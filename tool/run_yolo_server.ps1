param(
	[string]$ModelPath = "",
	[double]$Confidence = 0.2,
	[int]$Port = 8008
)

if ($ModelPath -and -not (Test-Path $ModelPath)) {
	Write-Host "Model not found: $ModelPath" -ForegroundColor Red
	exit 1
}

if ($ModelPath) {
	$env:YOLO_MODEL_PATH = $ModelPath
}

$env:YOLO_CONFIDENCE = "$Confidence"
$env:YOLO_PORT = "$Port"

Write-Host "Starting YOLO server..." -ForegroundColor Green
Write-Host "Model: " + ($(if ($env:YOLO_MODEL_PATH) { $env:YOLO_MODEL_PATH } else { "yolov8n.pt (default)" })) -ForegroundColor Cyan
Write-Host "Confidence: $env:YOLO_CONFIDENCE" -ForegroundColor Cyan
Write-Host "Port: $env:YOLO_PORT" -ForegroundColor Cyan

python .\tool\yolo_server.py
