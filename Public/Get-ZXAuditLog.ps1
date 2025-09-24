function Get-ZXAuditLog {
    param(
        [array]$ResourceID,
        [string]$ResourceIDSearch,
        [array]$ResourceType,
        [string]$ResourceTypeSearch,
        [array]$ResourceName,
        [string]$ResourceNameSearch,
        [string]$Limit,
        [switch]$WhatIf,
        [int]$StartDate,
        [int]$StartDaysAgo
    )
    #Validate Parameters
    if($StartDate -and $StartDaysAgo){
        Write-Host -ForegroundColor Yellow "Only one start date can be used !"
        continue
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "auditlog.get"
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value "extend"

    # add time_from propertie
    if ($StartDaysAgo){
        $StartDateWindows = (Get-Date).AddDays(-$($StartDaysAgo))
        $StartDateUnix =  ConvertTo-UnixTime -StandardTime $StartDateWindows
        $StartDateUnix = "$([int]([System.Math]::Floor($StartDateUnix)))"

        $PSObj.params | Add-Member -MemberType NoteProperty -Name "time_from" -Value $StartDateUnix
    }
    
    if($Limit){$PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit}
    if($ResourceID){AddFilter -PropertyName "resourceid" -PropertyValue $ResourceID}
    if($ResourceIDSearch){AddSearch -PropertyName "resourceid" -PropertyValue $ResourceIDSearch}
    if($ResourceNameSearch){AddSearch -PropertyName "resourcename" -PropertyValue $ResourceNameSearch}

    #Convert the PSObjec to Json
    $Json =  $PSObj | ConvertTo-Json -Depth 3

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($WhatIf){
        Write-JsonRequest
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post

        if($null -ne $Request.error){
        $Request.error
        return
        } else {
            $Request.result | % {
            $LocalTime =  ConvertFrom-UnixTime -UnixTime $_.clock
            $_ | Add-Member -MemberType NoteProperty -Name "clock_standard" -Value $LocalTime
            $_ | Add-Member -MemberType NoteProperty -Name "clock_time_Zone" -Value $([System.TimeZoneInfo]::Local).DisplayName
            $_
            }
            return
        }
    }
    
}