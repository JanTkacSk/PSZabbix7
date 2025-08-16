function Get-ZXAlert {
    param(
        [array]$HostID,
        [array]$GroupID,
        [array]$EventID,
        [array]$Output,
        [switch]$CountOutput,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
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

    function ConvertFrom-UnixTime{
        param(
            [array]$UnixTime
        )
        
        # Get the local time zone info
        #$LocalTimeZone = [System.TimeZoneInfo]::Local
        #This is when unix epoch started - 01 January 1970 00:00:00.
        #$Origin = [datetime]::UnixEpoch
        $Origin = [datetime]::SpecifyKind([datetime]::Parse("1970-01-01T00:00:00"), [System.DateTimeKind]::Utc)
        foreach ($UT in $UnixTime){
            #$TimeZoneToDisplay = LocalTimeZone.DisplayName
            $StandardTime = $Origin.AddSeconds($UT).ToLocalTime()
            Write-Output $StandardTime
        }
    }
    
    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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
        "method" = "alert.get";
        "params" = [PSCustomObject]@{
        };
        "id" = 1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

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

    #Show JSON Response if -ShowJsonResponse switch is used
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "`nJSON RESPONSE"
        if($null -ne $Request.error){
            Write-Host -ForegroundColor Cyan "$($request.error | ConvertTo-Json -Depth 5)`n"
        }
        else{
            Write-Host -ForegroundColor Cyan "$($request.result | ConvertTo-Json -Depth 5)`n"
        }
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


