function Get-ZXDiscoveryRule {
    param(
        [array]$ItemID,
        [array]$GroupID,
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
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "discoveryrule.get"

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
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
}