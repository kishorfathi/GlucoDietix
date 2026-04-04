import base64
import json
import requests
from PIL import Image, ImageDraw, ImageFont
import io

# Create a test image with text (simulating food)
img = Image.new('RGB', (640, 480), color='white')
draw = ImageDraw.Draw(img)

# Add some colored rectangles to simulate food items
draw.rectangle([50, 50, 200, 150], fill='brown', outline='black')  # Rice
draw.rectangle([220, 50, 370, 150], fill='red', outline='black')  # Curry
draw.rectangle([390, 50, 540, 150], fill='green', outline='black')  # Vegetable

# Convert to base64
buffer = io.BytesIO()
img.save(buffer, format='JPEG')
image_b64 = base64.b64encode(buffer.getvalue()).decode()

# Test YOLO server
url = 'http://127.0.0.1:8000/detect'
payload = {
    'image': image_b64,
    'topK': 10
}

print("Testing YOLO server...")
print(f"Sending request to {url}")
print(f"Image size: {len(image_b64)} bytes")

try:
    response = requests.post(url, json=payload, timeout=30)
    print(f"Status code: {response.status_code}")

    if response.status_code == 200:
        data = response.json()
        detections = data.get('detections', [])
        print(f"Detections: {len(detections)}")

        if detections:
            for i, det in enumerate(detections[:10], 1):
                print(f"  {i}. {det['label']} - {det['confidence']:.2%}")
        else:
            print("No objects detected in test image")
            print("This is expected for a blank test image")
            print("The model requires real food images to detect")
    else:
        print(f"Error: {response.text}")

except Exception as e:
    print(f"Request failed: {e}")

print("\n" + "="*50)
print("To properly test:")
print("   1. Upload a real food image in the app")
print("   2. Check browser console for network requests")
print("   3. Verify the request reaches http://127.0.0.1:8000/detect")
