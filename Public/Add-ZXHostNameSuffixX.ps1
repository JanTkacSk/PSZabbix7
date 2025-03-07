function Add-ZXHostNameSuffixX{
    param(
        [array]$HostName,
        [array]$HostId,
        [string]$Suffix,
        [switch]$SameAlias,
        [switch]$WhatIf,
        [bool]$WriteLog=$true,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$Transcript,
        [switch]$Force,
        [bool]$Confirm=$true
    )

    #Variables
    #Loop Id must be defined before the loop and passed to the function so that it does not change with each iteration
    $LoopId = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid
    #Name of the command we use
    $CommandName = $MyInvocation.MyCommand.Name
    #Command parameters including their values(arguments) in a hashtable
    $CommandParameters = $MyInvocation.BoundParameters
    $DateTime = (Get-Date).ToString("yyyy-MM-dd_HH.mm.ss.ffff")
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Log"
    $LogPath = "$SaveLocation\$($DateTime)_$($CommandName).json"
    $LogObject = [PSCustomObject]@{
        "TimeStamp" = Get-Date -Format "MM/dd/yyyy HH:mm"
        "TimeZone" = Get-TimeZone | Select-Object -ExpandProperty DisplayName
        "CommandName" = $CommandName
        "CommandParameters" = $CommandParameters
        "LoopID" = $LoopID
        "RequestResponse" = @()
        "HostsNotFound" = @()
        "Skipped" = @()
    }

    #Validate parameters
    #WARNING if you want the alias to be equal to the name, use -SameAlias switch and run the command again.
    if(!$SameAlias){
        Write-Host "If you want the alias to be equal to the name, use -SameAlias switch and set it to the same value as name"
        pause
    }
        
    if ($HostName -and $HostId){
        Write-Host -ForegroundColor Yellow 'Not allowed to use -HostName and -HostID parameters together'
        continue
    }

    function SetZXHostNameSuffixX {
        param(
            [string]$LoopID,
            [string]$HostId,
            [string]$HostName
        )
        
        #Variables
        #CorrelationID which is the same for request and the response. Since we are looping through multiple servers, we get multiple
        #requests and responses, correlation Id can links the request with the corresponding response
        $CorrelationID = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid

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
            $ZXHost = Get-ZXHost -HostID $HostId -Output hostid,host,name -IncludeItems -ItemProperties type
            if($null -eq $ZXHost.hostid){
                Write-Host "$HostId > " -NoNewline
                Write-Host -ForegroundColor Yellow Not Found
                $LogObject.HostsNotFound += $HostId
                Continue
            }

        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -Output hostid,host,name -IncludeItems -ItemProperties type
            if($null -eq $ZXHost.host){
                Write-Host "$HostName > " -NoNewline
                Write-Host -ForegroundColor Yellow Not Found
                $LogObject.HostsNotFound += $HostName
                Continue
            }

        }
        #Check if the host contains a dot. If so skip the host and add it to the log object.
        if($ZXHost.host -like "*.*" -and -not $Force){
            Write-Host -ForegroundColor Yellow "[$($ZXHost.host)] => Skipped (Has a dot in the name.)."
            $LogObject.Skipped += $ZXHost.host
            continue
        }

        #Check if the host contains any active check. If so skip the host and add it to the log object.
        if($ZXHost.items.type -contains "7" -and -not $Force){
            Write-Host -ForegroundColor Yellow "[$($ZXHost.host)] => Skipped (Has Agent Active Checks) ."
            $LogObject.Skipped += $ZXHost.host
            continue
        }
        #NewHostName
        $NewHostName = $ZXHost.host + "." + $Suffix.trim(".")
        #Read the $ZXHost properties and use the values to fill in $PSobject properties. $PSobject is later converted to $json request
        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $NewHostName
        #If -SameAlias switch is not used, the host alias is not changed.
        if($SameAlias){
            $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $NewHostName
        }
        else{
            $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        } 
        
        $Json = $PSObj | ConvertTo-Json -Depth 5

        #Save JSON Request if -WriteLog is not $false. Default is $true.
        If ($WriteLog){
            $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5
            $PSObjShow.auth = "*****"
            $RequestLogObject = [PSCustomObject]@{
                "Time" = Get-Date -Format "MM/dd/yyyy HH:mm"
                "Type" = "Request"
                "CorrelationID" = $CorrelationID
                "LoopID" = $LoopID
                "Original Status" = $ZXHost
                "RequestObject" = $PSObjShow
            }
            $LogObject.RequestResponse += $RequestLogObject              
        }
        

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

        #Save JSON Request if -WriteLog is not $false. Default is $true.
        If ($WriteLog){
            if($null -ne $Request.error){
                $ResponseObject = $Request.error
            }
            else{
                $ResponseObject = $Request.result
            }
            $ResponseLogObject = [PSCustomObject]@{
                "Time" = Get-Date -Format "MM/dd/yyyy HH:mm"
                "Type" = "Response"
                "CorrelationID" = $CorrelationID
                "LoopID" = $LoopID
                "ResponseObject" = $ResponseObject
            }
            $LogObject.RequestResponse += $ResponseLogObject
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
            Write-Host -ForegroundColor Green "$($Request.result.hostids) $HostName > $NewHostName"
            return
        }
        elseif(!$WhatIf) {
            Write-Host -ForegroundColor Yellow "No result"
            return
        }

    }#SetZXHostNameSuffixX

    if($HostName){
        foreach($Name in $HostName){
            SetZXHostNameSuffixX -HostName $Name -LoopID $LoopID 
        }    
    }
    if($HostID){
        foreach($Id in $HostId){
            SetZXHostNameSuffixX -HostId $Name -LoopID $LoopID 
        }    
    }

    $LogObject | ConvertTo-Json -Depth 6 | Out-File -FilePath $LogPath
    #Display the hosts that were skipped
    if ($LogObject.Skipped.length -gt 0){
        Write-Host "The following hosts were skipped. Use -Force to override."
        $LogObject.Skipped
    }
    #Display the hosts that were not found
    if ($LogObject.HostsNotFound.length -gt 0){
        Write-Host "The following hosts were not found."
        $LogObject.HostsNotFound
    }
    #Display the log location in the console
    Write-Host -ForegroundColor DarkCyan "Log: $LogPath"    

}


