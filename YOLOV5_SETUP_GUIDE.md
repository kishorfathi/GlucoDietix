# 🎯 YOLOv5 Food Detection Setup Guide

## Overview

This guide explains how to set up and use **YOLOv5** for on-device food detection in the GlucoDietix app. YOLOv5 provides fast, accurate object detection without requiring cloud APIs or internet connectivity.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│          Camera / Image Input                           │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│      Image Preprocessing (640x640, normalized)          │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│      YOLOv5 TFLite Model (On-Device Inference)         │
│  Input: [1, 640, 640, 3]                                │
│  Output: [1, 25200, 85] (detections)                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│      Post-Processing (NMS, Filtering)                   │
│  - Apply confidence threshold (0.35)                    │
│  - Non-Maximum Suppression (IoU 0.5)                    │
│  - Match to food database                               │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
        Detected Foods with Portions
```

## Why YOLOv5?

✅ **On-Device Processing**: No internet required, works offline  
✅ **Fast**: Real-time detection on mobile devices  
✅ **Accurate**: State-of-the-art object detection  
✅ **Privacy**: Images never leave the device  
✅ **Cost**: No API fees or usage limits  
✅ **Customizable**: Can be trained on custom food datasets

## Prerequisites

- Python 3.8+ (for model conversion)
- PyTorch
- YOLOv5 repository
- TensorFlow Lite converter

## Step 1: Prepare YOLOv5 Model

### Option A: Use Pre-trained Model

Download a pre-trained YOLOv5 model:

```bash
# Clone YOLOv5 repository
git clone https://github.com/ultralytics/yolov5
cd yolov5

# Install requirements
pip install -r requirements.txt

# Download pre-trained weights
wget https://github.com/ultralytics/yolov5/releases/download/v7.0/yolov5s.pt
```

### Option B: Train Custom Food Detection Model

If you want better accuracy for specific foods, train a custom model:

```bash
# Prepare your dataset in YOLO format
# Structure:
# dataset/
#   images/
#     train/
#     val/
#   labels/
#     train/
#     val/
#   data.yaml

# Train model
python train.py --img 640 --batch 16 --epochs 100 \
  --data dataset/data.yaml --weights yolov5s.pt \
  --name food_detection --cache

# Best model will be at runs/train/food_detection/weights/best.pt
```

### Creating Food Dataset

For custom food detection, you'll need annotated images:

1. **Collect Images**: Gather images of foods you want to detect
2. **Annotate**: Use [Roboflow](https://roboflow.com/) or [CVAT](https://www.cvat.ai/) to label foods
3. **Export**: Export in YOLO format
4. **Create data.yaml**:

```yaml
# dataset/data.yaml
path: ./dataset  # dataset root dir
train: images/train  # train images
val: images/val  # val images

# Classes (example for Sri Lankan foods)
names:
  0: rice
  1: chicken_curry
  2: fish_curry
  3: dhal_curry
  4: potato_curry
  5: string_hoppers
  6: hoppers
  7: roti
  8: kottu
  9: biriyani
  10: fried_rice
  11: noodles
  12: bread
  13: egg
  14: banana
  15: papaya
  16: mango
  17: coconut_sambol
  18: salad
  19: soup
```

## Step 2: Convert to TFLite

Convert the PyTorch model to TensorFlow Lite format:

```bash
# Export to TFLite
python export.py --weights runs/train/food_detection/weights/best.pt \
  --include tflite --img 640

# For pre-trained model:
python export.py --weights yolov5s.pt --include tflite --img 640

# Output: best-fp16.tflite or yolov5s-fp16.tflite
```

### Optimize for Mobile

```bash
# Create optimized INT8 model (smaller, faster)
python export.py --weights runs/train/food_detection/weights/best.pt \
  --include tflite --img 640 --int8

# This creates: best-int8.tflite (better for mobile)
```

## Step 3: Prepare Labels File

Create a labels file with your food classes:

```bash
# Extract class names from data.yaml to labels.txt
python -c "
import yaml
with open('dataset/data.yaml', 'r') as f:
    data = yaml.safe_load(f)
    with open('food_labels.txt', 'w') as out:
        for name in data['names'].values():
            out.write(name + '\n')
"
```

Or manually create `food_labels.txt`:

```text
rice
chicken_curry
fish_curry
dhal_curry
potato_curry
string_hoppers
hoppers
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
coconut_sambol
salad
soup
```

## Step 4: Add Model to Flutter App

1. **Create models directory** (if not exists):

```bash
mkdir -p assets/models
```

2. **Copy model and labels**:

```bash
# Copy TFLite model
cp best-fp16.tflite assets/models/yolov5_food_detection.tflite

# Or for INT8:
cp best-int8.tflite assets/models/yolov5_food_detection.tflite

# Copy labels
cp food_labels.txt assets/models/food_labels.txt
```

3. **Update pubspec.yaml** (already done):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/models/yolov5_food_detection.tflite
    - assets/models/food_labels.txt
```

## Step 5: Test the Implementation

Run the app and test food detection:

```bash
# Get dependencies
flutter pub get

# Run on device (Android/iOS)
flutter run

# For testing:
# 1. Open the food scanning screen
# 2. Take a photo of food
# 3. Model will detect and identify foods
# 4. Check console for detection logs
```

## Model Performance Tuning

### Adjust Confidence Threshold

Edit `lib/services/food_detection_service.dart`:

```dart
// Lower threshold = more detections (may have false positives)
static const double _confidenceThreshold = 0.25;

// Higher threshold = fewer, more confident detections
static const double _confidenceThreshold = 0.50;
```

### Adjust IoU Threshold (NMS)

```dart
// Lower IoU = keep more overlapping boxes
static const double _iouThreshold = 0.3;

// Higher IoU = remove more overlapping boxes
static const double _iouThreshold = 0.7;
```

### Change Input Size

```dart
// Larger size = better accuracy, slower inference
static const int _inputSize = 640;  // YOLOv5 default

// Smaller size = faster inference, lower accuracy
static const int _inputSize = 416;  // Faster option
```

## Debugging

### Enable Verbose Logging

The service already includes detailed logging:

```dart
print('✅ YOLOv5 model initialized with ${_labels?.length ?? 0} classes');
print('📸 Processing image with YOLOv5...');
print('✅ Detected ${labels.length} objects with YOLOv5');
```

Check Flutter console output for detection results.

### Common Issues

#### 1. Model Not Loading

```
❌ Failed to initialize YOLOv5 model: ...
```

**Solutions:**
- Verify model path in assets
- Check pubspec.yaml includes model in assets
- Run `flutter clean && flutter pub get`
- Ensure model is valid TFLite format

#### 2. No Detections

```
⚠️ No detections from YOLOv5
```

**Solutions:**
- Lower confidence threshold
- Check if objects are in training dataset
- Verify image preprocessing is correct
- Test with known objects from training data

#### 3. Slow Performance

**Solutions:**
- Reduce input size (640 → 416)
- Use INT8 quantized model
- Enable GPU delegate (Android)
- Enable NNAPI delegate (Android)

#### 4. Wrong Detections

**Solutions:**
- Increase confidence threshold
- Train custom model with more data
- Add more training examples of problematic foods
- Fine-tune NMS IoU threshold

## Advanced: GPU Acceleration

### Android

Already enabled in code:

```dart
_interpreter = await Interpreter.fromAsset(
  'assets/models/yolov5_food_detection.tflite',
  options: InterpreterOptions()
    ..threads = 4
    ..useNnApiForAndroid = true  // Use Android Neural Networks API
    ..useGpuDelegateV2 = true,   // Use GPU if available
);
```

### iOS

For iOS GPU acceleration, add Metal delegate:

```dart
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

// iOS Metal delegate
_interpreter = await Interpreter.fromAsset(
  'assets/models/yolov5_food_detection.tflite',
  options: InterpreterOptions()
    ..threads = 4
    ..addDelegate(GpuDelegateV2()),  // iOS GPU
);
```

## Model Metrics

### Expected Performance

| Model     | Size   | Inference Time* | mAP@0.5 |
|-----------|--------|-----------------|---------|
| YOLOv5s   | 14 MB  | ~50-100ms       | ~37%    |
| YOLOv5m   | 42 MB  | ~100-200ms      | ~45%    |
| YOLOv5l   | 92 MB  | ~150-300ms      | ~49%    |
| YOLOv5x   | 166 MB | ~200-400ms      | ~51%    |
| Custom    | Varies | Varies          | Varies  |

*Approximate on mid-range Android device

### Recommendations

- **Best for mobile**: YOLOv5s (small, fast)
- **Best accuracy**: YOLOv5l or custom trained model
- **Best balance**: YOLOv5m or custom YOLOv5s

## Food Detection Tips

### For Best Results

1. **Good Lighting**: Take photos in well-lit environments
2. **Clear View**: Ensure foods are clearly visible
3. **Single Items**: Works best with individual food items
4. **Standard Presentations**: Photos similar to training data
5. **Appropriate Distance**: Not too close or too far

### Limitations

- May not detect heavily mixed/blended foods
- Performance depends on training data quality
- Novel foods not in dataset won't be detected
- Overlapping foods may be challenging

## Next Steps

1. ✅ **Test Basic Detection**: Verify model works with sample images
2. 🎯 **Collect Sri Lankan Food Dataset**: Gather local food images
3. 🔄 **Train Custom Model**: Improve accuracy for target foods
4. 📊 **Evaluate Performance**: Measure accuracy and speed
5. 🚀 **Deploy**: Release to production

## Resources

- [YOLOv5 Documentation](https://docs.ultralytics.com/)
- [TFLite Flutter Plugin](https://pub.dev/packages/tflite_flutter)
- [Roboflow (Dataset Creation)](https://roboflow.com/)
- [Image Annotation Tools](https://www.cvat.ai/)
- [Food-101 Dataset](https://www.kaggle.com/datasets/dansbecker/food-101)

## Support

For issues or questions:
1. Check console logs for error messages
2. Verify model and labels are in assets
3. Ensure dependencies are installed
4. Test with different confidence thresholds

---

**Status**: ✅ YOLOv5 integration complete and ready for testing!
