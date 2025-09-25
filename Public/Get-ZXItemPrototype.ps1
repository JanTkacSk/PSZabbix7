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
        [switch]$ExcludeSearch,
        [switch]$WhatIf
    )

    # Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "itemprototype.get"

    # Validate Parameters
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
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
}