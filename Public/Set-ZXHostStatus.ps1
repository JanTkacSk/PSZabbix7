function Set-ZXHostStatus{
    param(
        [string]$HostName,
        [string]$HostId,
        [ValidateSet("0","1","Enabled","Disabled")]
        [Parameter(Mandatory=$true)]
        [string]$Status,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse
    )
    #Verify parameters
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

    switch ($Status) {
        "Enabled" {$Status = "0"}
        "Disabled" {$Status = "1"}
    }

    if($Status){

        if($HostId){
            $ZXHost = Get-ZXHost -HostID $HostId -IncludeTags
            if($null -eq $ZXHost.hostid){
                Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
                Write-Host " $HostId"
                $LogObject.HostsNotFound += $HostId
                Continue
            }

        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -IncludeTags
            if($null -eq $ZXHost.host){
                Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
                Write-Host " $HostName"
                $LogObject.HostsNotFound += $HostName
                Continue
            }

        }
        #Read the $ZXHost properties and use the values to fill in $PSobject properties. $PSobject is later converted to $json request
        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "status" -Value $Status
    
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
        $Request.result
        return
    }
    elseif(!$WhatIf) {
        Write-Host -ForegroundColor Yellow "No result"
        return
    }
    
}


