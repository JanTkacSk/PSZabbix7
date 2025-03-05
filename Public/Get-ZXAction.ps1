function Get-ZXAction {
    param(
        [array]$ActionID,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [array]$Output
    )

    #Validate Parameters

    if (!$Output){
        $Output = [string]$Output = "extend"
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Functions
    function ConvertFrom-UnixEpochTime ($UnixEpochTime){
        $customDate = (Get-Date -Date "01-01-1970") + ([System.TimeSpan]::FromSeconds($UnixEpochTime))
        $customDate
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "action.get";
        "params" = [PSCustomObject]@{};
        "id" = 1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    if ($ActionID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "actionids" -Value @($ActionID)
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output


    $Json =  $PSObj | ConvertTo-Json -Depth 3

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }
    else {
        ShowJsonRequest
    }

    #Show JSON Response if -ShowJsonResponse switch is used
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "`nJSON RESPONSE"
        if($null -ne $Request.error){
            Write-Host -ForegroundColor Cyan "$($request.error | ConvertTo-Json -Depth 5)`n"
        }
        else{
            Write-Host -ForegroundColor Cyan "$($request.result | ConvertTo-Json -Depth 5)`n"
        }
    }
    
    #Add human readable creation time to the object
    #$Request.result | Add-Member -MemberType ScriptProperty -Name CreationTime -Value {ConvertFrom-UnixEpochTime($this.clock)}
    
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


