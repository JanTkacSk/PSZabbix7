function Remove-ZXHostTag{
    param(
        [string]$HostName,
        [string]$HostId,
        [string]$TagName,
        [string]$TagValue,
        [switch]$RemoveAllTags,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [bool]$Continue

    )
    #Validate Parameters
    if ($HostId -and $HostName){
    Write-Host -ForegroundColor Red 'You cannot use -HostId and -HostName parameter at the same time'
    continue
    }

    if ($HostId){
        If ($HostId.GetType().Name -ne "String"){
            Write-Host -ForegroundColor Red "HostId must be a String, your input is $($HostId.GetType().Name)"
            continue
        }
    }
    elseif($HostName){
            If ($HostName.GetType().Name -ne "String"){
            Write-Host -ForegroundColor Red "HostName must be a String, your input is $($HostId.GetType().Name)"
            continue
        }
    }

    if($TagName -and -not $TagValue ) {
        Write-Host -ForegroundColor Yellow "'TagValue' parameter was not specified. This will remove all $TagName tags regardless of the value. Continue ?"
        Pause    
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

    if($TagName -or $RemoveAllTags){
       
        if($HostId){
            $ZXHost = Get-ZXHost -HostID $HostId -IncludeTags
        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -IncludeTags
        }

        if($ZXHost -eq $null){
        Write-Host -ForegroundColor Yellow "Host not found"
        continue
        }
    

        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        [System.Collections.ArrayList]$TagList = $ZXHost.tags

        if($TagName){
            if (!$TagValue){                
                $TagList.Remove(($TagList|Where-Object {$_.tag -ceq $TagName}))


            }
            if($TagValue){
                $TagList.Remove(($TagList|Where-Object {$_.tag -ceq $TagName -and $_.value -ceq $TagValue}))
            }
        }
        
        if($RemoveAllTags){
            $TagList = @()
        } 

        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "tags" -Value @($TagList)

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
    elseif($null -ne $Request.result){
        $Request.result
        return
    }
    elseif(!$WhatIf) {
        Write-Host -ForegroundColor Yellow "No result"
        return
    }
    
}


