function Get-ZXProblem {
    param(
        [array]$HostID,
        [array]$GroupID,
        [array]$EventID,
        [int]$Source,
        [switch]$IncludeTags,
        [switch]$Recent,
        [switch]$CountOutput,
        [int]$Limit,
        [array]$Output,
        [switch]$WhatIf,
        [datetime]$StartDate,
        [int]$StartDaysAgo
    )

    #Validate Parameters
    if($StartDate -and $StartDaysAgo){
        Write-Host -ForegroundColor Yellow "Only one start date can be used !"
        continue
    }

    if (!$Output){
        $Output = @("name","objectid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "problem.get"
    
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if ($EventID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "eventids" -Value $EventID
    }
    if ($Source){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "source" -Value $Source
    }
    if ($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value @("tag","value")
    }
    if ($Recent){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "recent" -Value "true"
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

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    
    # Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    
    # $PSObj.params.output = "extend"
    $Json =  $PSObj | ConvertTo-Json -Depth 5

    # Show JSON Request if -ShowJsonRequest switch is used
    If ($WhatIf){
        Write-JsonRequest
    }
    
    # Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }

}
