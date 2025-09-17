function Remove-ZXHost{
    param(
        [array]$HostId,
        [switch]$WhatIf,
        [switch]$ShowJsonRequest
    )
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method host.delete
    $PSObj.params = $HostId
    

    $ZXHost = Get-ZXHost -HostID $HostId
    if($null -eq $ZXHost.hostid){
        Write-Host -ForegroundColor Yellow "[Not Found]" -NoNewline
        Write-Host " $HostId"
        Continue
    }

    $Json = $PSObj | ConvertTo-Json -Depth 5


    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest -or $WhatIf){
        Write-JsonRequest
    }
    
    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request #Inspect the request.result and display the output
    }
    
}


