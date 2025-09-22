function Add-ZXHostGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$HostID,
        [Parameter(Mandatory=$true)]
        [array]$GroupID,
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )
    
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = New-ZXApiRequestObject -Method "hostgroup.massadd"

    #Add properties to the basic PS object based on the used parameters
    if($GroupID){
        $GroupIDObjects = ConvertArrayToObjects -PropertyName "groupid" -Array $GroupID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groups" -Value @($GroupIDObjects)
    }
    if($GroupObj){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "groups" -Value $GroupObj
    }
    if($HostID){
        $HostIDObjects = ConvertArrayToObjects -PropertyName "hostid" -Array $HostID
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hosts" -Value @($HostIDObjects)
    }
    if($HostObj){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "hosts" -Value $HostObj
    }

    $Json = $PSObj | ConvertTo-Json -Depth 5 

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($Whatif){
        Write-JsonRequest
    }

    #Make the API call
    if (!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }
    
}
