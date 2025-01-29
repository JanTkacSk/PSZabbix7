function Stop-ZXSession {
    param(
        [switch]$ShowJsonRequest=$true,
        [switch]$ShowJsonResponse,
        [string]$SessionID,
        [string]$ZXAPIUrl = $ZXAPIUrl,
        [switch]$WhatIf
    )

    if ($null -eq $ZXAPIUrl){
        $ZXAPIUrl = Read-Host -Prompt "Enter the zabbix API url:" 
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    if ($SessionID){     
        $Auth = $SessionID
    }
    else {
        $Auth = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($ZXAPIToken)));
    }
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.logout";
        "params" = @();
        "auth" = "$Auth"
        "id" = "1"

    }
    $JSON = $PSObj | ConvertTo-Json
    
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }
    
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request | ConvertTo-Json -Depth 5)
    }

    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        $Request.result
        return
    }
}
