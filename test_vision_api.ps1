# Test Google Vision API
$apiKey = "AIzaSyC6Nb6h7Ryipjzno9JDYHpXO95iwpCPJaA"

# Simple test with a base64 image
$body = @{
    requests = @(
        @{
            image = @{
                content = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
            }
            features = @(
                @{
                    type = "LABEL_DETECTION"
                    maxResults = 5
                }
            )
        }
    )
} | ConvertTo-Json -Depth 10

try {
    $response = Invoke-RestMethod -Uri "https://vision.googleapis.com/v1/images:annotate?key=$apiKey" `
        -Method Post `
        -ContentType "application/json" `
        -Body $body
    
    Write-Host "✅ API WORKS!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 5
} catch {
    Write-Host "❌ API FAILED!" -ForegroundColor Red
    Write-Host "Status Code: $($_.Exception.Response.StatusCode.Value__)" -ForegroundColor Yellow
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    
    if ($_.Exception.Response.StatusCode.Value__ -eq 403) {
        Write-Host ""
        Write-Host "403 Forbidden means:" -ForegroundColor Red
        Write-Host "  1. Cloud Vision API is NOT enabled" -ForegroundColor Yellow
        Write-Host "  2. OR billing is NOT set up" -ForegroundColor Yellow
        Write-Host "  3. OR API key restrictions are blocking the request" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Fix at: https://console.cloud.google.com/" -ForegroundColor Cyan
    }
}
