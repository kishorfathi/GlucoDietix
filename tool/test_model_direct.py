import sys
from ultralytics import YOLO
from PIL import Image
import numpy as np

# Load model
print("Loading model...")
model = YOLO("../backend/models/best.pt")

# Create a test image
print("Creating test image...")
img = Image.new('RGB', (640, 640), color='brown')

# Try detection with very low confidence
print("Running inference with conf=0.001...")
results = model.predict(img, conf=0.001, verbose=True)

print(f"\nResults: {len(results)}")
if results:
    result = results[0]
    print(f"Boxes: {len(result.boxes) if result.boxes else 0}")
    print(f"Names: {result.names}")

    if result.boxes and len(result.boxes) > 0:
        print("\nDetections found:")
        for i, box in enumerate(result.boxes[:10]):
            cls_id = int(box.cls[0])
            conf = float(box.conf[0])
            label = result.names.get(cls_id, 'unknown')
            print(f"  {i+1}. {label} - {conf:.3f}")
    else:
        print("\nNo detections found even at conf=0.001")
        print("This suggests the model might be expecting specific image preprocessing")

print("\n" + "="*60)
print("Model info:")
print(f"  Path: ../backend/models/best.pt")
print(f"  Classes: {len(model.names)}")
print(f"  Input size: {model.model.args.get('imgsz', 'unknown')}")
