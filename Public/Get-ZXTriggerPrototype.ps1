function Get-ZXTriggerPrototype {
    param(
        [array]$HostID,
        [array]$TriggerID,
        [int]$Limit,
        [int]$Status,
        [array]$Key,
        [array]$DiscoveryID,
        [string]$KeySearch,
        [string]$Type,
        [string]$TypeSearch,
        [array]$Description,
        [string]$TemplateID,
        [switch]$TemplateD,
        [array]$Tag,
        [array]$Output,
        [switch]$CountOutput,
        [string]$DescriptionSearch,
        [switch]$IncludeHosts,
        [switch]$IncludeTags,
        [switch]$IncludeDiscoveryRule,
        [array]$DiscoveryRuleProperties,
        [array]$HostProperties,
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "triggerprototype.get"

    #Validate Parameters

    if (!$Output){
        $Output = @("description","value","status")
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
    if ($TriggerID)
    {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "triggerids" -Value $TriggerID
    }
    #Get the triggers with the specified DiscoveryIDs
    if ($DiscoveryID)
    {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "discoveryids" -Value $DiscoveryID
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

    if ($Description){AddFilter -PropertyName "name" -PropertyValue $Description}
    if ($Id){AddFilter -PropertyName "triggerid" -PropertyValue $Id}
    if ($Key){AddFilter -PropertyName "key_" -PropertyValue $Key}
    if ($State){AddFilter -PropertyName "state" -PropertyValue $State}
    if ($KeySearch){AddSearch -PropertyName "key_" -PropertyValue $KeySearch}
    if ($DescriptionSearch){AddSearch -PropertyName "name" -PropertyValue $DescriptionSearch}
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

    #Show JSON Request if -Whatif switch is used
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }

}