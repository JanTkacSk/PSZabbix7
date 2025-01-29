function GEt-ZXSession {
    param(
        [securestring]$SessionID,
        [string]$SessionIDPlainText,
        [securestring]$Token,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [switch]$ShowSessionID
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.checkAuthentication";
        "params" = [PSCustomObject]@{};
        "id"  = "1"
    }

    if ($SessionID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sessionid" -Value "$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))))"
    }
    elseif ($SessionIDPlainText) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sessionid" -Value $SessionIDPlainText
    }

    if ($Token){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "token" -Value "$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))))"
    }
    
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        if($PSObjShow.params.sessionid){
            $PSObjShow.params.sessionid = "*****"
        }
        elseif($PSObjShow.params.token){
            $PSObjShow.params.token = "*****"
        }
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    $JSON = $PSObj | ConvertTo-Json -Depth 5

    #Make the API call
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }
    
    If ($ShowJsonResponse){
        #Create a deep copy of the $Request Object. This is necessary because otherwise changing the $PSObjShow is referencing the same object in memory as $Request
        $PSObjShow = $Request.result | ConvertTo-Json -Depth 5 | ConvertFrom-Json 
        if($PSObjShow.sessionid) {
            $PSObjShow.sessionid = "*****"
        }
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($PSObjShow | ConvertTo-Json -Depth 5)
    }

    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        if($Request.result){
            if($ShowSessionID){
                $Request.result
            }
            elseif($request.result.sessionid) {
                $request.result.sessionid = "*****"
                $request.result
            }
            else{
                $request.result
            }
        }
     }
}
