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
        [switch]$IncludeTemplates,
        [switch]$IncludeDiscoveries,
        [switch]$IncludeItems,
        [switch]$IncludeTriggers,
        [array]$ItemProperties,
        [array]$DiscoveryProperties,
        [array]$Output,
        [switch]$WithItems,
        [switch]$CountOutput,
        [switch]$WhatIf
    )

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
    $PSObj = New-ZXApiRequestObject -Method "template.get"

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
    if ($IncludeTemplates) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectTemplates" -Value "extend"
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

    #Show JSON Request if -Whatif switch is used
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if (!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
    
}