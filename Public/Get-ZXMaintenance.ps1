function Get-ZXMaintenance {
    param(
        [array]$GroupID,
        [array]$HostID,
        [array]$MaintenanceID,
        [array]$Output,
        [switch]$IncludeHostGroups,
        [switch]$IncludeHosts,
        [switch]$IncludeTags,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$IncludeTimePeriods,
        [array]$TimePeriodProperties,
        [int]$Limit,
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

    if (!$Output){
        [string]$Output = "extend"
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeTimePeriods){
        If (!$TimePeriodProperties){
            [string]$TimePeriodProperties = "extend"
        }
        elseif($TimePeriodProperties -contains "extend"){
            [string]$TimePeriodProperties = "extend"
        }    
    }
    

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "maintenance.get";
        "params" = [PSCustomObject]@{};
        "id" = 1;
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if ($MaintenanceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "maintenanceids" -Value $MaintenanceID
    }
    if ($IncludeTimePeriods){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTimeperiods" -Value $TimePeriodProperties
    }
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("hostid","host")
    }
    if ($IncludeHostGroups){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHostGroups" -Value @("groupid","name")
    }
    if ($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value @("tag","value")
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
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
