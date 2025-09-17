#A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
function ShowJsonRequest {
    Write-Host -ForegroundColor Yellow "JSON REQUEST"
    $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json
    $PSObjShow.auth = "*****"
    $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
    Write-Host -ForegroundColor Cyan $JsonShow
}