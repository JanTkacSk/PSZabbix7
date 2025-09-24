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
        [switch]$IncludeDiscoveries,
        [switch]$IncludeHostGroups,
        [switch]$IncludeInterfaces,
        [switch]$IncludeInventory,
        [switch]$IncludeItems,
        [switch]$IncludeMacros,
        [switch]$IncludeParentTemplates,
        [switch]$IncludeTags,
        [switch]$WithItems,
        [switch]$IncludeInheritedTags,
        [switch]$IncludeTriggers,
        [array]$TemplateIDs,
        [array]$Tag,
        [array]$GroupIDs,
        [switch]$inheritedTags,
        [switch]$CountOutput,
        [array]$Output,
        [int]$Limit,
        [switch]$WhatIf,
        [array]$ItemProperties,
        [array]$InventoryProperties,
        [array]$InterfaceProperties,
        [array]$TriggerProperties,
        [array]$DiscoveryProperties

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
        if (!$InventoryProperties){
            [string]$InventoryProperties = "extend"
        }
        elseif($InventoryProperties -contains "extend"){
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
    if ($IncludeDiscoveries){
        If (!$DiscoveryProperties){
            $DiscoveryProperties = @("name")
        }
        elseif($DiscoveryProperties -contains "extend"){
            [string]$DiscoveryProperties = "extend"
        }    
    }

    if (!$Output){
        $Output = @("hostid","host","name","status","proxy_hostid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }

    #Use Get-ZXHostInterface to search for the IP interfaces and get their host Id(s)
    if($IPsearch -and !$WhatIf){
        $HostID =  Get-ZXHostInterface -IPSearch $IPSearch | Select-Object -ExpandProperty hostid
        #If the HostidID is null the host.get will return all the hosts in zabbix.
        if ($null -eq $HostID){
            $HostID = "..n/a.."
        }   
    }
    elseif($IPSearch -and $WhatIf){
        Get-ZXHostInterface -IPSearch $IPSearch -WhatIf
        $HostID = "HostID(s)FromTheFirstAPICall"
    }

    #Use Get-ZXHostInterface to get IP interfaces that EXACTLY match the ip value of the argument, and get their host Id(s)
    if($IP -and !$WhatIf){
        $HostID =  Get-ZXHostInterface -IP $IP | Select-Object -ExpandProperty hostid
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

    $PSObj = New-ZXApiRequestObject -Method host.get

    
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
    if ($IncludeDiscoveries) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectDiscoveries" -Value $DiscoveryProperties
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

    #Show JSON Request if -WhatIf switch is used
    If ($WhatIf){Write-JsonRequest}

    #Record API call start time
    $APICallStartTime = Get-Date

    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }        
}