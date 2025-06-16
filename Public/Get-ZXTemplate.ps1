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