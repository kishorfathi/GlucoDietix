# Google Vision Setup (Web Real ML)

This app supports real food-label detection on web using Google Cloud Vision.

## 1. Create a Google Cloud API key

1. Open Google Cloud Console.
2. Create or select a project.
3. Enable `Cloud Vision API`.
4. Create an API key in `APIs & Services -> Credentials`.
5. Restrict the key:
   - API restriction: `Cloud Vision API` only.
   - Application restriction:
     - For local dev: allow localhost referrers.
     - For production: allow only your domain.

## 2. Run Flutter web with secure dart-define

Do not hardcode the key in source files.

PowerShell (Windows):

```powershell
$env:GOOGLE_VISION_API_KEY="YOUR_REAL_KEY"
flutter run -d chrome --dart-define=GOOGLE_VISION_API_KEY=$env:GOOGLE_VISION_API_KEY
```

CMD (Windows):

```cmd
set GOOGLE_VISION_API_KEY=YOUR_REAL_KEY
flutter run -d chrome --dart-define=GOOGLE_VISION_API_KEY=%GOOGLE_VISION_API_KEY%
```

Bash (macOS/Linux):

```bash
export GOOGLE_VISION_API_KEY="YOUR_REAL_KEY"
flutter run -d chrome --dart-define=GOOGLE_VISION_API_KEY=$GOOGLE_VISION_API_KEY
```

## 3. Optional helper script

Use:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\run_web_with_ml.ps1
```

This script reads the key from `GOOGLE_VISION_API_KEY` environment variable and launches Flutter with `--dart-define`.

## 4. Verify it is working

1. Open `Scan Plate`.
2. Capture a meal photo.
3. Confirm detected food cards show labels and confidence.
4. If no labels appear:
   - Check API key is valid.
   - Check Vision API is enabled.
   - Check key restrictions allow localhost/domain.

## 5. Security notes

- Never commit API keys into Dart files, `.env` files in repo, or screenshots.
- Prefer environment variables and CI/CD secrets.
- Rotate the key immediately if it was exposed.
