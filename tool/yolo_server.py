import base64
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from io import BytesIO

from PIL import Image
from ultralytics import YOLO

HOST = "0.0.0.0"
PORT = 8008

model = YOLO("yolov8n.pt")
model.fuse()


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
            image_bytes = base64.b64decode(image_b64)
            image = Image.open(BytesIO(image_bytes)).convert("RGB")
        except Exception:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Invalid image"}).encode("utf-8"))
            return

        try:
            results = model.predict(image, conf=0.25, verbose=False)
            if not results:
                detections = []
            else:
                result = results[0]
                names = result.names
                detections = []
                for box in result.boxes:
                    cls_id = int(box.cls[0])
                    conf = float(box.conf[0])
                    detections.append(
                        {
                            "label": names.get(cls_id, "unknown"),
                            "confidence": conf,
                        }
                    )

                detections = sorted(detections, key=lambda x: x["confidence"], reverse=True)
                detections = detections[:top_k]

            self._set_headers(200)
            self.wfile.write(json.dumps({"detections": detections}).encode("utf-8"))
        except Exception as exc:
            self._set_headers(500)
            self.wfile.write(
                json.dumps({"error": "Inference failed", "detail": str(exc)}).encode("utf-8")
            )


def run():
    server = HTTPServer((HOST, PORT), YoloHandler)
    print(f"✅ YOLO server running on http://{HOST}:{PORT}/detect")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    run()
