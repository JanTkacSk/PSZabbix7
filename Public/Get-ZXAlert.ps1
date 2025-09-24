function Get-ZXAlert {
    param(
        [array]$HostID,
        [array]$GroupID,
        [array]$EventID,
        [array]$Output,
        [switch]$CountOutput,
        [switch]$WhatIf,
        [datetime]$StartDate,
        [int]$StartDaysAgo,
        [int]$Limit
    )

    #Validate Parameters
    if (!$Output){
        $Output = @("alertid","actionid","clock","subject")
        
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "alert.get"
    
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    if ($EventID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "eventids" -Value @($EventID)
    }
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostIDs
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    if ($Output){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
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

    #$PSObj.params.output = "extend"
    $Json =  $PSObj | ConvertTo-Json -Depth 3
    
    #Show JSON Request if -Whatif switch is used
    If ($WhatIf){
        Write-JsonRequest
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }

}


