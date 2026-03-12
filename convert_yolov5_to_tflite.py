#!/usr/bin/env python3
"""
YOLOv5 to TFLite Conversion Script
Converts PyTorch YOLOv5 model to TensorFlow Lite for mobile deployment
"""

import argparse
import os
import sys
from pathlib import Path

def check_requirements():
    """Check if required packages are installed"""
    required = ['torch', 'ultralytics']
    missing = []
    
    for package in required:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)
    
    if missing:
        print(f"❌ Missing required packages: {', '.join(missing)}")
        print("\nInstall them with:")
        print(f"pip install {' '.join(missing)}")
        return False
    
    return True

def convert_to_tflite(weights_path, output_dir, img_size=640, int8=False):
    """
    Convert YOLOv5 model to TFLite format
    
    Args:
        weights_path: Path to YOLOv5 .pt weights file
        output_dir: Directory to save TFLite model
        img_size: Input image size (default: 640)
        int8: Use INT8 quantization for smaller model (default: False)
    """
    if not os.path.exists(weights_path):
        print(f"❌ Weights file not found: {weights_path}")
        return False
    
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Import YOLOv5 export (requires ultralytics)
    try:
        from ultralytics import YOLO
    except ImportError:
        print("❌ ultralytics package not found")
        print("Install with: pip install ultralytics")
        return False
    
    try:
        print(f"📦 Loading model from {weights_path}...")
        model = YOLO(weights_path)
        
        # Export to TFLite
        print(f"🔄 Converting to TFLite (img_size={img_size}, int8={int8})...")
        
        export_args = {
            'format': 'tflite',
            'imgsz': img_size,
            'int8': int8,
        }
        
        export_path = model.export(**export_args)
        
        # Move to output directory
        output_path = os.path.join(output_dir, 'yolov5_food_detection.tflite')
        if os.path.exists(export_path):
            import shutil
            shutil.move(export_path, output_path)
            print(f"✅ Model saved to: {output_path}")
            
            # Print file size
            size_mb = os.path.getsize(output_path) / (1024 * 1024)
            print(f"📊 Model size: {size_mb:.2f} MB")
            
            return True
        else:
            print("❌ Export failed - output file not found")
            return False
            
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        return False

def create_labels_file(class_names, output_dir):
    """Create labels.txt file from class names"""
    labels_path = os.path.join(output_dir, 'food_labels.txt')
    
    try:
        with open(labels_path, 'w') as f:
            for name in class_names:
                f.write(f"{name}\n")
        
        print(f"✅ Labels saved to: {labels_path}")
        print(f"📋 Total classes: {len(class_names)}")
        return True
    except Exception as e:
        print(f"❌ Failed to create labels file: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(
        description='Convert YOLOv5 PyTorch model to TFLite for Flutter'
    )
    parser.add_argument(
        '--weights',
        type=str,
        required=True,
        help='Path to YOLOv5 .pt weights file'
    )
    parser.add_argument(
        '--output',
        type=str,
        default='assets/models',
        help='Output directory for TFLite model (default: assets/models)'
    )
    parser.add_argument(
        '--img-size',
        type=int,
        default=640,
        help='Model input size (default: 640)'
    )
    parser.add_argument(
        '--int8',
        action='store_true',
        help='Use INT8 quantization for smaller model'
    )
    parser.add_argument(
        '--labels',
        type=str,
        nargs='+',
        help='Class names for labels.txt file'
    )
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("YOLOv5 to TFLite Converter")
    print("=" * 60)
    
    # Check requirements
    if not check_requirements():
        sys.exit(1)
    
    # Convert model
    success = convert_to_tflite(
        args.weights,
        args.output,
        args.img_size,
        args.int8
    )
    
    if not success:
        sys.exit(1)
    
    # Create labels file if provided
    if args.labels:
        create_labels_file(args.labels, args.output)
    else:
        print("\n⚠️  No labels provided. Create food_labels.txt manually.")
        print("Example labels for Sri Lankan foods:")
        print("  rice, chicken_curry, fish_curry, dhal_curry, roti, ...")
    
    print("\n" + "=" * 60)
    print("✅ Conversion complete!")
    print("=" * 60)
    print("\nNext steps:")
    print("1. Copy the TFLite model to your Flutter app:")
    print(f"   {args.output}/yolov5_food_detection.tflite")
    print("2. Update pubspec.yaml to include the model in assets")
    print("3. Run: flutter pub get")
    print("4. Test the app with food detection!")

if __name__ == '__main__':
    main()
