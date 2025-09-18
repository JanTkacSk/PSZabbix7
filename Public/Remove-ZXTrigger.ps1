function Remove-ZXTrigger{
    param(
        [array]$TriggerId,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method trigger.delete
    $PSObj.params = $TriggerId
    

    $ZXTrigger = Get-ZXTrigger -TriggerID $TriggerId
    if($null -eq $ZXTrigger.triggerid){
        Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
        Write-Host " $TriggerId"
        Continue
    }

    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Show JSON Request if -Whatif switch is used
    If ($WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request #Inspect the request.result and display the output
    }
    
}


