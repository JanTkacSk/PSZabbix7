function New-ZXService {
    param(
        [string]$Name,
        [ValidateSet("0","1","2")]
        [string]$Algorithm,
        [string]$StatusCalculationRule,
        [string]$SortOrder,
        [string]$Description,
        [array]$ChildServiceID,
        [array]$ParentServiceID,
        [array]$ProblemTag,
        [array]$ServiceTag,
        [switch]$ShowJsonRequest,
        [switch]$WhatIf,
        [PSCustomObject]$Parameters,
        [array]$StatusRule

    )

    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{$PropertyName = "$item"}
        }
        $Result
        return
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "service.create";
        "params" = [PSCustomObject]@{
        }; 
        #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
        "id" = 1;
    }

    #Add Parameters based on function parameters
    if ($Parameters) {
        $PSObj.params = $Parameters
    }
    if ($Name) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "name" -Value $Name
    }
    if ($Algorithm) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "algorithm" -Value $Algorithm
    }
    if ($ProblemTag) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "problem_tags" -Value $ProblemTag
    }
    if ($ServiceTag) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "tags" -Value $ServiceTag
    }
    if ($ParentServiceID) {
        $ParentServiceID = ConvertArrayToObjects -PropertyName serviceid -Array $ParentServiceID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "parents" -Value @($ParentServiceID)
    }
    if ($SortOrder) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "sortorder" -Value $SortOrder
    }
    if($StatusRule){
        $StatusRule = [PSCustomObject]@{
            "type" = $StatusRule[0]
            "limit_value" = $StatusRule[1]
            "limit_status" = $StatusRule[2]
            "new_status" = $StatusRule[3]
        }
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "status_rules" -Value @($StatusRule)
    }

    #Convert the ps object to json. It is crucial to use a correct value for the -Depth
    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
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