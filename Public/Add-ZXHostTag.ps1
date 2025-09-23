function Add-ZXHostTag{
    param(
        [string]$HostId,
        [string]$TagName, 
        [string]$TagValue,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = New-ZXApiRequestObject -Method "host.update"
    
    $ZXHost = Get-ZXHost -HostID $HostId -IncludeTags

    if($ZXHost -eq $null){
        Write-Host -ForegroundColor Yellow "Host not found"
        continue
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostid" $HostId
    
    #Get the list of host tags.
    [System.Collections.ArrayList]$TagList = $ZXHost.tags

    $TagList =  $TagList += [PSCustomObject]@{"tag"= $TagName; "value"=$TagValue}

    $PSObj.params |  Add-Member -MemberType NoteProperty -Name "tags" -Value @($TagList)

    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -WhatIf switch is used
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
    
}
