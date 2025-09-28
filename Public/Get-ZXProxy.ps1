function Get-ZXProxy {
    param(
        [array]$Name,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$WhatIf
    )

    function ConvertFrom-UnixEpochTime ($UnixEpochTime){
        $customDate = (Get-Date -Date "01-01-1970") + ([System.TimeSpan]::FromSeconds($UnixEpochTime))
        $customDate
    }
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "proxy.get"
        
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
    }
    
    if($Name){AddFilter -PropertyName "host" -PropertyValue $Name}
    if($NameSearch){AddSearch -PropertyName "host" -PropertyValue $NameSearch}


    #$PSObj.params.output = "extend"
    $Json =  $PSObj | ConvertTo-Json -Depth 3
    
    #Show JSON Request if -Whatif switch is used
    If ($ShowJsonRequest){
        Write-JsonRequest
    }

    if($WhatIf){
        Write-JsonRequest
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
}
