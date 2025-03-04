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