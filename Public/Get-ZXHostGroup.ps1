function Get-ZXHostGroup {
    param(
        [array]$Name,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [array]$Output,
        [array]$GroupID,
        [switch]$WithHosts,
        [switch]$WithMonitoredItems,
        [switch]$WhatIf,
        [int]$Limit
    )

    if (!$Output){
        $Output = @("name","groupid")
    }
    elseif($Output -contains "extend") {
        [string]$Output = "extend"
    }
    

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "hostgroup.get"

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
    }
    if ($WithHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "with_hosts" -Value $true
    }
    if ($WithMonitoredItems){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "with_monitored_items" -Value $true
    }
    if($Name){AddFilter -PropertyName "name" -PropertyValue $Name}
    if($NameSearch){AddSearch -PropertyName "name" -PropertyValue $NameSearch}
    if($GroupID){AddFilter -PropertyName "groupid" -PropertyValue $GroupID}
    if($Output) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output
    }

    #Limit the number of returned Groups
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }


    #Show JSON Request if -WhatIf switch is used
    If ($WhatIf){
        Write-JsonRequest
    }

    $JSON = $PSObj | ConvertTo-Json -Depth 5
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
}