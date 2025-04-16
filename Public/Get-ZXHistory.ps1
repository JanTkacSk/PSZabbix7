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

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
 
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "history.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }

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

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
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