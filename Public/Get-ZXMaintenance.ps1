function Get-ZXMaintenance {
    param(
        [array]$GroupID,
        [array]$HostID,
        [array]$MaintenanceID,
        [string]$Name,
        [string]$NameSearch,
        [array]$Output,
        [switch]$IncludeHostGroups,
        [switch]$IncludeHosts,
        [switch]$IncludeTags,
        [switch]$IncludeTimePeriods,
        [array]$TimePeriodProperties,
        [switch]$CountOutput,
        [int]$Limit,
        [switch]$WhatIf
    )

    # Validate Parameters
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

    # Functions

    # Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "maintenance.get"

    # Return a maintenance based on host name FILTER
    if($Name){
        AddFilter -PropertyName "name" -PropertyValue $Name
    }

    # Return a maintenance  based on host name SEARCH. 
    if($NameSearch){
        AddSearch -PropertyName "name" -PropertyValue $NameSearch
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
    # Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    $Json =  $PSObj | ConvertTo-Json -Depth 5

    if($WhatIf){
        Write-JsonRequest
    }
   
    # Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }

}
