param(
  [int]$WebPort = 53132,
  [switch]$SkipYolo
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path

Push-Location $projectRoot
try {
  if (-not (Test-Path ".dart_tool\package_config.json")) {
    Write-Host "Running flutter pub get (first-time setup)..." -ForegroundColor Cyan
    flutter pub get
  }

  if (-not $SkipYolo) {
    Write-Host "Starting YOLO backend..." -ForegroundColor Cyan
    Start-Process -FilePath powershell `
      -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", ".\tool\run_yolo_server.ps1",
        "-Port", "8000"
      ) `
      -WorkingDirectory $projectRoot | Out-Null
  }

  Write-Host "Starting Flutter (fast web mode)..." -ForegroundColor Green
  Write-Host "URL: http://127.0.0.1:$WebPort" -ForegroundColor Green

  flutter run `
    -d web-server `
    --web-hostname 0.0.0.0 `
    --web-port $WebPort `
    --no-track-widget-creation `
    --no-pub
}
finally {
  Pop-Location
}
