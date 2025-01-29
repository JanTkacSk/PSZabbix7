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
        [switch]$IncludeFunctions,
        [switch]$IncludeDependencies,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "trigger.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }
    
    #Validate parameters
    if (!$Output){
        $Output = @("hostid","host","name","status","proxy_hostid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
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
    

    #Get the item for the hosts with the specified IDs
    if ($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
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

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    
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