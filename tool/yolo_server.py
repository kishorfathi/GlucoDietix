import base64
import json
import os
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from io import BytesIO
from datetime import datetime, timezone
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from PIL import Image
from PIL import ImageEnhance
from ultralytics import YOLO

HOST = "0.0.0.0"
PORT = int(os.getenv("YOLO_PORT", "8000"))
MODEL_PATH = os.getenv("YOLO_MODEL_PATH", "yolo11n.pt")
CONFIDENCE = float(os.getenv("YOLO_CONFIDENCE", "0.2"))
AI_FALLBACK_ENABLED = os.getenv("AI_FALLBACK_ENABLED", "1").strip().lower() in {
    "1",
    "true",
    "yes",
    "on",
}
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "").strip()
OPENAI_BASE_URL = os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1").rstrip("/")
OPENAI_VISION_MODEL = os.getenv("OPENAI_VISION_MODEL", "gpt-4.1-mini")
AI_FALLBACK_TIMEOUT_SEC = float(os.getenv("AI_FALLBACK_TIMEOUT_SEC", "25"))
AI_FALLBACK_MIN_YOLO_COUNT = int(os.getenv("AI_FALLBACK_MIN_YOLO_COUNT", "2"))
AI_FALLBACK_MIN_CONF = float(os.getenv("AI_FALLBACK_MIN_CONF", "0.35"))
LOW_CONFIDENCE_FLOOR = float(os.getenv("YOLO_LOW_CONF_FLOOR", "0.01"))
ULTRA_LOW_CONFIDENCE_FLOOR = float(os.getenv("YOLO_ULTRA_LOW_CONF_FLOOR", "0.005"))


def _log(event: str, **fields):
    payload = {
        "time": datetime.now(timezone.utc).isoformat(timespec="seconds").replace("+00:00", "Z"),
        "event": event,
    }
    payload.update(fields)
    print(json.dumps(payload, ensure_ascii=False), flush=True)


def _resolve_label(names, cls_id: int) -> str:
    if isinstance(names, dict):
        return names.get(cls_id, "unknown")
    if isinstance(names, list) and 0 <= cls_id < len(names):
        return str(names[cls_id])
    return "unknown"


def _normalize_label(label: str) -> str:
    return re.sub(r"\s+", " ", (label or "").strip().lower())


def _extract_json_from_text(text: str):
    if not text:
        return None
    text = text.strip()
    try:
        return json.loads(text)
    except Exception:
        pass

    match = re.search(r"\{[\s\S]*\}", text)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except Exception:
        return None


def _to_ai_detections(parsed, top_k: int):
    foods = []
    if isinstance(parsed, dict):
        foods = parsed.get("foods") or parsed.get("detections") or []
    elif isinstance(parsed, list):
        foods = parsed

    detections = []
    seen = set()
    for item in foods:
        label = None
        confidence = AI_FALLBACK_MIN_CONF
        if isinstance(item, str):
            label = item
        elif isinstance(item, dict):
            label = item.get("name") or item.get("label") or item.get("food")
            if isinstance(item.get("confidence"), (int, float)):
                confidence = float(item.get("confidence"))
        if not label:
            continue

        normalized = _normalize_label(label)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        detections.append(
            {
                "label": label.strip(),
                "confidence": max(0.01, min(0.99, confidence)),
            }
        )
        if len(detections) >= top_k:
            break

    return detections


def _extract_message_content(data):
    choices = data.get("choices") if isinstance(data, dict) else None
    if not choices:
        return ""
    message = choices[0].get("message", {})
    content = message.get("content", "")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        text_parts = []
        for part in content:
            if isinstance(part, dict) and isinstance(part.get("text"), str):
                text_parts.append(part["text"])
        return "\n".join(text_parts)
    return ""


def _call_openai_food_fallback(image_bytes: bytes, top_k: int):
    if not AI_FALLBACK_ENABLED:
        return []
    if not OPENAI_API_KEY:
        _log("ai_fallback_skipped", reason="missing_openai_api_key")
        return []

    image_b64 = base64.b64encode(image_bytes).decode("utf-8")
    image_data_url = f"data:image/jpeg;base64,{image_b64}"
    prompt = (
        "Identify the visible edible foods in this meal photo for diabetes diet tracking. "
        f"Return up to {top_k} items. "
        "Respond with JSON only using this schema: "
        '{"foods":[{"name":"food name","confidence":0.0}]}. '
        "Use confidence between 0 and 1, and include only foods visible in the image."
    )

    payload = {
        "model": OPENAI_VISION_MODEL,
        "temperature": 0.1,
        "messages": [
            {
                "role": "system",
                "content": (
                    "You are an expert food recognition assistant for a diabetes meal app. "
                    "Return strict JSON only."
                ),
            },
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": image_data_url}},
                ],
            },
        ],
    }

    request = Request(
        url=f"{OPENAI_BASE_URL}/chat/completions",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {OPENAI_API_KEY}",
        },
        method="POST",
    )

    try:
        with urlopen(request, timeout=AI_FALLBACK_TIMEOUT_SEC) as response:
            raw = response.read().decode("utf-8")
        data = json.loads(raw)
        content = _extract_message_content(data)
        parsed = _extract_json_from_text(content)
        detections = _to_ai_detections(parsed, top_k)
        if detections:
            _log("ai_fallback_detected", detections=len(detections), model=OPENAI_VISION_MODEL)
        else:
            _log("ai_fallback_empty", model=OPENAI_VISION_MODEL, detail="no_parseable_foods")
        return detections
    except HTTPError as exc:
        try:
            detail = exc.read().decode("utf-8")
        except Exception:
            detail = str(exc)
        _log("ai_fallback_http_error", status=exc.code, detail=detail[:300])
        return []
    except URLError as exc:
        _log("ai_fallback_network_error", detail=str(exc))
        return []
    except Exception as exc:
        _log("ai_fallback_error", detail=str(exc))
        return []


def _merge_unique_detections(primary, secondary, top_k: int):
    merged = []
    seen = set()

    for source in (primary, secondary):
        for item in source:
            label = item.get("label", "")
            normalized = _normalize_label(label)
            if not normalized or normalized in seen:
                continue
            seen.add(normalized)
            merged.append(item)
            if len(merged) >= top_k:
                return merged
    return merged


def _extract_detections_from_results(results, top_k: int):
    if not results:
        return []
    result = results[0]
    names = result.names
    detections = []
    seen = set()
    for box in result.boxes:
        cls_id = int(box.cls[0])
        conf = float(box.conf[0])
        label = _resolve_label(names, cls_id)
        normalized = _normalize_label(label)
        if not normalized or normalized in seen:
            continue
        seen.add(normalized)
        detections.append(
            {
                "label": label,
                "confidence": conf,
            }
        )
        _log("detection", label=label, confidence=f"{conf:.3f}")

    detections = sorted(detections, key=lambda x: x["confidence"], reverse=True)
    return detections[:top_k]


def _detect_with_fallback_passes(image, top_k: int):
    adaptive_low_conf = max(LOW_CONFIDENCE_FLOOR, CONFIDENCE * 0.55)

    def _center_crop(src, crop_ratio: float = 0.82):
        width, height = src.size
        crop_width = max(1, int(width * crop_ratio))
        crop_height = max(1, int(height * crop_ratio))
        left = max(0, (width - crop_width) // 2)
        top = max(0, (height - crop_height) // 2)
        right = min(width, left + crop_width)
        bottom = min(height, top + crop_height)
        return src.crop((left, top, right, bottom))

    passes = [
        ("base", image, CONFIDENCE),
        ("adaptive_low_conf", image, adaptive_low_conf),
        ("enhanced_adaptive_low_conf", ImageEnhance.Contrast(image).enhance(1.25), adaptive_low_conf),
        ("center_crop_adaptive_low_conf", _center_crop(image), adaptive_low_conf),
        ("low_floor_conf", image, LOW_CONFIDENCE_FLOOR),
        ("enhanced_low_floor_conf", ImageEnhance.Contrast(image).enhance(1.35), LOW_CONFIDENCE_FLOOR),
        ("center_crop_low_floor_conf", _center_crop(image), LOW_CONFIDENCE_FLOOR),
        ("ultra_low_floor_conf", image, ULTRA_LOW_CONFIDENCE_FLOOR),
        ("enhanced_ultra_low_floor_conf", ImageEnhance.Contrast(image).enhance(1.5), ULTRA_LOW_CONFIDENCE_FLOOR),
    ]

    for pass_name, pass_image, pass_conf in passes:
        results = model.predict(pass_image, conf=pass_conf, verbose=False)
        detections = _extract_detections_from_results(results, top_k)
        _log("detect_pass", name=pass_name, conf=round(pass_conf, 4), detections=len(detections))
        if detections:
            return detections
    return []


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
            top_k = max(1, min(40, int(payload.get("topK", 25))))
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
            _log("image_received", width=image.width, height=image.height, mode=image.mode)
        except Exception:
            self._set_headers(400)
            self.wfile.write(json.dumps({"error": "Invalid image"}).encode("utf-8"))
            return

        try:
            detections = _detect_with_fallback_passes(image, top_k)
            _log("detect_result", detections=len(detections))

            if len(detections) < AI_FALLBACK_MIN_YOLO_COUNT:
                ai_detections = _call_openai_food_fallback(image_bytes, top_k)
                if ai_detections:
                    detections = _merge_unique_detections(detections, ai_detections, top_k)

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
                    "ai_fallback_enabled": AI_FALLBACK_ENABLED,
                    "ai_fallback_has_key": bool(OPENAI_API_KEY),
                    "ai_fallback_model": OPENAI_VISION_MODEL,
                    "ai_fallback_min_yolo_count": AI_FALLBACK_MIN_YOLO_COUNT,
                    "low_conf_floor": LOW_CONFIDENCE_FLOOR,
                    "ultra_low_conf_floor": ULTRA_LOW_CONFIDENCE_FLOOR,
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
