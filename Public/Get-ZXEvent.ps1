function Get-ZXEvent {
    param(
        [array]$HostID,
        [array]$GroupID,
        [array]$EventID,
        [switch]$IncludeTags,
        [array]$Output,
        [switch]$CountOutput,
        [switch]$IncludeAlerts,
        [switch]$WhatIf,
        [datetime]$StartDate,
        [int]$StartDaysAgo,
        [int]$Limit
    )
    #Validate Parameters
    if (!$Output){
        $Output = @("eventid","name")
        
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }
    
  
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "event.get"

    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }

    if ($Output){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    }
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostIDs
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if ($EventID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "eventids" -Value $EventID
    }
    if ($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value @("tag","value")
    }
    if ($IncludeAlerts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectAlerts" -Value @("subject","alertid","actionid")
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }


    if ($StartDaysAgo){
        $StartDateWindows = (Get-Date).AddDays(-$($StartDaysAgo))
        $StartDateUnix =  ConvertTo-UnixTime -StandardTime $StartDateWindows
        $StartDateUnix = "$([int]([System.Math]::Floor($StartDateUnix)))"

        $PSObj.params | Add-Member -MemberType NoteProperty -Name "time_from" -Value $StartDateUnix
    }

    if ($StartDate){
        $StartDateUnix =  ConvertTo-UnixTime -StandardTime $StartDate
        $StartDateUnix = "$([int]([System.Math]::Floor($StartDateUnix)))"

        $PSObj.params | Add-Member -MemberType NoteProperty -Name "time_from" -Value $StartDateUnix
    }

    $Json =  $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($Whatif){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
    
}


