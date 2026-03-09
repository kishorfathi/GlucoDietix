param(
    [string]$Device = "chrome"
)

if (-not $env:GOOGLE_VISION_API_KEY -or [string]::IsNullOrWhiteSpace($env:GOOGLE_VISION_API_KEY)) {
    Write-Error "GOOGLE_VISION_API_KEY environment variable is not set."
    Write-Host "Example:"
    Write-Host '$env:GOOGLE_VISION_API_KEY="YOUR_KEY"'
    Write-Host "powershell -ExecutionPolicy Bypass -File .\tool\run_web_with_ml.ps1"
    exit 1
}

flutter run -d $Device --dart-define=GOOGLE_VISION_API_KEY=$env:GOOGLE_VISION_API_KEY
