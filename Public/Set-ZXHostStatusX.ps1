function Set-ZXHostStatusX{
    param(
        [array]$HostName,
        [array]$HostId,
        [ValidateSet("0","1","Enabled","Disabled")]
        [Parameter(Mandatory=$true)]
        [string]$Status,
        [switch]$WhatIf,
        [bool]$WriteLog=$true,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse
    )

    #Verify parameters
    if ($HostName -and $HostId){
        Write-Host -ForegroundColor Yellow 'Not allowed to use -HostName and -HostID parameters together'
        continue
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
    #Functions
    #This function is used in a loop, it takes all the parameters of the main function
    #it has $HostName and $HostId parameters but they are strings, not arrays. 
    #Loop Id must be defined before the loop and passed to the function so that it does not change with each iteration
    function SetZXHostStatusX{
        param(
            [string]$HostName,
            [string]$HostId,
            [string]$LoopID
        )
        #Variables
        #CorrelationID which is the same for request and the response. Since we are looping through multiple servers, we get multiple
        #requests and responses, correlation Id can links the request with the corresponding response
        $CorrelationID = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid
        
        #Functions
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
            "auth" = "*****"
            "id" = "1"
        }

        #CreateaLogDirectory if it does not exist
        if (!(Test-Path $SaveLocation)) {
            New-Item $SaveLocation -ItemType Directory
        }

        #Change the human friendly status to format suitable for json call - 0 or 1
        switch ($Status) {
            "Enabled" {$Status = "0"}
            "Disabled" {$Status = "1"}
        }

        #Get host information based on the $HostId or $HostName depending on which parameter is used
        if($HostId){
            $ZXHost = Get-ZXHost -HostID $HostId
            #Check if the host was found based on hostid, if not, display a message and exit the function
            if($null -eq $ZXHost.hostid){
                Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
                Write-Host " $HostId"
                $LogObject.HostsNotFound += $HostId
                Continue
            }
        }
        elseif($HostName){
            $ZXHost = Get-ZXHost -Name $HostName
            #Check if the host was found based on host name, if not, display a message and exit the function
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
            ShowJsonRequest
        }
        #Add the Token value to the $psobj
        #This is the same as $ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        $PSObj.auth = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($ZXAPIToken))); 
        
        $Json = $PSObj | ConvertTo-Json -Depth 5

        #Make the API call
        if(!$Whatif){
            $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        }
        else{
            continue
        }
        #Save JSON Request if -WriteLog is not $false. Default is $true.
        If ($WriteLog){
            if($null -ne $Request.error){
                $ResponseObject = $Request.error
            } 
            else {
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

        #This will be returned by the function in case the response contains an error
        if($null -ne $Request.error){
            Write-Host -ForegroundColor Yellow $($Request.error)
            return
        }
        #This will be returned by the function in case the response contains non-error result
        elseif ($null -ne $Request.result) {
            Write-Host -NoNewline -ForegroundColor Green "[Status: $Status]" 
            Write-Host -ForegroundColor Green (" $($Request.result.hostids)" + " $HostName") 
            return
        }
        elseif(!$WhatIf) {
            Write-Host -ForegroundColor Yellow "No result"
            return
        }  
    }#SetZXHostStatusEnd

    #Display a help about what number means represends what status
    Write-Host -ForegroundColor DarkCyan "Status: 0 = enabled, Status: 1 = disabled"

    #Loop through all the hostnames if hostnames are used to identify the hosts.
    if ($HostName){
        foreach ($Name in $HostName){
            SetZXHostStatusX -HostName $Name -LoopID $LoopID
        }
    }
    #Loop through all the hostids if hostids are used to identify the hosts
    elseif($HostId){
        foreach($Id in $HostId){
            SetZXHostStatusX -HostId $Id -LoopID $LoopID
        }
    }
    #Write the log into a new file. The log object is written by the parent function 
    #so you can exit the nested function without having to writ into log before you exit.

    $LogObject | ConvertTo-Json -Depth 6 | Out-File -FilePath $LogPath
    #Display the log location in the console
    Write-Host -ForegroundColor DarkCyan "Log: $LogPath"
}
