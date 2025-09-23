function Disable-ZXTrigger{
    param(
        [string]$TriggerId,
        [switch]$WhatIf

    )
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "trigger.update"

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "triggerid" -Value $TriggerId
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "status" -Value "1"

    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }

}


