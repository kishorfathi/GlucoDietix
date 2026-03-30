# GlucoDietix - AI-Powered Diabetic Portion Manager

A Flutter mobile application with Python backend for diabetic patients to manage their food portions using AI-powered food detection and WebAR portion guidance.

## Project Structure

```
GlucoDietix/
├── backend/                    # Python FastAPI Backend
│   ├── main.py                 # Main server file
│   ├── requirements.txt        # Python dependencies
│   └── models/
│       └── best.pt             # Trained YOLO model
│
├── lib/                        # Flutter App Code
│   ├── main.dart               # App entry point
│   ├── config/
│   │   └── supabase_config.dart  # Supabase credentials
│   ├── models/                 # Data models
│   ├── providers/              # State management
│   ├── screens/                # UI screens
│   ├── services/               # Business logic
│   └── widgets/                # Reusable widgets
│
├── web/                        # Web Assets
│   └── ar_portion.html         # WebAR portion guidance page
│
├── database/                   # Database Schema
│   └── supabase_schema.sql     # Supabase table definitions
│
├── android/                    # Android platform files
├── windows/                    # Windows platform files
└── pubspec.yaml                # Flutter dependencies
```

## How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│  Python Backend │────▶│    Supabase     │
│  (Mobile/Web)   │     │   (YOLO Model)  │     │  (Nutrition DB) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│   WebAR Page    │
│ (Portion Guide) │
└─────────────────┘
```

1. **User captures food image** in Flutter app
2. **Image sent to Python backend** running YOLO11 model
3. **Backend detects foods** and returns food names
4. **Flutter queries Supabase** for nutrition data
5. **User views AR portion guidance** through WebAR page

---

## Setup Instructions

### 1. Start the Backend Server

```bash
# Navigate to backend folder
cd backend

# Create virtual environment (first time only)
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies (first time only)
pip install -r requirements.txt

# Start the server
python main.py
```

Server runs at: `http://localhost:8000`
API Documentation: `http://localhost:8000/docs`

### 2. Run the Flutter App

```bash
# Navigate to project root
cd GlucoDietix

# Install Flutter dependencies
flutter pub get

# Run the app
flutter run

# Or run on specific device
flutter run -d chrome    # Web
flutter run -d windows   # Windows
flutter run -d android   # Android device/emulator
```

---

## Communication Flow

### Flutter → Backend (Food Detection)

```dart
// Flutter sends image to backend
final response = await http.post(
  Uri.parse('http://localhost:8000/detect'),
  body: {'file': imageFile},
);
// Response: {"foods": ["rice", "chicken curry", "dhal"]}
```

### Flutter → Supabase (Nutrition Data)

```dart
// Flutter queries Supabase for nutrition info
final response = await supabase
    .from('foods')
    .select()
    .ilike('name', foodName);
// Returns: calories, protein, carbs, glycemic_index, etc.
```

### WebAR Portion Guidance

```
URL: ar_portion.html?foods=rice,curry&portions=150,100&current=225,150
```

Opens in browser, shows 3D portion comparison using AR.js

---

## Key Files Reference

| File | Purpose |
|------|---------|
| `backend/main.py` | FastAPI server with YOLO detection |
| `lib/main.dart` | Flutter app entry point |
| `lib/services/food_detection_service.dart` | Handles ML detection |
| `lib/services/supabase_service.dart` | Database queries |
| `lib/config/supabase_config.dart` | Supabase credentials |
| `web/ar_portion.html` | WebAR page for portion visualization |

---

## Troubleshooting

### Backend not loading model
- Ensure `best.pt` is in `backend/models/` folder
- Check Python version (3.9+ required)

### Flutter can't connect to backend
- Verify backend is running at `http://localhost:8000`
- For Android emulator, use `http://10.0.2.2:8000`
- For iOS simulator, use `http://localhost:8000`
- For physical device, use your computer's IP address

### Supabase connection issues
- Verify credentials in `lib/config/supabase_config.dart`
- Check internet connection

---

## Technologies Used

- **Flutter** - Cross-platform mobile framework
- **FastAPI** - Python web framework
- **YOLO11** - AI object detection model (Ultralytics)
- **Supabase** - Backend-as-a-Service (PostgreSQL)
- **AR.js** - Web-based augmented reality

---

## Research Team

GlucoDietix - Student Research Project
