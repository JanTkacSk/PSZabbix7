function Get-ZXProblem {
    param(
        [array]$HostID,
        [array]$GroupID,
        [array]$EventID,
        [int]$Source,
        [switch]$IncludeTags,
        [switch]$Recent,
        [switch]$CountOutput,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [int]$Limit,
        [array]$Output,
        [switch]$WhatIf,
        [datetime]$StartDate,
        [int]$StartDaysAgo,
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
        #$Origin = [datetime]::UnixEpoch
        $Origin = [datetime]::SpecifyKind([datetime]::Parse("1970-01-01T00:00:00"), [System.DateTimeKind]::Utc)
        foreach ($ST in $StandardTime){
            $UnixTime = $ST - $Origin | Select-Object -ExpandProperty TotalSeconds
            Write-Output $UnixTime
        }
    }

    function ConvertFrom-UnixTime{
        param(
            [array]$UnixTime
        )
        
        # Get the local time zone info
        #$LocalTimeZone = [System.TimeZoneInfo]::Local
        #This is when unix epoch started - 01 January 1970 00:00:00.
        $Origin = [datetime]::UnixEpoch
        foreach ($UT in $UnixTime){
            #$TimeZoneToDisplay = LocalTimeZone.DisplayName
            $StandardTime = $Origin.AddSeconds($UT).ToLocalTime()
            Write-Output $StandardTime
        }
    }
    if (!$Output){
        $Output = @("name","objectid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    function ConvertFrom-UnixEpochTime ($UnixEpochTime){
        $customDate = (Get-Date -Date "01-01-1970") + ([System.TimeSpan]::FromSeconds($UnixEpochTime))
        $customDate
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
        "method" = "problem.get";
        "params" = [PSCustomObject]@{};
        "id" = 1;
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }
    
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "recent" -Value "false"

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
    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    #$PSObj.params.output = "extend"
    $Json =  $PSObj | ConvertTo-Json -Depth 3

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
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
