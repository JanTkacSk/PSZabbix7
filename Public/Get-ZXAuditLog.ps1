function Get-ZXAuditLog {
    param(
        [array]$ResourceID,
        [string]$ResourceIDSearch,
        [array]$ResourceType,
        [string]$ResourceTypeSearch,
        [array]$ResourceName,
        [string]$ResourceNameSearch,
        [string]$Limit,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [int]$StartDate,
        [int]$StartDaysAgo
    )
    #Validate Parameters
    if($StartDate -and $StartDaysAgo){
        Write-Host -ForegroundColor Yellow "Only one start date can be used !"
        continue
    }

    function ConvertTo-UnixTime{
    param(
        [datetime]$StandardTime
    )

    #This is when unix epoch started - 01 January 1970 00:00:00.
    $Origin = [datetime]::UnixEpoch
    foreach ($ST in $StandardTime){
        $UnixTime = $ST - $Origin | Select-Object -ExpandProperty TotalSeconds
        Write-Output $UnixTime
    }
}

    if ($StartDaysAgo){
        $StartDateWindows = (Get-Date).AddDays(-$($StartDaysAgo))
        $StartDateUnix = ConvertTo-UnixTime -StandardTime $StartDateWindows
        $StartDateUnix
    }
    #Function to add a FILTER parameter to the PS object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
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
        "method" = "auditlog.get";
        "params" = [PSCustomObject]@{
            "output" = "extend"
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    if($Limit){$PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit}
    if($ResourceID){AddFilter -PropertyName "resourceid" -PropertyValue $ResourceID}
    if($ResourceIDSearch){AddSearch -PropertyName "resourceid" -PropertyValue $ResourceIDSearch}
    if($ResourceNameSearch){AddSearch -PropertyName "resourcename" -PropertyValue $ResourceNameSearch}

    #Convert the PSObjec to Json
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

    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        $Request.result
        return
    }
    
}