param(
	[string]$ModelPath = "",
	[double]$Confidence = 0.10,
	[int]$Port = 8000,
	[switch]$AutoRestart,
	[int]$RestartDelaySec = 2,
	[int]$MaxRestarts = 20
)

function Test-YoloHealth {
	param(
		[int]$Port
	)

	$healthUrl = "http://127.0.0.1:$Port/health"
	try {
		$response = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2
		return [bool]($response.status -eq "ok")
	} catch {
		return $false
	}
}

function Get-PortProcessId {
	param(
		[int]$Port
	)

	try {
		$conn = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
			Select-Object -First 1 -ExpandProperty OwningProcess
		if ($conn) {
			return [int]$conn
		}
	} catch {
		# Ignore and fall back to netstat parsing for compatibility.
	}

	try {
		$netstat = netstat -ano | Select-String -Pattern ":$Port\s+.*LISTENING\s+(\d+)"
		if ($netstat -and $netstat.Matches.Count -gt 0) {
			return [int]$netstat.Matches[0].Groups[1].Value
		}
	} catch {
		return $null
	}

	return $null
}

function Get-PythonInvocation {
	param(
		[string]$ProjectRoot
	)

	$venvPython = Join-Path $ProjectRoot ".venv\Scripts\python.exe"
	if (Test-Path $venvPython) {
		return @{
			Exe = $venvPython
			Args = @()
		}
	}

	$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
	if ($pythonCmd) {
		return @{
			Exe = $pythonCmd.Source
			Args = @()
		}
	}

	$pyCmd = Get-Command py -ErrorAction SilentlyContinue
	if ($pyCmd) {
		return @{
			Exe = $pyCmd.Source
			Args = @("-3")
		}
	}

	return $null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Resolve-Path (Join-Path $scriptDir "..")).Path
$serverScript = Join-Path $projectRoot "tool\yolo_server.py"
$defaultModelPath = Join-Path $projectRoot "backend\models\best.pt"

if (-not (Test-Path $serverScript)) {
	Write-Host "YOLO server script not found: $serverScript" -ForegroundColor Red
	exit 1
}

if (-not $ModelPath -and (Test-Path $defaultModelPath)) {
	$env:YOLO_MODEL_PATH = (Resolve-Path $defaultModelPath).Path
} elseif ($ModelPath) {
	$resolvedModelPath = $null
	if (Test-Path $ModelPath) {
		$resolvedModelPath = (Resolve-Path $ModelPath).Path
	} else {
		$candidateModelPath = Join-Path $projectRoot $ModelPath
		if (Test-Path $candidateModelPath) {
			$resolvedModelPath = (Resolve-Path $candidateModelPath).Path
		}
	}

	if (-not $resolvedModelPath) {
		Write-Host "Model not found: $ModelPath" -ForegroundColor Red
		exit 1
	}

	$env:YOLO_MODEL_PATH = $resolvedModelPath
}

$env:YOLO_CONFIDENCE = "$Confidence"
$env:YOLO_PORT = "$Port"
if (-not $env:YOLO_LOW_CONF_FLOOR) {
	$env:YOLO_LOW_CONF_FLOOR = "0.01"
}
if (-not $env:YOLO_ULTRA_LOW_CONF_FLOOR) {
	$env:YOLO_ULTRA_LOW_CONF_FLOOR = "0.005"
}


$python = Get-PythonInvocation -ProjectRoot $projectRoot
if (-not $python) {
	Write-Host "Python not found. Install Python 3.10+ and ensure python or py is in PATH." -ForegroundColor Red
	exit 1
}

if (Test-YoloHealth -Port $Port) {
	Write-Host "YOLO server is already running on port $Port." -ForegroundColor Yellow
	Write-Host "Health: http://127.0.0.1:$Port/health" -ForegroundColor Cyan
	exit 0
}

$stalePid = Get-PortProcessId -Port $Port
if ($stalePid) {
	if ($stalePid -eq $PID) {
		Write-Host "Port $Port is occupied by current shell process. Please close conflicting listeners and retry." -ForegroundColor Red
		exit 1
	}

	Write-Host "Port $Port is occupied by process $stalePid but health check failed. Restarting listener..." -ForegroundColor Yellow
	try {
		Stop-Process -Id $stalePid -Force -ErrorAction Stop
		Start-Sleep -Milliseconds 700
	} catch {
		Write-Host "Failed to stop process $stalePid on port ${Port}: $($_.Exception.Message)" -ForegroundColor Red
		exit 1
	}
}

Write-Host "Starting YOLO server..." -ForegroundColor Green
Write-Host ("Model: " + ($(if ($env:YOLO_MODEL_PATH) { $env:YOLO_MODEL_PATH } else { "yolo11n.pt (default)" }))) -ForegroundColor Cyan
Write-Host "Confidence: $env:YOLO_CONFIDENCE" -ForegroundColor Cyan
Write-Host "Low confidence floor: $env:YOLO_LOW_CONF_FLOOR" -ForegroundColor Cyan
Write-Host "Ultra-low confidence floor: $env:YOLO_ULTRA_LOW_CONF_FLOOR" -ForegroundColor Cyan
Write-Host "Port: $env:YOLO_PORT" -ForegroundColor Cyan
Write-Host "AI fallback enabled: $($(if ($env:AI_FALLBACK_ENABLED) { $env:AI_FALLBACK_ENABLED } else { "true" }))" -ForegroundColor Cyan
Write-Host "OpenAI key loaded: $([bool]$env:OPENAI_API_KEY)" -ForegroundColor Cyan
Write-Host "Python: $($python.Exe) $($python.Args -join ' ')" -ForegroundColor Cyan
Write-Host "Health: http://127.0.0.1:$Port/health" -ForegroundColor Cyan
if ($AutoRestart) {
	Write-Host "Auto-restart: enabled (max restarts: $MaxRestarts, delay: ${RestartDelaySec}s)" -ForegroundColor Cyan
}

Push-Location $projectRoot
try {
	$restartCount = 0
	do {
		& $python.Exe @($python.Args + @($serverScript))
		$exitCode = if ($null -ne $LASTEXITCODE) { [int]$LASTEXITCODE } else { 0 }

		if (-not $AutoRestart -or $exitCode -eq 0) {
			break
		}

		$restartCount++
		if ($restartCount -gt $MaxRestarts) {
			Write-Host "YOLO crashed too many times ($MaxRestarts). Giving up." -ForegroundColor Red
			exit 1
		}

		Write-Host "YOLO exited with code $exitCode. Restarting in ${RestartDelaySec}s... ($restartCount/$MaxRestarts)" -ForegroundColor Yellow
		Start-Sleep -Seconds $RestartDelaySec
	} while ($true)
} finally {
	Pop-Location
}
