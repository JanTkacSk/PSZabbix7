function Get-ZXApiVersion {

    param (
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "apiinfo.version";
        "params" = @();
        "id"  = "1"
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
    elseif($Request.result){
        $request.result
    }    
}
