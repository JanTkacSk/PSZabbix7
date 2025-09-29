function Get-ZXHostInterface {
    param(
        [array]$IP,
        [string]$IPSearch,
        [array]$InterfaceID,
        [array]$HostID,
        [array]$ItemProperties,
        [switch]$IncludeItems,
        [int]$Limit,
        [int]$Type,
        [switch]$WhatIf,
        [switch]$CountOutput

    )

    if ($IncludeItems){
        If (!$ItemProperties){
            $ItemProperties = @("name","itemid","type","lastvalue","delay","master_itemid")
        }
        elseif($ItemProperties -contains "extend"){
            [string]$ItemProperties = "extend"
        }    
    }
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "hostinterface.get"
    
    if($IP){AddFilter -PropertyName "ip" -PropertyValue $IP}
    if($Type){AddFilter -PropertyName "type" -PropertyValue $Type}
    if($IPSearch){AddSearch -PropertyName "ip" -PropertyValue $IPSearch}
    if($InterfaceID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "interfaceids" -Value $InterfaceID
    }
    if($HostID){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostids" -Value $HostID
    }
    if ($IncludeItems) {
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectItems" -Value $ItemProperties
    }
    #Return only output count
    if($CountOutput){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "countOutput" -Value "true"
    }

    #Limit the number of returned Interfaces
    if($Limit){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "limit" -Value $Limit
    }

    #$PSObj.params.output = "extend"
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