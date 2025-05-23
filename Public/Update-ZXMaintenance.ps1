function Update-ZXMaintenance {
    param(
        [array]$GroupID,
        [array]$HostIDReplace,
        [string]$MaintenanceID,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Validate Parameters

    #Functions

    # Create an array of objects from a simple array. Each object has only one property $PropertyName (you choose the name).
    # For example from the following array "1234","4321" it creates two objects "hostid" = "1234" and "hostid" = "4321"
    # and puts it into an array, then you can add it to the PS object and convert it to json object for the API request.
    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{$PropertyName = "$item"}
        }
        $Result
        return
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "maintenance.update";
        "params" = [PSCustomObject]@{};
        "id" = 1;
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    if ($HostIDReplace){
        $HostIDObjects = ConvertArrayToObjects -PropertyName "hostid" -Array $HostIDReplace
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hosts" -Value @($HostIDObjects)
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if ($MaintenanceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "maintenanceid" -Value $MaintenanceID
    }

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
    if($WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
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
