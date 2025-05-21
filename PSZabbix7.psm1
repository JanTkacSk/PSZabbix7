
function Add-ZXHostGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [array]$HostID,
        [Parameter(Mandatory=$false)]
        [array]$HostObj,
        [Parameter(Mandatory=$false)]
        [array]$GroupID,
        [Parameter(Mandatory=$false)]
        [array]$GroupObj,
        [Parameter(Mandatory=$false)]
        [switch]$ShowJsonResponse,
        [switch]$ShowJsonRequest,
        [Alias("SaveRes")]
        [bool]$SaveJsonRequest=$false,
        [Alias("SaveReq")]
        [bool]$SaveJsonResponse=$false,
        [switch]$WhatIf
    )
    
    #Funcions
    function DateToString{
        (Get-Date).ToString("2024-MM-dd_HH.mm.ss.ffff")
    }

    #Variables
    $DateTime = DateToString
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Request-Response_$DateTime"

    #CreateaRequestResponseDirectory
    New-Item $SaveLocation -ItemType Directory


    #Check if the parameters are not missing or if the combination is right. Address this later via parameter sets.
    if (!$GroupID -and !$GroupObj){
        Write-Host -ForegroundColor Yellow "You have to specify -GroupID or -GroupObj."
        return
    } 
    if ($GroupID -and $GroupObj){
        Write-Host -ForegroundColor Yellow "You cannot combine -GroupID and -GroupOBJ."
        return
    }
    if ($HostID -and $HostObj){
        Write-Host -ForegroundColor Yellow "You cannot combine -HostID and -HostObj."
        return
    }
    if (!$HostID -and !$HostObj){
        Write-Host -ForegroundColor Yellow "You have to specify -HostID or -HostObj "
        return
    }
    # Create an array of objects from a simple array. Each object has only one property $PropertyName (you choose the name).
    # For example from the following array "1234","4321" it creates two objects "hostid" = "1234" and "hostid" = "4321"
    # and puts it into an array, then you can add it to the PS object and convert it to json object for the API request.
    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{$PropertyName = "$item"}
        }
        $Result
        return
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
    $PSObj  = [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "hostgroup.massadd"; 
        "params" = [PSCustomObject]@{
        }; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }
    #Add properties to the basic PS object based on the used parameters
    if($GroupID){
        $GroupIDObjects = ConvertArrayToObjects -PropertyName "groupid" -Array $GroupID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groups" -Value @($GroupIDObjects)
    }
    if($GroupObj){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groups" -Value $GroupObj
    }
    if($HostID){
        $HostIDObjects = ConvertArrayToObjects -PropertyName "hostid" -Array $HostID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hosts" -Value @($HostIDObjects)
    }
    if($HostObj){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hosts" -Value $HostObj
    }

    $Json = $PSObj | ConvertTo-Json -Depth 5 

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    #Save JSON Request if -SaveJsonRequest is not $false. Default is $true.
    If ($SaveJsonRequest){
        $Json | Out-File -FilePath "$SaveLocation\Add-ZXHostGroup_JSON_Request_$DateTime.json"
        Write-Host -ForegroundColor Yellow "Request saved to:"
        Write-Host "$SaveLocation\Add-ZXHostGroup_JSON_Request_$DateTime.json"
    }

    #Make the API call
    if (!$WhatIf){
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
    #Save JSON Request if -SaveJsonResponse is not $false. Default is $true.
    If ($SaveJsonResponse){
        if($null -ne $Request.error){
            $request.error | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Add-ZXHostGroup_JSON_Response_$DateTime.json"
        }
        else{
            $request.result | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Add-ZXHostGroup_JSON_Response_$DateTime.json"
        }
        Write-Host -ForegroundColor Yellow "Response saved to:"
        Write-Host "$SaveLocation\Add-ZXHostGroup_JSON_Response-$DateTime.json"
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

function Add-ZXHostNameSuffix{
    param(
        [string]$HostName,
        [string]$HostId,
        [string]$Suffix,
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
        Write-Host "If you want the alias to be equal to the name, use -SameAlias switch and set it to the same value as name"
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
    #Check if the host contains a dot. If so skip the host.
    if($ZXHost.host -like "*.*" -and -not $Force){
        Write-Host -ForegroundColor Yellow "[$($ZXHost.host)] > Skipped."
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



<# 
class ZXTagList {
    [System.Collections.ArrayList]$Tags

    ZXTagList() {
        $this.Tags = [System.Collections.ArrayList]::new()
    }

    [void] AddTag([string]$name, [string]$value) {
        $newObject = [PSCustomObject]@{ Name = $name; Value = $value }
        $this.Tags.Add($newObject) | Out-Null
    }

    [void] Display() {
        $this.Tags
    }
}
#>

class ZXTagList {
    [System.Collections.ArrayList]$Tags

    ZXTagList() {
        $this.Tags = [System.Collections.ArrayList]::new()
    }

    [ZXTagList]AddTag([string]$name, [string]$value) {
        $newObject = [PSCustomObject]@{ name = $name; value = $value }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }

    [void] Display() {
        $this.Tags
    }
}

function Get-ZXAction {
    param(
        [array]$ActionID,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [array]$Output
    )

    #Validate Parameters

    if (!$Output){
        $Output = [string]$Output = "extend"
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Functions
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
        "method" = "action.get";
        "params" = [PSCustomObject]@{};
        "id" = 1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    if ($ActionID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "actionids" -Value @($ActionID)
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output


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
    else {
        ShowJsonRequest
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
    
    #Add human readable creation time to the object
    #$Request.result | Add-Member -MemberType ScriptProperty -Name CreationTime -Value {ConvertFrom-UnixEpochTime($this.clock)}
    
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



function Get-ZXAlert {
    param(
        [array]$EventID,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

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
        "method" = "alert.get";
        "params" = [PSCustomObject]@{
            "output"= "extend"
        };
        "id" = 1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    if ($EventID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "eventids" -Value @($EventID)
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
    
    #Add human readable creation time to the object
    $Request.result | Add-Member -MemberType ScriptProperty -Name CreationTime -Value {ConvertFrom-UnixEpochTime($this.clock)}
    
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



function Get-ZXApiVersion {

    param (
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "apiinfo.version";
        "params" = @();
        "id"  = "1"
    }

   
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        if($PSObjShow.params.sessionid){
            $PSObjShow.params.sessionid = "*****"
        }
        elseif($PSObjShow.params.token){
            $PSObjShow.params.token = "*****"
        }
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    $JSON = $PSObj | ConvertTo-Json -Depth 5

    #Make the API call
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }
    
    If ($ShowJsonResponse){
        #Create a deep copy of the $Request Object. This is necessary because otherwise changing the $PSObjShow is referencing the same object in memory as $Request
        $PSObjShow = $Request.result | ConvertTo-Json -Depth 5 | ConvertFrom-Json 
        if($PSObjShow.sessionid) {
            $PSObjShow.sessionid = "*****"
        }
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($PSObjShow | ConvertTo-Json -Depth 5)
    }

    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    elseif($Request.result){
        $request.result
    }    
}

function Get-ZXAuditLog {
    param(
        [array]$ResourceID,
        [string]$ResourceIDSearch,
        [array]$ResourceType,
        [string]$ResourceTypeSearch,
        [array]$ResourceName,
        [string]$ResourceNameSearch,
        [string]$Limit,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #Function to add a FILTER parameter to the PS object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
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
        "method" = "auditlog.get";
        "params" = [PSCustomObject]@{
            "output" = "extend"
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    if($Limit){$PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit}
    if($ResourceID){AddFilter -PropertyName "resourceid" -PropertyValue $ResourceID}
    if($ResourceIDSearch){AddSearch -PropertyName "resourceid" -PropertyValue $ResourceIDSearch}
    if($ResourceNameSearch){AddSearch -PropertyName "resourcename" -PropertyValue $ResourceNameSearch}

    #Convert the PSObjec to Json
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

    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        $Request.result
        return
    }
    
}

function Get-ZXDiscoveryRule {
    param(
        [array]$ItemID,
        [array]$GroupID,
        [array]$HostID,
        [array]$TemplateID,
        [string]$Limit,
        [string]$State,
        [string]$Status,
        [string]$Flag,
        [array]$Key,
        [string]$KeySearch,
        [string]$Type,
        [string]$TypeSearch,
        [array]$Name,
        [array]$TemplateIDs,
        [string]$TemplateIDFilter,
        [string]$TemplateIDSearch,
        [array]$Tag,
        [array]$Output,
        [switch]$CountOutput,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$IncludeItems,
        [switch]$IncludeTriggers,
        [switch]$WildCardsEnabled,
        [array]$ItemProperties,
        [array]$TriggerProperties,
        [array]$HostProperties,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "discoveryrule.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    #Function to add a filter to the object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

        function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Validate Parameters

    if (!$Output){
        $Output = @("name","lastvalue")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeHosts){
        If (!$HostProperties){
            $HostProperties = @("name")
        }
        elseif($HostProperties -contains "extend"){
            [string]$HostProperties = "extend"
        }    
    }
    if ($IncludeItems){
        If (!$ItemProperties){
            $ItemProperties = @("name")
        }
        elseif($ItemProperties -contains "extend"){
            [string]$ItemProperties = "extend"
        }    
    }
    if ($IncludeTriggers){
        If (!$TriggerProperties){
            $TriggerProperties = @("description")
        }
        elseif($TriggerProperties -contains "extend"){
            [string]$TriggerProperties = "extend"
        }    
    }
    
    

    #Get the item for the hosts with the specified IDs
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    #Get the items with the specified IDs
    if ($ItemID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "itemids" -Value $ItemID
    }
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value $HostProperties
    }
    if ($IncludeItems) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItems" -Value $ItemProperties
    }
    if ($IncludeTriggers) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTriggers" -Value $TriggerProperties
    }
    if ($GroupID) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value @($GroupIDs)
    }
    if ($TemplateIDs) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templateids" -Value @($TemplateIDs)
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    

    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }

    if ($Name){AddFilter -PropertyName "name" -PropertyValue $Name}
    if ($Id){AddFilter -PropertyName "itemid" -PropertyValue $Id}
    if ($Key){AddFilter -PropertyName "key_" -PropertyValue $Key}
    if ($State){AddFilter -PropertyName "state" -PropertyValue $State}
    if ($Status){AddFilter -PropertyName "status" -PropertyValue $Status}
    # Looks like templateid is actually a parent item id
    if ($TemplateIDFilter){AddFilter -PropertyName templateid -PropertyValue $TemplateIDFilter}
    if ($TemplateIDSearch){AddSearch -PropertyName templateid -PropertyValue $TemplateIDSearch}
    if ($KeySearch){AddSearch -PropertyName "key_" -PropertyValue $KeySearch}
    if ($NameSearch){AddSearch -PropertyName "name" -PropertyValue $NameSearch}

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    if($ExcludeSearch){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "excludeSearch" -Value "true"
    }
    if($WildCardsEnabled){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "searchWildcardsEnabled" -Value "true"
    }
    

    
    $Json =  $PSObj | ConvertTo-Json -Depth 5

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
        $StartTime = Get-Date
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        $Duration = (Get-Date) - $StartTime

    }
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
   
    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    } 
    else {
        $Request.result
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    }

}

function Get-ZXEvent {
    param(
        [array]$HostID,
        [array]$EventID,
        [switch]$IncludeTags,
        [array]$Output,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )
    #Validate Parameters
    if (!$Output){
        $Output = @("eventid","name")
        
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
        "method" = "event.get";
        "params" = [PSCustomObject]@{};
        "id" = 1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1

    }

    if ($Output){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    }
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostIDs
    }
    if ($EventID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "eventids" -Value $EventID
    }
    if ($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value @("tag","value")
    }


    $Json =  $PSObj | ConvertTo-Json -Depth 5

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
    
    #Add human readable creation time to the object
    #$Request.result | Add-Member -MemberType ScriptProperty -Name CreationTime -Value {ConvertFrom-UnixEpochTime($this.clock)}
    
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



function Get-ZXHistory {
    param(
        [parameter(mandatory="false")]
        [array]$ItemID,
        [int]$Limit,
        [string]$SortField="clock",
        [string]$SortOrder="DESC",
        [parameter(mandatory="true")]
        [int]$History,
        [int]$TimeFrom,
        [int]$TimeTill,
        [string]$Output="extend",
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

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
        "method" = "history.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    #Get the history of the following Items
    if ($ItemID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "itemids" -Value $ItemID
    }

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }

    if ($SortField){$PSObj.params | Add-Member -MemberType NoteProperty -Name "sortfield" -Value $SortField}
    if ($SortOrder){$PSObj.params | Add-Member -MemberType NoteProperty -Name "sortorder" -Value $SortOrder}
    if ($History){$PSObj.params | Add-Member -MemberType NoteProperty -Name "history" -Value $History}
    if ($TimeTill){$PSObj.params | Add-Member -MemberType NoteProperty -Name "time_till" -Value $TimeTill}
    if ($TimeFrom){$PSObj.params | Add-Member -MemberType NoteProperty -Name "time_from" -Value $TimeFrom}
    if ($Output){$PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output}
    
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

function Get-ZXHost {
    [CmdletBinding(PositionalBinding=$false)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [alias("Host","HostName")]
        [array]$Name,
        [alias("HostSearch","HostNameSearch")]
        [string]$NameSearch,
        [alias("VisibleName")]
        [string]$Alias,
        [alias("VisibleNameSearch")]
        [string]$AliasSearch,
        [string]$IPSearch,
        [string]$IP,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [array]$HostID,
        [ValidateSet("0","1","Enabled","Disabled")]
        [string]$Status,
        [ValidateSet("0","1","True","False")]
        [string]$InMaintenance,
        [switch]$ShowJsonRequest,
        [switch]$ShowResponseTime,
        [switch]$ShowJsonResponse,
        [switch]$IncludeDiscoveries,
        [switch]$IncludeDiscoveryRule,
        [switch]$IncludeGraphs,
        [switch]$IncludeHostGroups,
        [switch]$IncludeHostDiscovery,
        [switch]$IncludeHttpTests,
        [switch]$IncludeInterfaces,
        [switch]$IncludeInventory,
        [switch]$IncludeItems,
        [switch]$IncludeMacros,
        [switch]$IncludeParentTemplates,
        [switch]$IncludeDashboards,
        [switch]$IncludeTags,
        [switch]$WithItems,
        [switch]$IncludeInheritedTags,
        [switch]$IncludeTriggers,
        [switch]$IncludeValueMaps,
        [array]$TemplateIDs,
        [array]$ItemIDs,
        [array]$Tag,
        [array]$TriggeIDs,
        [array]$GroupIDs,
        [switch]$inheritedTags,
        [switch]$CountOutput,
        [array]$Output,
        [int]$Limit,
        [switch]$WhatIf,
        [array]$ItemProperties,
        [array]$InventoryProperties,
        [array]$InterfaceProperties,
        [array]$TriggerProperties

    )

    #Validate Parameters
    if ($IncludeItems){
        If (!$ItemProperties){
            $ItemProperties = @("name","itemid","type","lastvalue","delay","master_itemid")
        }
        elseif($ItemProperties -contains "extend"){
            [string]$ItemProperties = "extend"
        }    
    }
    if ($IncludeInterfaces){
        If (!$InterfaceProperties){
            $InterfaceProperties = @("ip","port")
        }
        elseif($InterfaceProperties -contains "extend"){
            [string]$InterfaceProperties = "extend"
        }    
    }
        if ($IncludeInventory){
        If (!$InventoryProperties){
            $InventoryProperties = "extend"
        }
        elseif($InterfaceProperties -contains "extend"){
            [string]$InterfaceProperties = "extend"
        }    
    }
    if ($IncludeTriggers){
        If (!$TriggerProperties){
            $TriggerProperties = @("name","value")
        }
        elseif($TriggerProperties -contains "extend"){
            [string]$TriggerProperties = "extend"
        }    
    }

    if (!$Output){
        $Output = @("hostid","host","name","status","proxy_hostid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Use Get-ZXHostInterface to search for the IP interfaces and get their host Id(s)
    if($IPsearch -and !$ShowJsonRequest -and !$WhatIf){
        $HostID =  Get-ZXHostInterface -IPSearch $IPSearch | Select-Object -ExpandProperty hostid
        #If the HostidID is null the host.get will return all the hosts in zabbix.
        if ($null -eq $HostID){
            $HostID = "..n/a.."
        }   
    }
    elseif($IPsearch -and $ShowJsonRequest -and !($WhatIf)){
        $HostID =  Get-ZXHostInterface -IPSearch $IPSearch -ShowJsonRequest | Select-Object -ExpandProperty hostid
        #If the HostidID is null the host.get will return all the hosts in zabbix.
        if ($null -eq $HostID){
            $HostID = "..n/a.."
        }   
    }
    elseif($IPSearch -and $WhatIf){
        Get-ZXHostInterface -IPSearch $IPSearch -WhatIf
        $HostID = "..n/a.."
    }

    #Use Get-ZXHostInterface to get IP interfaces that EXACTLY match the ip value of the argument, and get their host Id(s)
    if($IP -and !$ShowJsonRequest -and !$WhatIf){
        $HostID =  Get-ZXHostInterface -IP $IP | Select-Object -ExpandProperty hostid
        #If the HostidID is null the host.get will return all the hosts in zabbix.
        if ($null -eq $HostID){
            $HostID = "..n/a.."
        }       
    }
    elseif($IP -and $ShowJsonRequest -and !($WhatIf)){
        $HostID =  Get-ZXHostInterface -IP $IP -ShowJsonRequest | Select-Object -ExpandProperty hostid
        #If the HostidID is null the host.get will return all the hosts in zabbix.
        if ($null -eq $HostID){
            $HostID = "..n/a.."
        }          
        
    }
    elseif($IP -and $WhatIf){
        Get-ZXHostInterface -IP $IP -WhatIf
        $HostID = "HostID(s)FromTheFirstAPICall"
    }

 
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "host.get"; 
        "params" = [PSCustomObject]@{
        }; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }

    #Function to add a filter parameter to the PS object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if search is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Add additional host parameters to the ps object based on the function parameters

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    
    #Return a host based on host name FILTER. Instead of Hostname, you have to put host in the json which equals to hostname in zabbix.
    if($Name){
        AddFilter -PropertyName "host" -PropertyValue $Name
    }
    if($Alias){
        AddFilter -PropertyName "name" -PropertyValue $Alias
    }
    if($AliasSearch){
        AddSearch -PropertyName "name" -PropertyValue $AliasSearch
    }

    #Return a host based on host name SEARCH. Instead of Hostname, you have to put host in the json which equals to hostname in zabbix.
    if($NameSearch){AddSearch -PropertyName "host" -PropertyValue $NameSearch}
    
    #Return the host based on hostid
    if($HostID){AddFilter -PropertyName "hostid" -PropertyValue $HostID}

    #Get only hosts with the given status 0 = enabled 1 = disabled
    if($Status){
        switch ($Status) {
            "Enabled" {$Status = "0"}
            "Disabled" {$Status = "1"}
        }
        AddFilter -PropertyName "status" -PropertyValue $Status
    }

    #Get only hosts which are in maintenance or only hosts which are not in maintenance
    #Boolean is converted to number.
    if($InMaintenance){
        switch ($InMaintenance) {
            "False" {$InMaintenance = "0"}
            "True" {$InMaintenance = "1"}
        }
        AddFilter -PropertyName "maintenance_status" -PropertyValue $InMaintenance
    }

    if ($IncludeParentTemplates) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectParentTemplates" -Value @("templateid","name")
    }
    if ($IncludeHostGroups) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectGroups" -Value @("groupid","name")
    }
    if ($IncludeInventory) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectInventory" -Value $InventoryProperties
    }
    if ($IncludeTags) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value @("tag","value")
    }
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }
    if ($IncludeInheritedTags) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectInheritedTags" -Value @("tag","value")
    }
    if ($IncludeInterfaces) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectInterfaces" -Value $InterfaceProperties
    }
    if ($IncludeMacros) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectMacros" -Value "extend"
    }
    if ($IncludeItems) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItems" -Value $ItemProperties
    }
    if ($IncludeTriggers) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTriggers" -Value $TriggerProperties
    }
    # Return only hosts that are linked to the given templates.
    if ($TemplateIDs) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templateids" -Value @($TemplateIDs)
    }
    if ($GroupIDs) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value @($GroupIDs)
    }

    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    if($WithItems){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "with_items" -Value "true"
    }
    #Limit the number of returned hosts
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    


    #Convert the ps object to json. It is crucial to use a correct value for the -Depth
    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Record API call start time
    $APICallStartTime = Get-Date

    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Record API call end
    $APICallEndTime = Get-Date

    #Calculste API call response time
    $APICallResponseTime = $APICallEndTime - $APICallStartTime
    

    #Show JSON Request if -ShowJsonResponse switch is used
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
    
    #Show API call respoinse time if -ShowResponseTime switch is used
    If ($ShowResponseTime){
        Write-Host -ForegroundColor Yellow "Response time: " -NoNewline
        Write-Host -ForegroundColor Cyan "$($APICallResponseTime.TotalSeconds) seconds"
    }
    #This will be returned by the function

        if($null -ne $Request.error){
            $Request.error
            return
        }
        elseif($CountOutput){
            $Request.result
            return
        }   
        else {
            $Request.result
            return
        }
        
    }

function Get-ZXHostGroup {
    param(
        [array]$Name,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [array]$Output,
        [array]$GroupID,
        [switch]$WithHosts,
        [switch]$WithMonitoredItems,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #Function to add a FILTER parameter to the PS object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    if (!$Output){
        $Output = @("name","groupid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }
    

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "hostgroup.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
    }
    if ($WithHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "with_hosts" -Value $true
    }
    if ($WithMonitoredItems){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "with_monitored_items" -Value $true
    }
    if($Name){AddFilter -PropertyName "name" -PropertyValue $Name}
    if($NameSearch){AddSearch -PropertyName "name" -PropertyValue $NameSearch}
    if($GroupID){AddFilter -PropertyName "groupid" -PropertyValue $GroupID}
    if($Output) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    }


    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    $JSON = $PSObj | ConvertTo-Json -Depth 5
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
  
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        $Request.result
        return
    }
}

function Get-ZXHostInterface {
    param(
        [array]$IP,
        [string]$IPSearch,
        [array]$InterfaceID,
        [array]$HostID,
        [array]$ItemProperties,
        [switch]$IncludeItems,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf

    )

    if ($IncludeItems){
        If (!$ItemProperties){
            $ItemProperties = @("name","itemid","type","lastvalue","delay","master_itemid")
        }
        elseif($ItemProperties -contains "extend"){
            [string]$ItemProperties = "extend"
        }    
    }
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "hostinterface.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }
    
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    if($IP){AddFilter -PropertyName "ip" -PropertyValue $IP}
    if($IPSearch){AddSearch -PropertyName "ip" -PropertyValue $IPSearch}
    if($InterfaceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "interfaceids" -Value $InterfaceID
    }
    if($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    if ($IncludeItems) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItems" -Value $ItemProperties
    }

    #$PSObj.params.output = "extend"
    $Json =  $PSObj | ConvertTo-Json -Depth 3

    #Show JSON Request based on the -ShowJsonRequest switch.
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

function Get-ZXItem {
    param(
        [array]$HostID,
        [string]$Limit,
        [string]$State,
        [string]$Status,
        [string]$Flag,
        [array]$Key,
        [string]$KeySearch,
        [string]$Type,
        [string]$TypeSearch,
        [array]$Name,
        [array]$Id,
        [array]$ItemID,
        [array]$GroupID,
        [array]$TemplateIDs,
        [string]$TemplateIDFilter,
        [string]$TemplateIDSearch,
        [array]$Tag,
        [array]$Output,
        [switch]$CountOutput,
        [array]$SortField,
        [ValidateSet("ASC","DESC")]
        [string]$SortOrder,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$IncludeTags,
        [switch]$IncludeDiscoveryRule,
        [switch]$WildCardsEnabled,
        [array]$DiscoveryRuleProperties,
        [switch]$IncludeItemDiscovery,
        [array]$ItemDiscoveryProperties,
        [array]$HostProperties,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "item.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    #Function to add a filter to the object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

        function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Validate Parameters

    if (!$Output){
        $Output = @("name","lastvalue")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeHosts){
        If (!$HostProperties){
            $HostProperties = @("name")
        }
        elseif($HostProperties -contains "extend"){
            [string]$HostProperties = "extend"
        }    
    }
    if ($IncludeDiscoveryRule){
        If (!$DiscoveryRuleProperties){
            $DiscoveryRuleProperties = @("name")
        }
        elseif($DiscoveryRuleProperties -contains "extend"){
            [string]$DiscoveryRuleProperties = "extend"
        }    
    }
    if ($IncludeItemDiscovery){
        If (!$ItemDiscoveryProperties){
            $ItemDiscoveryProperties = @("parent_itemid")
        }
        elseif($ItemDiscoveryProperties -contains "extend"){
            [string]$ItemDiscoveryProperties = "extend"
        }    
    }
    
    

    #Get the item for the hosts with the specified IDs
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    #Get the items with the specified IDs
    if ($ItemID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "itemids" -Value $ItemID
    }
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value $HostProperties
    }
    # Add "selecTags" parameter to return all hosts linked tho the templates.
    if ($IncludeTags) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value "extend"
    }
    if ($IncludeDiscoveryRule) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectDiscoveryRule" -Value $DiscoveryRuleProperties
    }
    if ($IncludeItemDiscovery) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItemDiscovery" -Value $ItemDiscoveryProperties
    }
    if ($GroupID) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value @($GroupID)
    }
    if ($TemplateIDs) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templateids" -Value @($TemplateIDs)
    }
    if ($SortField) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sortfield" -Value @($SortField)
    }
    if ($SortOrder) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sortorder" -Value $SortOrder
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    

    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }

    if ($Name){AddFilter -PropertyName "name" -PropertyValue $Name}
    if ($Id){AddFilter -PropertyName "itemid" -PropertyValue $Id}
    if ($Key){AddFilter -PropertyName "key_" -PropertyValue $Key}
    if ($State){AddFilter -PropertyName "state" -PropertyValue $State}
    if ($Type){AddFilter -PropertyName "type" -PropertyValue $Type}
    if ($Flag){AddFilter -PropertyName "flags" -PropertyValue $Flag}
    if ($Status){AddFilter -PropertyName "status" -PropertyValue $Status}
    # Looks like templateid is actually a parent item id
    if ($TemplateIDFilter){AddFilter -PropertyName templateid -PropertyValue $TemplateIDFilter}
    if ($TemplateIDSearch){AddSearch -PropertyName templateid -PropertyValue $TemplateIDSearch}
    if ($KeySearch){AddSearch -PropertyName "key_" -PropertyValue $KeySearch}
    if ($NameSearch){AddSearch -PropertyName "name" -PropertyValue $NameSearch}

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    if($ExcludeSearch){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "excludeSearch" -Value "true"
    }
    if($WildCardsEnabled){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "searchWildcardsEnabled" -Value "true"
    }
    

    
    $Json =  $PSObj | ConvertTo-Json -Depth 5

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
        $StartTime = Get-Date
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        $Duration = (Get-Date) - $StartTime

    }
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
   
    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    } 
    else {
        $Request.result
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    }

}

function Get-ZXItemPrototype {
    param(
        [array]$HostID,
        [array]$ItemID,
        [int]$Limit,
        [int]$Status,
        [array]$Key,
        [array]$DiscoveryIDs,
        [string]$KeySearch,
        [string]$Type,
        [string]$TypeSearch,
        [array]$Name,
        [string]$TemplateID,
        [switch]$TemplateD,
        [array]$Tag,
        [array]$Output,
        [switch]$CountOutput,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$IncludeDiscoveryRule,
        [array]$DiscoveryRuleProperties,
        [array]$HostProperties,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "itemprototype.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    #Function to add a filter to the object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

        function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Validate Parameters

    if (!$Output){
        $Output = @("name","lastvalue")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeHosts){
        If (!$HostProperties){
            $HostProperties = @("name")
        }
        elseif($HostProperties -contains "extend"){
            [string]$HostProperties = "extend"
        }    
    }
    if ($IncludeDiscoveryRule){
        If (!$DiscoveryRuleProperties){
            $DiscoveryRuleProperties = @("name")
        }
        elseif($DiscoveryRuleProperties -contains "extend"){
            [string]$DiscoveryRuleProperties = "extend"
        }    
    }
    if ($IncludeItemDiscovery){
        If (!$ItemDiscoveryProperties){
            $ItemDiscoveryProperties = @("parent_itemid")
        }
        elseif($ItemDiscoveryProperties -contains "extend"){
            [string]$ItemDiscoveryProperties = "extend"
        }    
    }
    
    

    #Get the item for the hosts with the specified IDs
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    #Get the items with the specified IDs
    if ($ItemID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "itemids" -Value $ItemID
    }
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value $HostProperties
    }
    if ($IncludeDiscoveryRule) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectDiscoveryRule" -Value $DiscoveryRuleProperties
    }
    if ($IncludeItemDiscovery) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItemDiscovery" -Value $ItemDiscoveryProperties
    }
    if ($GroupID) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value @($GroupIDs)
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    

    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }

    if ($Name){AddFilter -PropertyName "name" -PropertyValue $Name}
    if ($Id){AddFilter -PropertyName "itemid" -PropertyValue $Id}
    if ($Key){AddFilter -PropertyName "key_" -PropertyValue $Key}
    if ($State){AddFilter -PropertyName "state" -PropertyValue $State}
    if ($KeySearch){AddSearch -PropertyName "key_" -PropertyValue $KeySearch}
    if ($NameSearch){AddSearch -PropertyName "name" -PropertyValue $NameSearch}
    # Looks like templateid is actually a parent item id
    if ($TemplateID){AddFilter -PropertyName templateid -PropertyValue $TemplateID}

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    #Return only prototypes that belong to templates
    if($TemplateD){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templated" -Value "true"
    }
    if($ExcludeSearch){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "excludesearch" -Value "true"
    }
    

    
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
        $StartTime = Get-Date
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        $Duration = (Get-Date) - $StartTime

    }
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
   
    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    } 
    else {
        $Request.result
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    }

}

function Get-ZXMaintenance {
    param(
        [array]$GroupID,
        [array]$HostID,
        [array]$MaintenanceID,
        [string]$Name,
        [string]$NameSearch,
        [array]$Output,
        [switch]$IncludeHostGroups,
        [switch]$IncludeHosts,
        [switch]$IncludeTags,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$IncludeTimePeriods,
        [array]$TimePeriodProperties,
        [int]$Limit,
        [switch]$WhatIf
    )

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Validate Parameters

    if (!$Output){
        [string]$Output = "extend"
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeTimePeriods){
        If (!$TimePeriodProperties){
            [string]$TimePeriodProperties = "extend"
        }
        elseif($TimePeriodProperties -contains "extend"){
            [string]$TimePeriodProperties = "extend"
        }    
    }

    #Functions

    #Function to add a filter parameter to the PS object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if search is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }
    

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "maintenance.get";
        "params" = [PSCustomObject]@{};
        "id" = 1;
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    #Return a maintenance based on host name FILTER
    if($Name){
        AddFilter -PropertyName "name" -PropertyValue $Name
    }

    #Return a maintenance  based on host name SEARCH. 
    if($NameSearch){
        AddSearch -PropertyName "name" -PropertyValue $NameSearch
    }
    
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if ($MaintenanceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "maintenanceids" -Value $MaintenanceID
    }
    if ($IncludeTimePeriods){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTimeperiods" -Value $TimePeriodProperties
    }
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("hostid","host")
    }
    if ($IncludeHostGroups){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHostGroups" -Value @("groupid","name")
    }
    if ($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value @("tag","value")
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    


    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

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
    if($WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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

function Get-ZXProblem {
    param(
        [array]$HostID,
        [array]$EventID,
        [int]$Source,
        [switch]$IncludeTags,
        [switch]$Recent,
        [switch]$CountOutput,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [int]$Limit,
        [array]$Output,
        [switch]$WhatIf
    )

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
        "auth" = $ZXAPIToken | ConvertFrom-SecureString -AsPlainText; 
    }

    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
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

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
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

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
    
    #Add human readable creation time to the object
    $Request.result | Add-Member -MemberType ScriptProperty -Name CreationTime -Value {ConvertFrom-UnixEpochTime($this.clock)}
    
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

function Get-ZXProxy {
    param(
        [array]$Name,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    function ConvertFrom-UnixEpochTime ($UnixEpochTime){
        $customDate = (Get-Date -Date "01-01-1970") + ([System.TimeSpan]::FromSeconds($UnixEpochTime))
        $customDate
    }
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "proxy.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }
    
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }
    
    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
    }
    
    if($Name){AddFilter -PropertyName "host" -PropertyValue $Name}
    if($NameSearch){AddSearch -PropertyName "host" -PropertyValue $NameSearch}


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

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }

    #Add API call time stamp to the result
    $Request.result | Add-Member -MemberType NoteProperty -Name APICallTimeUTC -Value $(Get-Date -AsUTC)

    #Add Human Readable Last Access time
    $Request.result | Add-Member -MemberType ScriptProperty -Name LastAccessReadableUTC -Value {
        ConvertFrom-UnixEpochTime($this.lastaccess)
    }
    #Add the last seen parameter. This is freshly recalculated even if you save the result to variable and then just call the variable
    $Request.result | Add-Member -MemberType ScriptProperty -Name "LastSeen" -Value {
        (Get-Date $this.APICallTimeUTC) - (get-date $this.LastAccessReadableUTC) | Select-Object -ExpandProperty totalseconds
    
    }

    if($IncludeHosts){
        $Request.result | Add-Member -MemberType ScriptProperty -Name "HostCount" -Value {
        ($this.Hosts).count
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

function Get-ZXService {
    param(
        [string]$Name,
        [string]$NameSearch,
        [array]$ServiceID,
        [array]$ParentID,
        [switch]$DeepParentID,
        [array]$ChildID,
        [string]$EvalType,
        [array]$Tag,
        [array]$ProblemTag,
        [switch]$WithoutProblemTags,
        [array]$SLAID,
        [switch]$IncludeChildren,
        [switch]$IncludeParents,
        [switch]$IncludeTags,
        [switch]$IncludeProblemEvents,
        [switch]$IncludeProblemTags,
        [switch]$IncludeStatusRules,
        [switch]$IncludeStatusTimeline,
        [array]$ChildrenProperties,
        [array]$ParentProperties,
        [array]$ProblemEventProperties,
        [array]$StatusRuleProperties,
        [array]$StatusTimelineProperties,
        [switch]$ExcludeSearch,
        [array]$Status,
        [switch]$Editable,
        [switch]$ShowJsonRequest,
        [switch]$WhatIf,
        [array]$Output
    )
    #Validate parameters

    if (!$Output){
        $Output = @("name","description","status")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeChildren){
        If (!$ChildrenProperties){
            $ChildrenProperties = @("name")
        }
        elseif($ChildrenProperties -contains "extend"){
            [string]$ChildrenProperties = "extend"
        }    
    }
    if ($IncludeParents){
        If (!$ParentProperties){
            $ParentProperties = @("name","status")
        }
        elseif($ParentProperties -contains "extend"){
            Write-Host -ForegroundColor Yellow "Extend will not work for here"
        }    
    }
    if ($IncludeProblemEvents){
        If (!$ProblemEventProperties){
            $ProblemEventProperties = @("name","severity","eventid")
        }
        elseif($ProblemEventProperties -contains "extend"){
            Write-Host -ForegroundColor Yellow "Extend will not work for here"
        }    
    }
    if ($IncludeStatusRules){
        If (!$StatusRuleProperties){
            $StatusRuleProperties = @("extend")
        }
        elseif($StatusRuleProperties -contains "extend"){
            [string]$StatusRuleProperties = "extend"
        }    
    }
    if ($IncludeStatusTimeline){
        If (!$StatusTimelineProperties){
            $StatusTimelineProperties = @("extend")
        }
        elseif($StatusTimelineProperties -contains "extend"){
            [string]$StatusTimelineProperties = "extend"
        }    
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "service.get";
        "params" = [PSCustomObject]@{
        }; 
        #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
        "id" = 1;
    }

     #Function to add a filter parameter to the PS object
     function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if search is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Output content
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }
    if($ServiceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "serviceids" -Value $ServiceID
    }

    # Example of the argument for $ProblemTag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $ProblemTag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($ProblemTag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "problemTags" -Value $ProblemTag
    }
      
    if($Name){
        AddFilter -PropertyName name -PropertyValue $Name
    }
    if($Status){
        AddFilter -PropertyName status -PropertyValue @($Status)
    }
    if($NameSearch){
        AddSearch -PropertyName name -PropertyValue $NameSearch
    }
    if($ExcludeSearch){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "excludeSearch" -Value "true"
    }
    if($Editable){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "editable" -Value $True
    }
    if($IncludeChildren){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectChildren" -Value $ChildrenProperties
    }
    if($IncludeParents){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectParents" -Value $ParentProperties
    }
    if($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value "extend"
    }
    if($IncludeProblemTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectProblemTags" -Value "extend"
    }
    if($IncludeProblemEvents){
        $PSObj.params| Add-Member -MemberType NoteProperty -Name "selectProblemEvents" -Value @($ProblemEventProperties)
    }
    if($IncludeStatusRules){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectStatusRules" -Value $StatusRuleProperties
    }
    if($IncludeChildren){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectStatusTimeline" -Value $StatusTimelineProperties
    }
    if($DeepParentID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "deep_parentids" -Value $true
    }
    if($ParentID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "parentids" -Value $ParentID
    }



        #Convert the ps object to json. It is crucial to use a correct value for the -Depth
        $Json = $PSObj | ConvertTo-Json -Depth 6

            #Make the final API call
        if(!$WhatIf){
            $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        }


        #Show JSON Request if -ShowJsonRequest switch is used
        If ($ShowJsonRequest -or $WhatIf){
            Write-Host -ForegroundColor Yellow "JSON REQUEST"
            $PSObjShow = $PSObj | ConvertTo-Json -Depth 6 | ConvertFrom-Json -Depth 6
            $PSObjShow.auth = "*****"
            $JsonShow = $PSObjShow | ConvertTo-Json -Depth 6
            Write-Host -ForegroundColor Cyan $JsonShow
        }

        #This will be returned by the function

        if($null -ne $Request.error){
            $Request.error
            return
        }
        elseif($CountOutput){
            $Request.result
            return
        }   
        else {
            $Request.result
            return
        }

}

function GEt-ZXSession {
    param(
        [securestring]$SessionID,
        [string]$SessionIDPlainText,
        [securestring]$Token,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [switch]$ShowSessionID
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.checkAuthentication";
        "params" = [PSCustomObject]@{};
        "id"  = "1"
    }

    if ($SessionID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sessionid" -Value "$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))))"
    }
    elseif ($SessionIDPlainText) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sessionid" -Value $SessionIDPlainText
    }

    if ($Token){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "token" -Value "$([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))))"
    }
    
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        if($PSObjShow.params.sessionid){
            $PSObjShow.params.sessionid = "*****"
        }
        elseif($PSObjShow.params.token){
            $PSObjShow.params.token = "*****"
        }
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    $JSON = $PSObj | ConvertTo-Json -Depth 5

    #Make the API call
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }
    
    If ($ShowJsonResponse){
        #Create a deep copy of the $Request Object. This is necessary because otherwise changing the $PSObjShow is referencing the same object in memory as $Request
        $PSObjShow = $Request.result | ConvertTo-Json -Depth 5 | ConvertFrom-Json 
        if($PSObjShow.sessionid) {
            $PSObjShow.sessionid = "*****"
        }
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($PSObjShow | ConvertTo-Json -Depth 5)
    }

    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        if($Request.result){
            if($ShowSessionID){
                $Request.result
            }
            elseif($request.result.sessionid) {
                $request.result.sessionid = "*****"
                $request.result
            }
            else{
                $request.result
            }
        }
     }
}

function Get-ZXTemplate {
    param(
        [array]$Name,
        [string]$Limit,
        [array]$TemplateID,
        [array]$VisibleName,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [string]$VisibleNameSearch,
        [array]$HostProperties,
        [switch]$IncludeMacros,
        [switch]$IncludeTags,
        [array]$TagProperties,
        [switch]$IncludeParentTemplates,
        [switch]$IncludeDiscoveries,
        [switch]$IncludeItems,
        [switch]$IncludeTriggers,
        [array]$ItemProperties,
        [array]$DiscoveryProperties,
        [array]$Output,
        [switch]$WithItems,
        [switch]$CountOutput,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if search is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertFrom-Json | ConvertTo-Json
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Validate Parameters

    if (!$Output){
        $Output = @("host")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeDiscoveries){
        If (!$DiscoveryProperties){
            $DiscoveryProperties = @("name","key_","templateid","itemid")
        }
        elseif($DiscoveryProperties -contains "extend"){
            [string]$DiscoveryProperties = "extend"
        }    
    }
    if ($IncludeItems){
        If (!$ItemProperties){
            $ItemProperties = @("name","key_","templateid","itemid")
        }
        elseif($ItemProperties -contains "extend"){
            [string]$ItemProperties = "extend"
        }    
    }
    if ($IncludeTriggers){
        If (!$TriggerProperties){
            $TriggerProperties = @("description","priority","status")
        }
        elseif($TriggerProperties -contains "extend"){
            [string]$TriggerProperties = "extend"
        }    
    }
    if ($IncludeHosts){
        If (!$HostProperties){
            $HostProperties = @("name")
        }
        elseif($HostProperties -contains "extend"){
            [string]$HostProperties = "extend"
        }    
    }
    if ($IncludeTags){
        If (!$TagProperties){
            $TagProperties = @("tag","value")
        }
        elseif($TagProperties -contains "extend"){
            [string]$TagProperties = "extend"
        }    
    }
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "template.get";
        "params" = [PSCustomObject]@{};
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    #Template name in the zabbix api is host, not name, therefore property name is "host"...
    if ($NameSearch){
        AddSearch -PropertyName "host" -PropertyValue $NameSearch
    }

    if ($VisibleNameSearch){
        AddSearch -PropertyName "name" -PropertyValue $VisibleNameSearch
    }
    if ($Name){
        AddFilter -PropertyName "host" -PropertyValue $Name
    }
    if ($VisibleName){
        AddFilter -PropertyName "name" -PropertyValue $VisibleName
    }
    if ($TemplateID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templateids" -Value $TemplateID
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    #Return only templates with items
    if($WithItems){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "with_items" -Value "true"
    }

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value $HostProperties
    }
    #Add "selectMacros" paremeter to return all macros of the template
    if ($IncludeMacros) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectMacros" -Value "extend"
    }
    #Add "selectPatentTemplates" to return all templates that are are a child of this template, sounds counterintuitive
    if ($IncludeParentTemplates) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectParentTemplates" -Value "extend"
    }
    if ($IncludeDiscoveries) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectDiscoveries" -Value $DiscoveryProperties
    }
    if ($IncludeItems) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItems" -Value $ItemProperties
    }
    if ($IncludeTriggers) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTriggers" -Value $TriggerProperties
    }
    if ($IncludeTags) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value $TagProperties
    }
    #Output property
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output


    $Json =  $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json -Depth 5  | ConvertFrom-Json 
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Make the API call
    if (!$WhatIf){
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

function Get-ZXTrigger {
    param(
        [array]$HostID,
        [array]$TriggerId,
        [array]$HostGroupID,
        [array]$TemplateID,
        [array]$Output,
        [string]$Description,
        [switch]$IncludeHosts,
        [switch]$IncludeHostGroups,
        [switch]$IncludeItems,
        [switch]$IncludeTags,
        [switch]$IncludeFunctions,
        [switch]$IncludeDependencies,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "trigger.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }
    
    #Validate parameters
    if (!$Output){
        $Output = @("triggerid","description","expression","status","type","state")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Function to add a filter to the object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

        function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    

    #Get the item for the hosts with the specified IDs
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    if ($TriggerId){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "triggerids" -Value $TriggerId
    }

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
    }
    if ($IncludeTags){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value "extend"
    }

    if ($HostGroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $HostGroupID
    }
    if ($HostGroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templateids" -Value $TemplateID
    }
    if ($Description){
        AddFilter -PropertyName "description" -PropertyValue $Description
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    
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

function Get-ZXTriggerPrototype {
    param(
        [array]$HostID,
        [array]$TriggerID,
        [int]$Limit,
        [int]$Status,
        [array]$Key,
        [array]$DiscoveryIDs,
        [string]$KeySearch,
        [string]$Type,
        [string]$TypeSearch,
        [array]$Name,
        [string]$TemplateID,
        [switch]$TemplateD,
        [array]$Tag,
        [array]$Output,
        [switch]$CountOutput,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$IncludeTags,
        [switch]$IncludeDiscoveryRule,
        [array]$DiscoveryRuleProperties,
        [array]$HostProperties,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "triggerprototype.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

    #Function to add a filter to the object
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

        function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value @($PropertyValue)
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Validate Parameters

    if (!$Output){
        $Output = @("name","lastvalue")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    if ($IncludeHosts){
        If (!$HostProperties){
            $HostProperties = @("name")
        }
        elseif($HostProperties -contains "extend"){
            [string]$HostProperties = "extend"
        }    
    }
    if ($IncludeDiscoveryRule){
        If (!$DiscoveryRuleProperties){
            $DiscoveryRuleProperties = @("name")
        }
        elseif($DiscoveryRuleProperties -contains "extend"){
            [string]$DiscoveryRuleProperties = "extend"
        }    
    }
    if ($IncludeTriggerDiscovery){
        If (!$TriggerDiscoveryProperties){
            $TriggerDiscoveryProperties = @("parent_triggerid")
        }
        elseif($TriggerDiscoveryProperties -contains "extend"){
            [string]$TriggerDiscoveryProperties = "extend"
        }    
    }
    
    

    #Get the trigger for the hosts with the specified IDs
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    #Get the triggers with the specified IDs
    if ($TriggerID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "triggerids" -Value $TriggerID
    }
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value $HostProperties
    }
    if ($IncludeTags) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTags" -Value "extend"
    }
    if ($IncludeDiscoveryRule) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectDiscoveryRule" -Value $DiscoveryRuleProperties
    }
    if ($IncludeTriggerDiscovery) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTriggerDiscovery" -Value $TriggerDiscoveryProperties
    }
    if ($GroupID) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value @($GroupIDs)
    }
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }
    

    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "value" = ""; "operator" = "2"})
    # Example of the argument for $Tag parameter: @([pscustomobject]@{"tag" ="#disabled_reason"; "operator" = "5"})
    # Possible operator values:  0 - (default) Contains; 1 - Equals; 2 - Not like; 3 - Not equal; 4 - Exists; 5 - Not exists.
    if($Tag){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $Tag
    }

    if ($Name){AddFilter -PropertyName "name" -PropertyValue $Name}
    if ($Id){AddFilter -PropertyName "triggerid" -PropertyValue $Id}
    if ($Key){AddFilter -PropertyName "key_" -PropertyValue $Key}
    if ($State){AddFilter -PropertyName "state" -PropertyValue $State}
    if ($KeySearch){AddSearch -PropertyName "key_" -PropertyValue $KeySearch}
    if ($NameSearch){AddSearch -PropertyName "name" -PropertyValue $NameSearch}
    # Looks like templateid is actually a parent trigger id
    if ($TemplateID){AddFilter -PropertyName templateid -PropertyValue $TemplateID}

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }
    #Return only prototypes that belong to templates
    if($TemplateD){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "templated" -Value "true"
    }
    if($ExcludeSearch){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "excludesearch" -Value "true"
    }
    

    
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
        $StartTime = Get-Date
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        $Duration = (Get-Date) - $StartTime

    }
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }
   
    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    } 
    else {
        $Request.result
        Write-Host "The API response took $($Duration.TotalSeconds)"
        return
    }

}

function Invoke-ZXTask {
    param(
        [array]$ItemID,
        [string]$Type,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [array]$Output
    )

    #Validate Parameters


    #Functions

    <# Create an array of objects from a simple array. Each object has only one property $PropertyName (you choose the name).
    # For example from the following array "1234" it creates an object like" 
    {
      "request": {
        "itemid": 1234
      },
      "type": "6"
    }
    #> 
    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{"type"="6";
                "request"=[PSCustomObject]@{
                    "$PropertyName" = $item
                }
            }
        }
        $Result
        return
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
        "method" = "task.create";
        "id" = 1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }
    

    if($ItemID){
        $TaskObjects = ConvertArrayToObjects -PropertyName "itemid" -Array $ItemID
        $PSObj | Add-Member -MemberType NoteProperty -Name "params" -Value @($TaskObjects)
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output


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
    else {
        ShowJsonRequest
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
    
    #Add human readable creation time to the object
    #$Request.result | Add-Member -MemberType ScriptProperty -Name CreationTime -Value {ConvertFrom-UnixEpochTime($this.clock)}
    
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



function New-ZXLogonSession {
    param(
        [switch]$UserData,
        [switch]$Load,
        [string]$UserName,
        [string]$Url, 
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [switch]$ShowSessionID

    )
    
    #Read the user input
    if(!$RemoveAllSettings -and !$Load){
        if (!$Url){
            $Global:ZXAPIUrl = Read-Host -Prompt "Enter the zabbix API URL"
        }
        else {
            $Global:ZXAPIUrl = $Url
        }

        if (!$UserName){
            $UserName = Read-Host -Prompt "Enter the zabbix API User Name"
        }
        $Password = Read-Host -AsSecureString -Prompt "Enter your password"
    }

    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Login\LogonData.txt"
    if (!( Test-Path $SaveLocation)){
        New-Item -ItemType File $SaveLocation -Force
    }

    #New logon data object
    $NewLogonData = [pscustomobject]@{
        "Id" = ""
        "URL" = $Global:ZXAPIUrl
        "UserName" = $UserName
        "Password" = $Password | ConvertFrom-SecureString
        "SessionID" = ""
    }
    #Get the data from the LogonData.txt, filter out the entry with the same URL you have entered in case it exists.
    #This way you can enter the same url again and the password and name will be overwritten in the next steps
     
    function CheckForAHangingSession{
        $LogonDataList = @(Get-Content $SaveLocation | ConvertFrom-Json)
        $LoadedLogonData = $LogonDataList | Where-Object {$_.URL -eq $Global:ZXAPIUrl}
        # If there is an url and username match between currently entered data and data saved in user profile json file, check if session id is not empty
        # if it is not empty, it means the user did nod log off the session properly, try to use the same session id again.
        if ($LoadedLogonData.SessionID -ne "" -and $LoadedLogonData.SessionID -ne $null){
            $Global:ZXAPIToken = $LoadedLogonData.SessionID | ConvertTo-SecureString
            Write-Host -ForegroundColor Yellow "The last session was not terminated properly.Trying to use the old session..."
            $CheckAuthObj = [PSCustomObject]@{
                "jsonrpc" = "2.0";
                "method" = "user.checkAuthentication";
                "params" = [PSCustomObject]@{
                    "sessionid" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
                };
                "id" = "1"
            }
            $CheckAuthJSON = $CheckAuthObj | ConvertTo-Json -Depth 5

            $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $CheckAuthJSON -ContentType "application/json" -Method Post -SessionVariable global:websession

            if($null -ne $Request.error){
                $Request.error
                exit
            } 
            else {
                if($Request.result){
                    if($ShowSessionID){
                        $Request.result
                        exit
                    }
                    elseif($request.result.sessionid) {
                        $request.result.sessionid = "*****"
                        $request.result
                        exit
                    }
                    else{
                        $request.result
                        exit
                    }
                }
            }   
            #End the sript here even if it fails, you have to make sure the session was terminated
            Write-Host "Exiting the script!"
        }
    }

    CheckForAHangingSession

    #Check for a hanging session
    CheckForAHangingSession

    if($Load -and !$Url){
        $LogonDataList | ForEach-Object {
            Write-Host -NoNewline "[$($_.Id)]"; 
            Write-Host -NoNewline -ForegroundColor Yellow " $($_.URL)"; 
            Write-Host " - $($_.UserName)"
        }
        $Choice = Read-Host -Prompt "Select the number and press enter"

        $UserName = $LogonDataList[$Choice].UserName
        $Password = $LogonDataList[$Choice].Password | ConvertTo-SecureString
        $Global:ZXApiURL = $LogonDataList[$Choice].URL
        #Check for a hanging session first
        CheckForAHangingSession
    }

    if($Load -and $Url){
        $LogonDataList = (Get-Content $SaveLocation | ConvertFrom-Json) | Where-Object {$_.URL -eq $Url}
        $UserName = $LogonDataList.UserName
        $Password = $LogonData.Password | ConvertTo-SecureString
        $Global:ZXApiURL = $LogonData.URL
        #Check for a hanging session first
        CheckForAHangingSession
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObject = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.login";
        "params" = @{
            "username" = $UserName;
            "password" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Password)));
            "userData" = "$([bool]$UserData)"
        }
        "id" = "1"
    }

    $JSON = $PSObject | ConvertTo-Json
    
    if($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObject | ConvertTo-Json | ConvertFrom-Json
        $PSObjShow.params.password = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Make the API call
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post -SessionVariable global:websession
    }

    If ($ShowJsonResponse){
        #Create a deep copy of the $Request Object. This is necessary because otherwise changing the $PSObjShow is referencing the same object in memory as $Request
        $PSObjShow = $Request.result | ConvertTo-Json -Depth 5 | ConvertFrom-Json 
        if($PSObjShow.sessionid) {
            $PSObjShow.sessionid = "*****"
        }
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($PSObjShow | ConvertTo-Json -Depth 5)
    }
    
    #Save the logon data
    $NewLogonData.SessionID = $Request.result.sessionid | ConvertTo-SecureString -asPlainText -Force | ConvertFrom-SecureString 
    #Add the new logondata item into logondatalist, first filter out the entry with the same url, that entry will be overwritten by $NewLogonData
    $LogonDataList = $LogonDataList | Where-Object {$_.URL -ne $NewLogonData.URL}
    $LogonDataList += $NewLogonData
    $LogonDataList | ConvertTo-Json | Out-File $SaveLocation -Force

    
    if($null -ne $Request.error){
        #This will be returned by the function in case of error
        $Request.error
        return
    }     
    else {
        #Add the session id into the global variable.
        $Global:ZXAPIToken = $Request.result.sessionid | ConvertTo-SecureString -AsPlainText -Force
        #This will be returned by the function if there is no error and if showsessionid parameter is used  
        if($ShowSessionID){
            $Request.result
            return   
        }
        else{
            #This will be returned by the function if there is no error and showsessionid is NOT used. 
            $request.result.sessionid = "*****"
            $Request.result
            return    
        }
    }   
}

function New-ZXProblemTagList {

    $Tags = [System.Collections.ArrayList]::new()

    $object = [PSCustomObject]@{
        Tags = $Tags
    }

    $object | Add-Member -MemberType ScriptMethod -Name AddTag -Value {
        param (
            [string]$TagName,
            [ValidateSet("0","2","Contains","Equals")]
            [string]$Operator,
            [string]$Value
        )
        switch ($operator){
            Equals {$Operator = "0"}
            Contains {$Operator = "2" }
        }
        $newObject = [PSCustomObject]@{ tag = $TagName; operator = $Operator; value = $Value }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }
    return $object
    
}


function New-ZXService {
    param(
        [string]$Name,
        [ValidateSet("0","1","2")]
        [string]$Algorithm,
        [string]$StatusCalculationRule,
        [string]$SortOrder,
        [string]$Description,
        [array]$ChildServiceID,
        [array]$ParentServiceID,
        [array]$ProblemTag,
        [array]$ServiceTag,
        [switch]$ShowJsonRequest,
        [switch]$WhatIf,
        [PSCustomObject]$Parameters,
        [array]$StatusRule

    )

    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{$PropertyName = "$item"}
        }
        $Result
        return
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "service.create";
        "params" = [PSCustomObject]@{
        }; 
        #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
        "id" = 1;
    }

    #Add Parameters based on function parameters
    if ($Parameters) {
        $PSObj.params = $Parameters
    }
    if ($Name) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "name" -Value $Name
    }
    if ($Algorithm) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "algorithm" -Value $Algorithm
    }
    if ($ProblemTag) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "problem_tags" -Value $ProblemTag
    }
    if ($ServiceTag) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $ServiceTag
    }
    if ($ParentServiceID) {
        $ParentServiceID = ConvertArrayToObjects -PropertyName serviceid -Array $ParentServiceID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "parents" -Value @($ParentServiceID)
    }
    if ($SortOrder) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sortorder" -Value $SortOrder
    }
    if($StatusRule){
        $StatusRule = [PSCustomObject]@{
            "type" = $StatusRule[0]
            "limit_value" = $StatusRule[1]
            "limit_status" = $StatusRule[2]
            "new_status" = $StatusRule[3]
        }
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "status_rules" -Value @($StatusRule)
    }

    #Convert the ps object to json. It is crucial to use a correct value for the -Depth
    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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

function New-ZXTagFilter {

    $Tags = [System.Collections.ArrayList]::new()

    $object = [PSCustomObject]@{
        Tags = $Tags
    }

    $object | Add-Member -MemberType ScriptMethod -Name AddTag -Value {
        param (
            [string]$Name,
            [ValidateSet("0","1","2","3","4","5","Contains","Equals","NotLike","NotEqual","Exists","NotExists")]
            [string]$Operator,
            [string]$Value
        )
        switch ($operator){
            Contains {$operator = "0"}
            Equals {$operator = "1"}
            NotLike {$operator = "2" }
            NotEqual {$operator = "3" }
            Exists {$operator = "4" }
            NotExists {$operator = "5" }
        }
        $newObject = [PSCustomObject]@{ tag = $Name; operator = $Operator; value = $Value }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }
    return $object
    
}


function New-ZXTagList {
    $Tags = [System.Collections.ArrayList]::new()

    $object = [PSCustomObject]@{
        Tags = $Tags
    }

    $object | Add-Member -MemberType ScriptMethod -Name AddTag -Value {
        param (
            [string]$TagName,
            [string]$TagValue
        )
        $newObject = [PSCustomObject]@{ tag = $TagName; value = $TagValue }
        $this.Tags.Add($newObject) | Out-Null
        return $this
    }
    return $object
}


function New-ZXTokenSession{
    param(
        [switch]$Save,
        [switch]$RemoveAllSettings,
        [switch]$Load,
        [string]$Url,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf

    )

    #Create the tokens.txt file if it does not exist yet
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Login\Tokens.txt"
    if (!( Test-Path $SaveLocation)){
        New-Item -ItemType File $SaveLocation -Force | Out-Null
    }

    # Set the variables for the current powershell session without saving them into registry
    if(!$RemoveAllSettings -and !$Load){
        $Global:ZXAPIToken = Read-Host -AsSecureString -Prompt "Enter the zabbix API Token"
        if ($URL){
            $Global:ZXAPIUrl = $URL
        }
        else{
            $Global:ZXAPIUrl = Read-Host -Prompt "Enter the zabbix API URL"
        }
    }

    # Save the settings to registry. The settins are saved in a new subkey that has the same name as the zabbix api url
    # If you save the the settings for the same url again they will be overwritten
    if($Save){

        Write-Host -ForegroundColor Yellow "Encrypting and saving the token in $SaveLocation"
        
        $NewObj = [pscustomobject]@{
            "Id" = ""
            "URL" = $ZXAPIUrl
            "Token" = $ZXAPIToken | ConvertFrom-SecureString
        }

        #Get the data from the Tokens.txt, filter out the entry with the same URL you have entered in case it exists.
        #This way you can enter the same url again and the record with this url will be overwritten
        $LogonData = @(Get-Content $SaveLocation | ConvertFrom-Json | Where-Object {$_.URL -ne $NewObj.URL })
        #Add the data you entered into read-host prompt
        $LogonData += $NewObj
        #Add an Id to each object
        $LogonData | ForEach-Object -Begin {$i=0} -Process { $_.Id = $i;$i++} -End {Remove-Variable i}
        #Save the object
        $LogonData | ConvertTo-Json | Out-File $SaveLocation -Force
        
    }

    #Remove the whole HKCU:\SOFTWARE\ZXModule subkey
    if($RemoveAllSettings){
        Remove-Item $SaveLocation
    }

    #Load the settings - load all subkeys under HKCU:\SOFTWARE\ZXModule and let the user choose which one to load
    if($Load -and -not $Url){
        $LogonData = Get-Content $SaveLocation | ConvertFrom-Json
        $LogonData | ForEach-Object {
            Write-Host -NoNewline "[$($_.Id)]"; 
            Write-Host -ForegroundColor Yellow " $($_.URL)";
        }
        $Choice = Read-Host -Prompt "Select the number and press enter"

        $ZXAPIToken = $LogonData[$Choice].Token | ConvertTo-SecureString
        $Global:ZXApiURL = $LogonData[$Choice].URL

    }

    if($Load -and $Url){
        $LogonData = (Get-Content $SaveLocation | ConvertFrom-Json) | Where-Object {$_.URL -eq $Url}
        $Global:ZXAPIToken = $LogonData.Token | ConvertTo-SecureString
        $Global:ZXAPIUrl = $LogonData.URL
        if($Global:ZXAPIToken -ne $null -and $Global:ZXAPIToken -ne ""  -and $Global:ZXAPIUrl -ne $null -and $Global:ZXAPIUrl -ne ""){
            Write-Host -ForegroundColor Green "Loaded the token for $($Global:ZXAPIUrl)"
        }
    }

    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.checkAuthentication";
        "params" = [PSCustomObject]@{
            "token" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($ZXAPIToken)));
        };
        "id" = "1"
    }

        
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        if($PSObjShow.params.token){
            $PSObjShow.params.token = "*****"
        }
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    $JSON = $PSObj | ConvertTo-Json -Depth 5

    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        if($Request.result){
            if($ShowSessionID){
                $Request.result
            }
            elseif($request.result.sessionid) {
                $request.result.sessionid = "*****"
                $request.result
            }
            else{
                $request.result
            }
        }
     }
}

function Remove-ZXHost{
    param(
        [array]$HostId,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse
    )
   
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
        "method" = "host.delete"; 
        "params" = $HostId; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }

    $ZXHost = Get-ZXHost -HostID $HostId
    if($null -eq $ZXHost.hostid){
        Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
        Write-Host " $HostId"
        Continue
    }

    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        #Make a clean copy of an object - have to uset convertto and convertfrom in order to break the references to the original object
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
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



function Remove-ZXHostGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [array]$HostID,
        [Parameter(Mandatory=$false)]
        [array]$GroupID,
        [Parameter(Mandatory=$false)]
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [Alias("SaveRes")]
        [bool]$SaveJsonRequest=$true,
        [Alias("SaveReq")]
        [bool]$SaveJsonResponse=$true,
        [switch]$WhatIf
    )
    
    #Funcions
    function DateToString{
        (Get-Date).ToString("2024-MM-dd_HH.mm.ss.ffff")
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Variables
    $DateTime = DateToString
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Request-Response_$DateTime"

    #CreateaRequestResponseDirectory
    New-Item $SaveLocation -ItemType Directory

    #!!!!! Unlike with hostgroup.massadd, you cannot use array of objects here, only arrays of group IDs and host IDs.

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "hostgroup.massremove"; 
        "params" = [PSCustomObject]@{
        }; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }
    #Add properties to the basic PS object based on the used parameters
    if($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    $Json = $PSObj | ConvertTo-Json -Depth 5 

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
            
    #Save JSON Request if -SaveJsonRequest is not $false. Default is $true.
    If ($SaveJsonRequest){
        $Json | Out-File -FilePath "$SaveLocation\remove-ZXHostGroup_JSON_Request_$DateTime.json"
        Write-Host -ForegroundColor Yellow "Request saved to:"
        Write-Host "$SaveLocation\remove-ZXHostGroup_JSON_Request_$DateTime.json"
    }

    #Make the API call
    if (!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Show JSON Response if -ShowJsonResponse switch is used
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "`nJSON RESPONSE"
        if($null -ne $Request.error){Write-Host -ForegroundColor Cyan "$($request.error | ConvertTo-Json -Depth 5)`n"}
        else{Write-Host -ForegroundColor Cyan "$($request.result | ConvertTo-Json -Depth 5)`n"}
    }
    #Save JSON Request if -SaveJsonResponse is not $false. Default is $true.
    If ($SaveJsonResponse){
        if($null -ne $Request.error){
            $request.error | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\remove-ZXHostGroup_JSON_Response_$DateTime.json"
        }
        else{
            $request.result | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\remove-ZXHostGroup_JSON_Response_$DateTime.json"
        }
        Write-Host -ForegroundColor Yellow "Response saved to:"
        Write-Host "$SaveLocation\remove-ZXHostGroup-JSON_Response-$DateTime.json"
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

function Remove-ZXHostNameSuffixX{
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
    $LoopID = [Guid]::NewGuid() | Select-Object -ExpandProperty Guid
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

    function RemoveZXHostNameSuffixX {
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
            $ZXHost = Get-ZXHost -HostID $HostId -Output hostid,host,name
            if($null -eq $ZXHost.hostid){
                Write-Host "$HostId > " -NoNewline
                Write-Host -ForegroundColor Yellow Not Found
                $LogObject.HostsNotFound += $HostId
                Continue
            }

        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -Output hostid,host,name
            if($null -eq $ZXHost.host){
                Write-Host "$HostName > " -NoNewline
                Write-Host -ForegroundColor Yellow Not Found
                $LogObject.HostsNotFound += $HostName
                Continue
            }

        }
        #Remove and add the dot to the suffix. This way you can enter the suffix with or without the initial dot.
        $Suffix = "." + $Suffix.trim(".")
        #NewHostName. Do not use trim here
        $NewHostName = "$($ZXHost.host)".Replace($Suffix,"")
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
            RemoveZXHostNameSuffixX -HostName $Name -LoopID $LoopID 
        }    
    }
    if($HostID){
        foreach($Id in $HostId){
            RemoveZXHostNameSuffixX -HostId $Name -LoopID $LoopID 
        }    
    }

    $LogObject | ConvertTo-Json -Depth 6 | Out-File -FilePath $LogPath
    #Display the hosts that were skipped
    if ($LogObject.Skipped.length -gt 0){
        Write-Host "The following hosts were skipped because they have a dot character '.' in the name, therefore they may already have a suffix. Use -Force switch to add the suffix anyway."
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



function Remove-ZXMaintenance{
    param(
        [array]$MaintenanceId,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse
    )
   
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
        "method" = "maintenance.delete"; 
        "params" = $MaintenanceId; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }

    $ZXMaintenance = Get-ZXMaintenance -MaintenanceID $MaintenanceId
    if($null -eq $ZXMaintenance){
        Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
        Write-Host " $MaintenanceId"
        Continue
    }

    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        #Make a clean copy of an object - have to uset convertto and convertfrom in order to break the references to the original object
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
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



function Set-ZXHostLetterCase{
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

function Set-ZXHostLetterCaseX{
    param(
        [array]$HostName,
        [array]$HostId,
        [switch]$ToUpper,
        [switch]$ToLower,
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

    function SetZXHostLetterCaseX {
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

        #Check if the host contains any active check. If so skip the host and add it to the log object.
        if($ZXHost.items.type -contains "7" -and -not $Force){
            Write-Host -ForegroundColor Yellow "[$($ZXHost.host)] => Skipped (Has Agent Active Checks) ."
            $LogObject.Skipped += $ZXHost.host
            continue
        }
        #NewHostName
        if ($ToUpper){
            $NewHostName ="$($ZXHost.host)".ToUpper()
        }
        if ($ToLower){
            $NewHostName ="$($ZXHost.host)".ToLower()
        }

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

    }#SetZXHostLetterCaseX

    if($HostName){
        foreach($Name in $HostName){
            SetZXHostLetterCaseX -HostName $Name -LoopID $LoopID 
        }    
    }
    if($HostID){
        foreach($Id in $HostId){
            SetZXHostLetterCaseX -HostId $Name -LoopID $LoopID 
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



function Set-ZXHostName{
    param(
        [string]$HostName,
        [string]$HostId,
        [Parameter(Mandatory=$true)]
        [string]$NewHostName,
        [string]$NewAlias,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$Transcript
    )
    #Start Transcript
    if($Transcript){
        Start-Transcript
    }

    #Verify parameters

    #WARNING if you want the alias to be equal to the name, use -NewAlias parameter and set it to the same value as name.
    if(!$NewAlias){
        Write-Host "If you want the alias to be equal to the name, use -NewAlias parameter and set it to the same value as name"
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

    if($NewHostName){

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
        #Read the $ZXHost properties and use the values to fill in $PSobject properties. $PSobject is later converted to $json request
        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $NewHostName
        if($NewAlias){
            $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $NewAlias
        }
        else{
            $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        }
    
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
        Write-Host -ForegroundColor Green "[$($Request.result.hostids)] $HostName => $NewHostName"
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

function Stop-ZXSession {
    param(
        [switch]$ShowJsonRequest=$true,
        [switch]$ShowJsonResponse,
        [string]$SessionID,
        [string]$ZXAPIUrl = $ZXAPIUrl,
        [switch]$WhatIf
    )

    if ($null -eq $ZXAPIUrl){
        $ZXAPIUrl = Read-Host -Prompt "Enter the zabbix API url:" 
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    if ($SessionID){     
        $Auth = $SessionID
    }
    else {
        $Auth = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($ZXAPIToken)));
    }
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.logout";
        "params" = @();
        "auth" = "$Auth"
        "id" = "1"

    }
    $JSON = $PSObj | ConvertTo-Json
    
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
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
    else {
        $Request.result
        return
    }
}

function Update-ZXHostTagList{
    param(
        [string]$HostName,
        [string]$HostId,
        [string]$AddTag, 
        [string]$AddTagValue,
        [string]$RemoveTag,
        [string]$RemoveTagValue,
        [switch]$RemoveAllTags,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [bool]$Continue

    )
    #Validate Parameters
    if ($AddTag -eq $RemoveTag -and $AddTagValue -eq $RemoveTagValue){
        Write-Host -ForegroundColor Red "You are trying to add and remove an identical tag/value pair. Choose only one operation."
        continue
    }
    if($RemoveTag -and -not $RemoveTagValue ) {
        Write-Host -ForegroundColor Yellow "-RemoveTagValue parameter was not specified. This will remove all $RemoveTag tags regardless of the value. Continue ?"
        Pause    
    }

    #Funcions
    function DateToString{
        (Get-Date).ToString("2024-MM-dd_HH.mm.ss.ffff")
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
            $ZXHost = Get-ZXHost -HostID $HostId -IncludeTags
        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -IncludeTags
        }
        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
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
            $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5
            $PSObjShow.auth = "*****"
            $RequestLogObject = [PSCustomObject]@{
                "Time" = Get-Date -Format "MM/dd/yyyy HH:mm"
                "Type" = "Request"
                "CorrelationID" = $CorrelationID
                "LoopID" = $LoopID
                "RequestObject" = $PSObjShow
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

function Update-ZXHostTemplateList{
    param(
        [string]$HostName,
        [string]$HostId,
        [string]$LinkTemplateID, 
        [string]$UnlinkTemplateID,
        [string]$UnlinkClearTemplateID,
        [switch]$WhatIf,
        [Alias("SaveRes")]
        [bool]$SaveJsonRequest=$true,
        [Alias("SaveReq")]
        [bool]$SaveJsonResponse=$true,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse

    )
    #Funcions
    function DateToString{
        (Get-Date).ToString("2024-MM-dd_HH.mm.ss.ffff")
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Variables
    $DateTime = DateToString
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Request-Response_$DateTime"

    #CreateaRequestResponseDirectory
    New-Item $SaveLocation -ItemType Directory

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

    if($LinkTemplateID -or $UnlinkTemplateID){

        if($HostId){
            $ZXHost = Get-ZXHost -HostID $HostId -IncludeParentTemplates
        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -IncludeParentTemplates
        }
        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        $TemplateList = $ZXHost.ParentTemplates

        if($LinkTemplateID){
            $TemplateList =  $TemplateList += @{"templateid"= $LinkTemplateID}
        } 
    
        if($UnlinkTemplateID){
            $TemplateList = $TemplateList | Where-Object {$_.templateid -ne $UnlinkTemplateID}
        } 

        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "templates" -Value @($TemplateList)

    }
    
    if($UnlinkClearTemplateID){
        if($HostId){$ZXHost = Get-ZXHost -HostID $HostId -IncludeParentTemplates}
        elseif ($HostName){($ZXHost = Get-ZXHost -Name $HostName -IncludeParentTemplates)}

        $TemplatesToClear = $ZXHost.ParentTemplates | Where-Object {$_.templateid -eq $UnlinkClearTemplateID}

        $PSObj.params.hostid = $HostId
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "templates_clear" -Value @($TemplatesToClear)
    } 

    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Save JSON Request if -SaveJsonRequest is not $false. Default is $true.
    If ($SaveJsonRequest){
        $Json | Out-File -FilePath "$SaveLocation\Set-ZXHost_JSON_Request_$DateTime.json"
        Write-Host -ForegroundColor Yellow "Request saved to:"
        Write-Host "$SaveLocation\Set-ZXHost_JSON_Request_$DateTime.json"
    }

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
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

    #Save JSON Request if -SaveJsonResponse is not $false. Default is $true.
    If ($SaveJsonResponse){
        if($null -ne $Request.error){
            $request.error | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Set-ZXHost_JSON_Response_$DateTime.json"
        }
        else{
            $request.result | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Set-ZXHost_JSON_Response_$DateTime.json"
        }
        Write-Host -ForegroundColor Yellow "Response saved to:"
        Write-Host "$SaveLocation\Set-ZXHost_JSON_Response_$DateTime.json"
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



function Update-ZXMaintenance {
    param(
        [array]$GroupID,
        [array]$HostIDReplace,
        [string]$MaintenanceID,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Validate Parameters

    #Functions

    # Create an array of objects from a simple array. Each object has only one property $PropertyName (you choose the name).
    # For example from the following array "1234","4321" it creates two objects "hostid" = "1234" and "hostid" = "4321"
    # and puts it into an array, then you can add it to the PS object and convert it to json object for the API request.
    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{$PropertyName = "$item"}
        }
        $Result
        return
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "maintenance.update";
        "params" = [PSCustomObject]@{};
        "id" = 1;
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
    }

    if ($HostIDReplace){
        $HostIDObjects = ConvertArrayToObjects -PropertyName "hostid" -Array $HostIDReplace
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hosts" -Value @($HostIDObjects)
    }
    if ($GroupID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value $GroupID
    }
    if ($MaintenanceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "maintenanceid" -Value $MaintenanceID
    }

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
    if($WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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

function Update-ZXService {
    param(
        [string]$ServiceID,
        [string]$Name,
        [ValidateSet("0","1","2")]
        [string]$Algorithm,
        [string]$StatusCalculationRule,
        [string]$SortOrder,
        [string]$Description,
        [array]$ChildServiceID,
        [array]$ParentServiceID,
        [array]$ProblemTag,
        [array]$ServiceTag,
        [switch]$ShowJsonRequest,
        [switch]$WhatIf,
        [PSCustomObject]$Parameters,
        [array]$StatusRule
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "service.update";
        "params" = [PSCustomObject]@{
            "serviceid" = $ServiceID
        }; 
        #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
        "id" = 1;
    }

    #Add Parameters based on function parameters
    if ($Parameters) {
        $PSObj.params = $Parameters
    }
    if ($Name) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "name" -Value $Name
    }
    if ($Algorithm) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "algorithm" -Value $Algorithm
    }
    if ($ProblemTag) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "problem_tags" -Value $ProblemTag
    }
    if ($ServiceTag) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $ServiceTag
    }
    if ($ParentServiceID) {
        $ParentServiceID = ConvertArrayToObjects -PropertyName serviceid -Array $ParentServiceID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "parents" -Value @($ParentServiceID)
    }
    if ($SortOrder) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sortorder" -Value $SortOrder
    }
    if($StatusRule){
        $StatusRule = [PSCustomObject]@{
            "type" = $StatusRule[0]
            "limit_value" = $StatusRule[1]
            "limit_status" = $StatusRule[2]
            "new_status" = $StatusRule[3]
        }
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "status_rules" -Value @($StatusRule)
    }

    #Convert the ps object to json. It is crucial to use a correct value for the -Depth
    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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

