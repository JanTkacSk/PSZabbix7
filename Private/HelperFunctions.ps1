#A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
Function Write-JsonRequest {
    Write-Host -ForegroundColor Yellow "JSON REQUEST"
    $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json
    $PSObjShow.auth = "*****"
    $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
    Write-Host -ForegroundColor Cyan $JsonShow
}

#Basic PS Object wich will be edited based on the used parameters and finally converted to json
Function New-ZXApiRequestObject ($Method){
        return [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "$Method"; 
        "params" = [PSCustomObject]@{}; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }
}
