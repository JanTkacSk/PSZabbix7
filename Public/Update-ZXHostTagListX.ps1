function Update-ZXHostTagListX{
    param(
        [array]$HostName,
        [array]$HostID,
        [string]$AddTag, 
        [string]$AddTagValue,
        [string]$RemoveTagValue,
        [string]$RemoveTag,
        [switch]$RemoveAllTags,
        [switch]$WhatIf,
        [bool]$WriteLog=$true,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse

    )
    #ValidateParameters
    if ($AddTag -eq $RemoveTag -and $AddTagValue -eq $RemoveTagValue){
        Write-Host -ForegroundColor Red "You are trying to add and remove an identical tag/value pair. Choose only one operation."
        continue
    }
    if($RemoveTag -and -not $RemoveTagValue ) {
        Write-Host -ForegroundColor Yellow "-RemoveTagValue parameter was not specified. This will remove all $RemoveTag tags regardless of the value. Continue ?"
        Pause    
    }
    #Variables
    #Loop Id must be defined before the loop and passed to the function so that it does not change with each iteration
    $LoopID = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid
    #Name of the command we use
    $CommandName = $MyInvocation.MyCommand.Name
    #Command parameters including their values(arguments) in a hashtable
    $CommandParameters = $MyInvocation.BoundParameters
    $DateTime = (Get-Date).ToString("yyyy-MM-dd_HH.mm.ss.ffff")
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Log"
    $LogPath = "$SaveLocation\$CommandName_$DateTime.json"
    $LogObject = [PSCustomObject]@{
        "TimeStamp" = Get-Date -Format "MM/dd/yyyy HH:mm"
        "TimeZone" = Get-TimeZone | Select-Object -ExpandProperty DisplayName
        "CommandName" = $CommandName
        "CommandParameters" = $CommandParameters
        "LoopID" = $LoopID
        "RequestResponse" = @()
        "HostsNotFound" = @()
    }

    #Validate Parameters
    if ($AddTag -eq $RemoveTag -and $AddTagValue -eq $RemoveTagValue){
        Write-Host -ForegroundColor Red "You are trying to add and remove an identical tag/value pair. Choose only one operation."
        continue
    }

    #Variables
    #CorrelationID which is the same for request and the response. Since we are looping through multiple servers, we get multiple
    #requests and responses, correlation Id can links the request with the corresponding response
    $CorrelationID = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid
    
    #Funcions
    function UpdateZXHostTagListX{
        param(
            [array]$HostId,
            [array]$HostName,
            [string]$LoopID
        )
        #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
        function ShowJsonRequest {
            Write-Host -ForegroundColor Yellow "JSON REQUEST"
            $PSObjShow = $PSObj
            $PSObjShow.auth = "*****"
            $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
            Write-Host -ForegroundColor Cyan $JsonShow
        }

        #CreateaLogDirectory if it does not exist
        if (!(Test-Path $SaveLocation)) {
            New-Item $SaveLocation -ItemType Directory
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

        if($AddTag -or $RemoveTag -or $RemoveAllTags){

            if($HostId){
                $ZXHost = Get-ZXHost -HostID $HostId 
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
            #Get the tag list which will be later adjusted
            [System.Collections.ArrayList]$TagList = $ZXHost.tags

            if($AddTag){
                $TagList =  $Taglist += [PSCustomObject]@{"tag"= $AddTag; "value"=$AddTagValue}
            }
            
            if($RemoveTag){
                if (!$RemoveTagValue){
                    $TagList = $TagList | Where-Object {$_.tag -cne $RemoveTag}
                }
                if($RemoveTagValue){
                    $TagList.Remove(($TagList|Where-Object {$_.tag -ceq $RemoveTag -and $_.value -ceq $RemoveTagValue}))
                }
            }

            if($RemoveAllTags){
                $TagList = @()
            } 

            $PSObj.params |  Add-Member -MemberType NoteProperty -Name "tags" -Value @($TagList)

        }

        $Json = $PSObj | ConvertTo-Json -Depth 5


        #Save JSON Request if -WriteLog is not $false. Default is $true.
        If ($WriteLog){
            $RequestLogObject = [PSCustomObject]@{
                "Time" = Get-Date -Format "MM/dd/yyyy HH:mm"
                "Type" = "Request"
                "CorrelationID" = $CorrelationID
                "LoopID" = $LoopID
                "RequestObject" = $PSObj
                "Original Status" = $ZXHost
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
        elseif($null -ne $Request.result){
            Write-Host -ForegroundColor Green ("$($Request.result.hostids)" + " $HostName") 
            return
        }
        elseif(!$WhatIf) {
            Write-Host -ForegroundColor Yellow "No result"
            return
        }
        
    }#UpdateZXHostTagListX

    #Loop through all the hostnames if hostnames are used to identify the hosts.
    if ($HostName){
        foreach ($Name in $HostName){
            UpdateZXHostTagListX -HostName $Name -LoopID $LoopID
        }
    }
    #Loop through all the hostids if hostids are used to identify the hosts
    elseif($HostId){
        foreach($Id in $HostId){
            UpdateZXHostTagListX -HostId $Id -LoopID $LoopID
        }
    }
    #Write the log into a new file. The log object is written by the parent function 
    #so you can exit the nested function without having to writ into log before you exit.

    $LogObject | ConvertTo-Json -Depth 6 | Out-File -FilePath $LogPath
    #Display the log location in the console
    Write-Host -ForegroundColor DarkCyan "Log: $LogPath"
        
}
