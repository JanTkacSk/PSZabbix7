function Remove-ZXItem{
    param(
        [array]$ItemId,
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method Item.delete
    $PSObj.params = $ItemId
    

    $ZXItem = Get-ZXItem -ItemID $ItemId
    if($null -eq $ZXItem.Itemid){
        Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
        Write-Host " $ItemId"
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


