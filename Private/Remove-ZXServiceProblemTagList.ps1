function Remove-ZXServiceProblemTagList {
    param(
        [string]$ServiceID,
        [switch]$ShowJsonRequest,
        [switch]$WhatIf,
        [PSCustomObject]$Parameters,
        [array]$StatusRule

    )


    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "service.update";
        "params" = [PSCustomObject]@{
            "serviceid" = $ServiceID;
            "problem_tags" = @();
        }; 
        #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
        "id" = 1;
    }


    #Convert the ps object to json. It is crucial to use a correct value for the -Depth
    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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