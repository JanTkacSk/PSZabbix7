function Get-ZXHistory {
    param(
        [parameter(mandatory="false")]
        [array]$ItemID,
        [int]$Limit,
        [string]$SortField="clock",
        [string]$SortOrder="DESC",
        [parameter(mandatory="true")]
        [int]$History,
        [int]$TimeFrom,
        [int]$TimeTill,
        [string]$Output="extend",
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "history.get"

    #Get the history of the following Items
    if ($ItemID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "itemids" -Value $ItemID
    }

    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }

    if ($SortField){$PSObj.params | Add-Member -MemberType NoteProperty -Name "sortfield" -Value $SortField}
    if ($SortOrder){$PSObj.params | Add-Member -MemberType NoteProperty -Name "sortorder" -Value $SortOrder}
    if ($History){$PSObj.params | Add-Member -MemberType NoteProperty -Name "history" -Value $History}
    if ($TimeTill){$PSObj.params | Add-Member -MemberType NoteProperty -Name "time_till" -Value $TimeTill}
    if ($TimeFrom){$PSObj.params | Add-Member -MemberType NoteProperty -Name "time_from" -Value $TimeFrom}
    if ($Output){$PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output}
    
    $Json =  $PSObj | ConvertTo-Json -Depth 3

    #Show JSON Request if -WhatIf switch is used
    If ($WhatIf){
       Write-JsonRequest
    }
    
    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
}