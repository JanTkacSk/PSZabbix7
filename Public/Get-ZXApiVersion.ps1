function Get-ZXApiVersion {

    param (
        [switch]$WhatIf
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
        $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "apiinfo.version";
        "params" = @();
        "id"  = "1"
    }

    $JSON = $PSObj | ConvertTo-Json -Depth 5

    if ($WhatIf){
        Write-JsonRequest
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $request
    }
    
}
