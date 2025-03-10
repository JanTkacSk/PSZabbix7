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
    if ($IncludeDiscoveryRule) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectDiscoveryRule" -Value $DiscoveryRuleProperties
    }
    if ($IncludeItemDiscovery) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItemDiscovery" -Value $ItemDiscoveryProperties
    }
    if ($GroupID) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groupids" -Value @($GroupIDs)
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