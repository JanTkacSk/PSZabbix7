function Add-ZXHostGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [array]$HostID,
        [Parameter(Mandatory=$false)]
        [array]$HostObj,
        [Parameter(Mandatory=$false)]
        [array]$GroupID,
        [Parameter(Mandatory=$false)]
        [array]$GroupObj,
        [Parameter(Mandatory=$false)]
        [switch]$ShowJsonResponse,
        [switch]$ShowJsonRequest,
        [Alias("SaveRes")]
        [bool]$SaveJsonRequest=$true,
        [Alias("SaveReq")]
        [bool]$SaveJsonResponse=$true,
        [switch]$WhatIf
    )
    
    #Funcions
    function DateToString{
        (Get-Date).ToString("2024-MM-dd_HH.mm.ss.ffff")
    }

    #Variables
    $DateTime = DateToString
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Request-Response_$DateTime"

    #CreateaRequestResponseDirectory
    New-Item $SaveLocation -ItemType Directory


    #Check if the parameters are not missing or if the combination is right. Address this later via parameter sets.
    if (!$GroupID -and !$GroupObj){
        Write-Host -ForegroundColor Yellow "You have to specify -GroupID or -GroupObj."
        return
    } 
    if ($GroupID -and $GroupObj){
        Write-Host -ForegroundColor Yellow "You cannot combine -GroupID and -GroupOBJ."
        return
    }
    if ($HostID -and $HostObj){
        Write-Host -ForegroundColor Yellow "You cannot combine -HostID and -HostObj."
        return
    }
    if (!$HostID -and !$HostObj){
        Write-Host -ForegroundColor Yellow "You have to specify -HostID or -HostObj "
        return
    }
    # Create an array of objects from a simple array. Each object has only one property $PropertyName (you choose the name).
    # For example from the following array "1234","4321" it creates two objects "hostid" = "1234" and "hostid" = "4321"
    # and puts it into an array, then you can add it to the PS object and convert it to json object for the API request.
    function ConvertArrayToObjects($PropertyName,$Array){
        $Result = @()
        foreach ($item in $Array){
            $Result += @{$PropertyName = "$item"}
        }
        $Result
        return
    }
    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "hostgroup.massadd"; 
        "params" = [PSCustomObject]@{
        }; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }
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
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    #Save JSON Request if -SaveJsonRequest is not $false. Default is $true.
    If ($SaveJsonRequest){
        $Json | Out-File -FilePath "$SaveLocation\Add-ZXHostGroup_JSON_Request_$DateTime.json"
        Write-Host -ForegroundColor Yellow "Request saved to:"
        Write-Host "$SaveLocation\Add-ZXHostGroup_JSON_Request_$DateTime.json"
    }

    #Make the API call
    if (!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Show JSON Response if -ShowJsonResponse switch is used
    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "`nJSON RESPONSE"
        if($null -ne $Request.error){
            Write-Host -ForegroundColor Cyan "$($request.error | ConvertTo-Json -Depth 5)`n"
        }
        else{
            Write-Host -ForegroundColor Cyan "$($request.result | ConvertTo-Json -Depth 5)`n"
        }
    }
    #Save JSON Request if -SaveJsonResponse is not $false. Default is $true.
    If ($SaveJsonResponse){
        if($null -ne $Request.error){
            $request.error | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Add-ZXHostGroup_JSON_Response_$DateTime.json"
        }
        else{
            $request.result | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Add-ZXHostGroup_JSON_Response_$DateTime.json"
        }
        Write-Host -ForegroundColor Yellow "Response saved to:"
        Write-Host "$SaveLocation\Add-ZXHostGroup-JSON_Response-$DateTime.json"
    }
    
    #This will be returned by the function
    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        $Request.result
        return
    }
    
}
