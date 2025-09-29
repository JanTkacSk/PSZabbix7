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
        [switch]$WhatIf,        
        [string]$Limit
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "trigger.get"

    #Validate parameters
    if (!$Output){
        $Output = @("triggerid","description","expression","status","type","state")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
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
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    
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