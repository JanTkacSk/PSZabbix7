function Set-ZXHostNameCase{
    param(
        [string]$HostName,
        [switch]$ToUpper,
        [switch]$ToLower,
        [string]$HostId,
        [switch]$SameAlias,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$Transcript,
        [switch]$Force,
        [bool]$Confirm=$true
    )
    #Start Transcript
    if($Transcript){
        Start-Transcript
    }

    #Verify parameters

    #WARNING if you want the alias to be equal to the name, use -SameAlias switch and run the command again.
    if(!$SameAlias){
        Write-Host "If you want the alias to be equal to the name, use -SameAlias switch to set it to the same value as name"
        pause
    }
        

    if ($HostName -and $HostId){
        Write-Host -ForegroundColor Yellow 'Not allowed to use -HostName and -HostID parameters together'
        continue
    }
    
    #Funcions
    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    } 

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "host.update"; 
        "params" = [PSCustomObject]@{
            "hostid" = $HostId
        }; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }

    if($HostId){
        $ZXHost = Get-ZXHost -HostID $HostId
        if($null -eq $ZXHost.hostid){
            Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
            Write-Host " $HostId"
            Continue
        }

    }
    elseif ($HostName){
        $ZXHost = Get-ZXHost -Name $HostName
        if($null -eq $ZXHost.host){
            Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
            Write-Host " $HostName"
            Continue
        }

    }
    #NewHostName
    if ($ToUpper){
        $NewHostName ="$($ZXHost.host)".ToUpper()
    }
    if ($ToLower){
        $NewHostName ="$($ZXHost.host)".ToLower()
    }
    
    #Read the $ZXHost properties and use the values to fill in $PSobject properties. $PSobject is later converted to $json request
    #This is setting host parameter
    $PSObj.params.hostid = $ZXHost.hostid
    $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $NewHostName
    #If -SameAlias switch is not used, the host alias is not changed.
    if($SameAlias){
        #This is setting name parameter to what you set as the host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $NewHostName
    }
    else{
        #This is setting name parameter to the same name as it was before
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
    } 
    
    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request | ConvertTo-Json -Depth 5)
    }

    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    elseif ($null -ne $Request.result) {
        Write-Host -ForegroundColor Green "$($Request.result.hostids) [$HostName] > $NewHostName"
        return
    }
    elseif(!$WhatIf) {
        Write-Host -ForegroundColor Yellow "No result"
        return
    }

    if($Transcript){
        Stop-Transcript
    }
    
}