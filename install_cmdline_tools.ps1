# PowerShell script to install Android SDK Command-line Tools

$sdkPath = "C:\Users\kishor\AppData\Local\Android\sdk"
$cmdlineToolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$zipFile = "$env:TEMP\commandlinetools.zip"
$extractPath = "$sdkPath\cmdline-tools"

Write-Host "Downloading Android SDK Command-line Tools..." -ForegroundColor Green
Invoke-WebRequest -Uri $cmdlineToolsUrl -OutFile $zipFile

Write-Host "Creating cmdline-tools directory..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path $extractPath | Out-Null

Write-Host "Extracting files..." -ForegroundColor Green
Expand-Archive -Path $zipFile -DestinationPath "$extractPath\temp" -Force

Write-Host "Organizing files..." -ForegroundColor Green
if (Test-Path "$extractPath\latest") {
    Remove-Item "$extractPath\latest" -Recurse -Force
}
Move-Item "$extractPath\temp\cmdline-tools" "$extractPath\latest"
Remove-Item "$extractPath\temp" -Recurse -Force

Write-Host "Cleaning up..." -ForegroundColor Green
Remove-Item $zipFile

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "Command-line tools installed at: $extractPath\latest" -ForegroundColor Cyan

Write-Host "`nSetting environment variables..." -ForegroundColor Green
Write-Host "Please add the following to your PATH:" -ForegroundColor Yellow
Write-Host "$extractPath\latest\bin" -ForegroundColor Cyan

Write-Host "`nYou can now use avdmanager and sdkmanager commands!" -ForegroundColor Green
