"""
================================================================================
GlucoDietix Backend - FastAPI + YOLO11 Food Detection API
================================================================================

This backend server provides food detection capabilities using YOLO11 AI model.
It receives images from the Flutter mobile app, runs object detection,
and returns the names of detected food items for diabetic portion management.

HOW IT WORKS:
1. Flutter app captures/selects an image of a food plate
2. Image is sent to this backend via POST /detect endpoint
3. YOLO11 model detects food items in the image
4. Backend returns list of detected food names
5. Flutter app queries Supabase for nutrition data

REQUIREMENTS:
- Python 3.9+
- YOLO model file: models/best.pt

USAGE:
    python main.py

Server runs at: http://localhost:8000

Author: GlucoDietix Research Team
Version: 1.0.0
================================================================================
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
from ultralytics import YOLO
from pathlib import Path
import io
import base64
from PIL import Image, ImageEnhance
import uvicorn


# ==============================================================================
# CONFIGURATION - Adjust these values as needed
# ==============================================================================

PORT = 8000                    # Server port number
CONFIDENCE_THRESHOLD = 0.15    # Minimum detection confidence (lowered for better detection)
LOW_CONFIDENCE_FLOOR = 0.03    # Fallback confidence floor for hard images
MODEL_PATH = Path(__file__).parent / "models" / "best.pt"  # Path to YOLO model


# ==============================================================================
# APPLICATION SETUP
# ==============================================================================

# Create FastAPI application instance
app = FastAPI(
    title="GlucoDietix Food Detection API",
    description="AI-powered food detection for diabetic portion management",
    version="1.0.0"
)

# Enable CORS (Cross-Origin Resource Sharing)
# This allows the Flutter app to communicate with the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],       # Allow all origins (restrict in production)
    allow_credentials=True,
    allow_methods=["*"],       # Allow all HTTP methods
    allow_headers=["*"],       # Allow all headers
)

# Global variable to store the loaded YOLO model
model = None


def _extract_unique_detections(results, top_k: int):
    detections = []
    seen_labels = set()

    for result in results:
        boxes = result.boxes
        if boxes is None or len(boxes) == 0:
            continue
        for box in boxes:
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            class_name = model.names[class_id]
            if class_name in seen_labels:
                continue
            seen_labels.add(class_name)
            detections.append({
                "label": class_name,
                "confidence": round(confidence, 3)
            })

    detections.sort(key=lambda x: x["confidence"], reverse=True)
    return detections[:top_k]


def _run_detection_with_fallback_passes(image: Image.Image, top_k: int):
    passes = [
        ("base", image, CONFIDENCE_THRESHOLD),
        ("low_conf", image, max(LOW_CONFIDENCE_FLOOR, CONFIDENCE_THRESHOLD * 0.55)),
        ("enhanced_low_conf",
         ImageEnhance.Contrast(image).enhance(1.25),
         max(LOW_CONFIDENCE_FLOOR, CONFIDENCE_THRESHOLD * 0.55)),
    ]

    for pass_name, pass_image, pass_conf in passes:
        print(f"Running detect pass '{pass_name}' with conf={pass_conf:.3f}")
        results = model(pass_image, conf=pass_conf)
        detections = _extract_unique_detections(results, top_k)
        print(f"Pass '{pass_name}' detections: {len(detections)}")
        if detections:
            return detections
    return []


# ==============================================================================
# REQUEST MODELS
# ==============================================================================

class DetectRequest(BaseModel):
    """Request model for JSON-based detection (used by Flutter app)"""
    image: str  # Base64 encoded image
    topK: Optional[int] = 25  # Maximum number of detections to return


# ==============================================================================
# MODEL LOADING
# ==============================================================================

def load_model():
    """
    Load the YOLO11 model from the models directory.
    Called automatically when the server starts.
    """
    global model

    print("=" * 60)
    print("Loading YOLO11 Food Detection Model...")
    print("=" * 60)

    try:
        # Check if model file exists
        if not MODEL_PATH.exists():
            print(f"ERROR: Model not found at {MODEL_PATH}")
            print("Please place your trained model (best.pt) in the models/ folder")
            print("Using default YOLOv8n as fallback...")
            model = YOLO('yolov8n.pt')
            return

        # Load the trained model
        print(f"Loading model from: {MODEL_PATH}")
        model = YOLO(str(MODEL_PATH))
        print("Model loaded successfully!")

        # Display model information
        if hasattr(model, 'names'):
            class_names = list(model.names.values())
            print(f"Number of classes: {len(class_names)}")
            print(f"Food classes: {class_names[:10]}...")  # Show first 10

    except Exception as e:
        print(f"ERROR loading model: {str(e)}")
        print("Using default YOLOv8n as fallback...")
        model = YOLO('yolov8n.pt')


# ==============================================================================
# API ENDPOINTS
# ==============================================================================

@app.on_event("startup")
async def startup_event():
    """Initialize the model when server starts."""
    load_model()
    print("=" * 60)
    print("GlucoDietix Backend Server Ready!")
    print(f"API Documentation: http://localhost:{PORT}/docs")
    print("=" * 60)


@app.get("/")
async def root():
    """
    Root endpoint - Returns server status.
    Use this to check if the server is running.
    """
    return {
        "status": "running",
        "message": "GlucoDietix Food Detection API",
        "version": "1.0.0",
        "model_loaded": model is not None
    }


@app.get("/health")
async def health_check():
    """
    Health check endpoint - Returns detailed server status.
    Used by Flutter app to verify backend connectivity.
    """
    return {
        "status": "healthy",
        "model_status": "loaded" if model else "not loaded",
        "model_classes": list(model.names.values()) if model and hasattr(model, 'names') else []
    }


@app.post("/detect")
async def detect_food(request: DetectRequest):
    """
    Main food detection endpoint (JSON with base64 image).

    Used by Flutter app. Accepts JSON body with base64-encoded image.

    Args:
        request: JSON with 'image' (base64 string) and optional 'topK' (int)

    Returns:
        JSON: {"detections": [{"label": "rice", "confidence": 0.95}, ...]}
    """
    # Check if model is loaded
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please restart the server."
        )

    try:
        # Decode base64 image
        try:
            image_data = base64.b64decode(request.image)
            image = Image.open(io.BytesIO(image_data))
            print(f"Processing base64 image ({len(request.image)} chars)")
        except Exception as decode_error:
            print(f"Base64 decode error: {decode_error}")
            raise HTTPException(status_code=400, detail="Invalid base64 image")

        detections = _run_detection_with_fallback_passes(image, request.topK)

        print(f"Total detected: {len(detections)} food items")

        # Return format expected by Flutter app
        return {"detections": detections}

    except HTTPException:
        raise
    except Exception as e:
        print(f"Detection error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@app.post("/detect-file")
async def detect_food_file(file: UploadFile = File(...)):
    """
    File-based food detection endpoint.

    Receives an image file and returns detected food items.

    Args:
        file: Image file (JPEG, PNG, etc.)

    Returns:
        JSON: {"detections": [{"label": "rice", "confidence": 0.95}, ...]}

    Example:
        curl -X POST -F "file=@plate.jpg" http://localhost:8000/detect-file
    """
    # Check if model is loaded
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please restart the server."
        )

    try:
        # Read and open the uploaded image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        print(f"Processing uploaded file: {file.filename}")

        detections = _run_detection_with_fallback_passes(image, 25)

        print(f"Total detected: {len(detections)} food items")

        return {"detections": detections}

    except Exception as e:
        print(f"Detection error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


@app.post("/detect-detailed")
async def detect_food_detailed(file: UploadFile = File(...)):
    """
    Detailed food detection endpoint.

    Returns food items with confidence scores and bounding boxes.

    Args:
        file: Image file (JPEG, PNG, etc.)

    Returns:
        JSON: {
            "count": 3,
            "detections": [
                {"food": "rice", "confidence": 0.95, "bbox": [x1, y1, x2, y2]},
                ...
            ]
        }
    """
    if model is None:
        raise HTTPException(
            status_code=503,
            detail="Model not loaded. Please restart the server."
        )

    try:
        # Read and process image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        # Run detection with confidence fallback
        raw = _run_detection_with_fallback_passes(image, 50)
        detections = [
            {
                "food": d["label"],
                "confidence": d["confidence"],
                "bbox": [],
            }
            for d in raw
        ]

        return {
            "count": len(detections),
            "detections": detections
        }

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Detection failed: {str(e)}")


# ==============================================================================
# MAIN ENTRY POINT
# ==============================================================================

if __name__ == "__main__":
    print()
    print("=" * 60)
    print("     GlucoDietix Food Detection Backend")
    print("=" * 60)
    print()
    print("Starting server...")
    print(f"URL: http://localhost:{PORT}")
    print(f"API Docs: http://localhost:{PORT}/docs")
    print()

    # Start the server
    uvicorn.run(app, host="0.0.0.0", port=PORT)
