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