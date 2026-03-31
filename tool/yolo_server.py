import base64
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from datetime import datetime, timezone

from PIL import Image
from ultralytics import YOLO

HOST = "0.0.0.0"
PORT = int(os.getenv("YOLO_PORT", "8008"))
MODEL_PATH = os.getenv("YOLO_MODEL_PATH", "yolo11n.pt")
CONFIDENCE = float(os.getenv("YOLO_CONFIDENCE", "0.2"))


def _log(event: str, **fields):
    payload = {
        "time": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "event": event,
    }
    payload.update(fields)
    print(json.dumps(payload, ensure_ascii=False))


def _resolve_label(names, cls_id: int) -> str:
    if isinstance(names, dict):
        return names.get(cls_id, "unknown")
    if isinstance(names, list) and 0 <= cls_id < len(names):
        return str(names[cls_id])
    return "unknown"


try:
    model = YOLO(MODEL_PATH)
    model.fuse()
except Exception as exc:
    _log("model_load_error", model=MODEL_PATH, detail=str(exc))
    raise SystemExit(1)


class YoloHandler(BaseHTTPRequestHandler):
    def _set_headers(self, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_OPTIONS(self):
        self._set_headers(200)

    def do_POST(self):
        if self.path != "/detect":
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Not found"}).encode("utf-8"))
            return

        length = int(self.headers.get("Content-Length", "0"))
        if length == 0:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Empty request"}).encode("utf-8"))
            return

        body = self.rfile.read(length)
        try:
            payload = json.loads(body.decode("utf-8"))
            image_b64 = payload.get("image")
            top_k = int(payload.get("topK", 10))
        except Exception:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Invalid JSON"}).encode("utf-8"))
            return

        if not image_b64:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Missing image"}).encode("utf-8"))
            return

        try:
            # Support raw base64 or data URLs (data:image/jpeg;base64,...)
            if isinstance(image_b64, str) and "," in image_b64 and image_b64.startswith("data:"):
                image_b64 = image_b64.split(",", 1)[1]
            image_bytes = base64.b64decode(image_b64)
            image = Image.open(BytesIO(image_bytes)).convert("RGB")
            _log("image_received", width=image.width, height=image.height, format=image.format)
        except Exception:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Invalid image"}).encode("utf-8"))
            return

        try:
            results = model.predict(image, conf=CONFIDENCE, verbose=True)
            if not results:
                detections = []
                _log("detect_result", detections=0, message="No results returned")
            else:
                result = results[0]
                names = result.names
                detections = []
                _log("detect_boxes_found", num_boxes=len(result.boxes) if result.boxes else 0)
                for box in result.boxes:
                    cls_id = int(box.cls[0])
                    conf = float(box.conf[0])
                    label = _resolve_label(names, cls_id)
                    detections.append(
                        {
                            "label": label,
                            "confidence": conf,
                        }
                    )
                    _log("detection", label=label, confidence=f"{conf:.3f}")

                detections = sorted(detections, key=lambda x: x["confidence"], reverse=True)
                detections = detections[:top_k]

            self._set_headers(200)
            _log("detect_ok", detections=len(detections), topK=top_k)
            self.wfile.write(json.dumps({"detections": detections}).encode("utf-8"))
        except Exception as exc:
            _log("detect_error", detail=str(exc))
            self._set_headers(500)
            self.wfile.write(
                json.dumps({"error": "Inference failed", "detail": str(exc)}).encode("utf-8")
            )

    def do_GET(self):
        if self.path != "/health":
            self._set_headers(404)
            self.wfile.write(json.dumps({"error": "Not found"}).encode("utf-8"))
            return

        self._set_headers(200)
        self.wfile.write(
            json.dumps(
                {
                    "status": "ok",
                    "model": MODEL_PATH,
                    "confidence": CONFIDENCE,
                    "endpoint": "/detect",
                }
            ).encode("utf-8")
        )


def run():
    try:
        server = ThreadingHTTPServer((HOST, PORT), YoloHandler)
    except OSError as exc:
        _log("server_bind_error", host=HOST, port=PORT, detail=str(exc))
        raise SystemExit(1)

    _log(
        "server_start",
        model=MODEL_PATH,
        confidence=CONFIDENCE,
        detect_url=f"http://{HOST}:{PORT}/detect",
        health_url=f"http://{HOST}:{PORT}/health",
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    run()
