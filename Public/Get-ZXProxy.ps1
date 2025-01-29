function Get-ZXProxy {
    param(
        [array]$Name,
        [string]$NameSearch,
        [switch]$IncludeHosts,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf
    )

    function ConvertFrom-UnixEpochTime ($UnixEpochTime){
        $customDate = (Get-Date -Date "01-01-1970") + ([System.TimeSpan]::FromSeconds($UnixEpochTime))
        $customDate
    }
   
    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "proxy.get";
        "params" = [PSCustomObject]@{
        };
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = 1
    }
    
    function AddFilter($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.filter){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "filter" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.filter | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }

    #Function to add a Search parameter to the PS object
    function AddSearch($PropertyName,$PropertyValue){
        #Check if filter is already in the object or not and if not, add it.
        if ($null -eq $PSObj.params.search){
            $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
        }
        #Add a specific property to the filter
        $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
    }
    
    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    # Add "selectHosts" parameter to return all hosts linked tho the templates.
    if ($IncludeHosts){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "selectHosts" -Value @("host","name","description")
    }
    
    if($Name){AddFilter -PropertyName "host" -PropertyValue $Name}
    if($NameSearch){AddSearch -PropertyName "host" -PropertyValue $NameSearch}


    #$PSObj.params.output = "extend"
    $Json =  $PSObj | ConvertTo-Json -Depth 3
    
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Make the API call
    if(!$WhatIf){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
    }

    #Add API call time stamp to the result
    $Request.result | Add-Member -MemberType NoteProperty -Name APICallTimeUTC -Value $(Get-Date -AsUTC)

    #Add Human Readable Last Access time
    $Request.result | Add-Member -MemberType ScriptProperty -Name LastAccessReadableUTC -Value {
        ConvertFrom-UnixEpochTime($this.lastaccess)
    }
    #Add the last seen parameter. This is freshly recalculated even if you save the result to variable and then just call the variable
    $Request.result | Add-Member -MemberType ScriptProperty -Name "LastSeen" -Value {
        (Get-Date $this.APICallTimeUTC) - (get-date $this.LastAccessReadableUTC) | Select-Object -ExpandProperty totalseconds
    
    }

    if($IncludeHosts){
        $Request.result | Add-Member -MemberType ScriptProperty -Name "HostCount" -Value {
        ($this.Hosts).count
        }
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
