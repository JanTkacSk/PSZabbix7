function Invoke-ZXTask {
    param(
        [array]$ItemID,
        [string]$Type,
        [switch]$WhatIf,
        [array]$Output
    )

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "task.create"

    if($ItemID){
        $TaskObjects = ConvertArrayToObjects -PropertyName "itemid" -Array $ItemID
        $PSObj.params = @($TaskObjects)
    }

    $PSObj.params | Add-Member -MemberType NoteProperty -Name "output" -Value $Output

    $Json =  $PSObj | ConvertTo-Json -Depth 5

    if ($WhatIf){
        Write-JsonRequest
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
}


