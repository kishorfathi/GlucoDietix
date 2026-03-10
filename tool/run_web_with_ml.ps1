param(
    [string]$Device = "chrome",
    [string]$ApiKey = ""
)

# Check if API key is provided as parameter
if ($ApiKey) {
    $env:GOOGLE_VISION_API_KEY = $ApiKey
}

if (-not $env:GOOGLE_VISION_API_KEY -or [string]::IsNullOrWhiteSpace($env:GOOGLE_VISION_API_KEY)) {
    Write-Host "=" * 70 -ForegroundColor Yellow
    Write-Host "ERROR: GOOGLE_VISION_API_KEY is not set!" -ForegroundColor Red
    Write-Host "=" * 70 -ForegroundColor Yellow
    Write-Host ""
    Write-Host "How to fix this:" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Option 1: Set environment variable first, then run this script:" -ForegroundColor Green
    Write-Host '  $env:GOOGLE_VISION_API_KEY="YOUR_ACTUAL_API_KEY"' -ForegroundColor White
    Write-Host '  .\tool\run_web_with_ml.ps1' -ForegroundColor White
    Write-Host ""
    Write-Host "Option 2: Pass API key directly to this script:" -ForegroundColor Green
    Write-Host '  .\tool\run_web_with_ml.ps1 -ApiKey "YOUR_ACTUAL_API_KEY"' -ForegroundColor White
    Write-Host ""
    Write-Host "How to get an API key:" -ForegroundColor Cyan
    Write-Host "  1. Go to https://console.cloud.google.com/" -ForegroundColor White
    Write-Host "  2. Create/select a project" -ForegroundColor White
    Write-Host "  3. Enable Cloud Vision API" -ForegroundColor White
    Write-Host "  4. Create API key in APIs & Services -> Credentials" -ForegroundColor White
    Write-Host ""
    Write-Host "=" * 70 -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting Flutter web with Google Vision API..." -ForegroundColor Green
Write-Host "Device: $Device" -ForegroundColor Cyan
Write-Host "API Key: ***" + $env:GOOGLE_VISION_API_KEY.Substring([Math]::Max(0, $env:GOOGLE_VISION_API_KEY.Length - 4)) -ForegroundColor Cyan
Write-Host ""

flutter run -d $Device --dart-define=GOOGLE_VISION_API_KEY=$env:GOOGLE_VISION_API_KEY
