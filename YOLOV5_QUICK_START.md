# 🚀 Quick Start: YOLOv5 Integration

This guide shows you how to quickly set up YOLOv5 food detection in GlucoDietix.

## Option 1: Using Pre-trained YOLOv5 Model (5 minutes)

### Step 1: Install Python Dependencies

```bash
pip install -r requirements.txt
```

### Step 2: Download and Convert YOLOv5

```bash
# Download pre-trained YOLOv5s model
pip install ultralytics
python -c "from ultralytics import YOLO; YOLO('yolov5s.pt')"

# Convert to TFLite
python convert_yolov5_to_tflite.py \
  --weights yolov5s.pt \
  --output assets/models \
  --int8

# Create labels file for COCO dataset (80 classes)
cat > assets/models/food_labels.txt << EOF
person
bicycle
car
food
apple
banana
sandwich
orange
broccoli
carrot
hot_dog
pizza
donut
cake
EOF
```

### Step 3: Update Flutter Assets

Ensure `pubspec.yaml` includes:

```yaml
flutter:
  assets:
    - assets/models/yolov5_food_detection.tflite
    - assets/models/food_labels.txt
```

### Step 4: Run the App

```bash
flutter pub get
flutter run
```

## Option 2: Custom Food Detection Model (Recommended)

For better accuracy with specific foods:

### Step 1: Prepare Your Dataset

1. **Collect Images**: 500-1000 images of target foods
2. **Annotate**: Use [Roboflow](https://roboflow.com/)
   - Create project
   - Upload images
   - Draw bounding boxes around foods
   - Label each food item
   - Export in YOLOv5 format

### Step 2: Train YOLOv5

```bash
# Clone YOLOv5
git clone https://github.com/ultralytics/yolov5
cd yolov5
pip install -r requirements.txt

# Train on your dataset
python train.py \
  --img 640 \
  --batch 16 \
  --epochs 100 \
  --data /path/to/your/data.yaml \
  --weights yolov5s.pt \
  --name food_detection

# Best model: runs/train/food_detection/weights/best.pt
```

### Step 3: Convert Custom Model

```bash
cd ../  # Back to GlucoDietix root

# Convert your trained model
python convert_yolov5_to_tflite.py \
  --weights yolov5/runs/train/food_detection/weights/best.pt \
  --output assets/models \
  --int8 \
  --labels rice curry fish chicken egg bread banana mango
```

### Step 4: Test

```bash
flutter pub get
flutter run
```

## Sri Lankan Food Detection Example

### Quick Dataset Setup

```bash
# Example labels for Sri Lankan foods
cat > assets/models/food_labels.txt << EOF
rice
chicken_curry
fish_curry
dhal_curry
potato_curry
beetroot_curry
green_beans
string_hoppers
hoppers
egg_hopper
roti
kottu
biriyani
fried_rice
noodles
bread
egg
banana
papaya
mango
watermelon
pineapple
coconut_sambol
seeni_sambol
pol_sambol
papadam
salad
soup
curd
wattalappan
kavum
kokis
EOF
```

## Troubleshooting

### Model Not Loading

```bash
# Check model exists
ls -lh assets/models/

# Should see:
# yolov5_food_detection.tflite
# food_labels.txt

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Poor Detection

1. **Lower confidence threshold** in `food_detection_service.dart`:
   ```dart
   static const double _confidenceThreshold = 0.25;
   ```

2. **Use larger model**:
   ```bash
   python convert_yolov5_to_tflite.py --weights yolov5m.pt ...
   ```

3. **Train custom model** with your specific foods

### Slow Performance

1. **Use smaller input size**:
   ```dart
   static const int _inputSize = 416;  // Faster than 640
   ```

2. **Use INT8 quantization**:
   ```bash
   python convert_yolov5_to_tflite.py --int8 ...
   ```

## Testing Checklist

- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Model converted to TFLite
- [ ] Labels file created
- [ ] Files in `assets/models/` directory
- [ ] `pubspec.yaml` updated
- [ ] `flutter pub get` run
- [ ] App runs without errors
- [ ] Food detection works (check console logs)
- [ ] Detections appear in UI

## Performance Targets

| Device Type    | Inference Time | Target      |
|----------------|----------------|-------------|
| High-end       | < 50ms         | ✅ Excellent |
| Mid-range      | 50-150ms       | ✅ Good      |
| Low-end        | 150-300ms      | ⚠️ Acceptable|

## Next Steps

1. ✅ **Basic Setup**: Get YOLOv5 working with pre-trained model
2. 🎯 **Custom Training**: Train on Sri Lankan foods
3. 📊 **Evaluate**: Test accuracy with real food images
4. 🔧 **Optimize**: Tune thresholds and model size
5. 🚀 **Deploy**: Release to users

---

For detailed information, see [YOLOV5_SETUP_GUIDE.md](YOLOV5_SETUP_GUIDE.md)
