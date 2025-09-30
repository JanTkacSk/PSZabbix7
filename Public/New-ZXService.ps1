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
    $PSObj = New-ZXApiRequestObject -Method "service.create"

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

    #Show JSON Request if -WhatIf switch is used
    If ($WhatIf){
        Write-JsonRequest
    }

    #Make the final API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }

}