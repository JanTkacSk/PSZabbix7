function Remove-ZXHostNameSuffix{
    param(
        [string]$HostName,
        [int] $HostId,
        [string]$Suffix,
        [switch]$SameAlias,
        [switch]$WhatIf,
        [switch]$Transcript
    )

    #Variables
    #Validate parameters
    #WARNING if you want the alias to be equal to the name, use -SameAlias switch and run the command again.
    if(!$SameAlias){
        Write-Host "If you want the alias to be equal to the name, use -SameAlias switch and set it to the same value as name"
        pause
    }
        
    if ($HostName -and $HostId){
        Write-Host -ForegroundColor Yellow 'Not allowed to use -HostName and -HostID parameters together'
        continue
    }


    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj = New-ZXApiRequestObject -Method "host.update"
    $PSObj.params | Add-Member -MemberType NoteProperty -Name "hostid" -Value $HostId

    if($HostId){
        $ZXHost = Get-ZXHost -HostID $HostId -Output hostid,host,name
        if($null -eq $ZXHost.hostid){
            Write-Host "$HostId > " -NoNewline
            Write-Host -ForegroundColor Yellow Not Found
            $LogObject.HostsNotFound += $HostId
            Continue
        }

    }
    elseif ($HostName){
        $ZXHost = Get-ZXHost -Name $HostName -Output hostid,host,name
        if($null -eq $ZXHost.host){
            Write-Host "$HostName > " -NoNewline
            Write-Host -ForegroundColor Yellow Not Found
            $LogObject.HostsNotFound += $HostName
            Continue
        }

    }
    #Remove and add the dot to the suffix. This way you can enter the suffix with or without the initial dot.
    $Suffix = "." + $Suffix.trim(".")
    #NewHostName. Do not use trim here
    $NewHostName = "$($ZXHost.host)".Replace($Suffix,"")
    #Read the $ZXHost properties and use the values to fill in $PSobject properties. $PSobject is later converted to $json request
    $PSObj.params.hostid = $ZXHost.hostid
    $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $NewHostName
    #If -SameAlias switch is not used, the host alias is not changed.
    if($SameAlias){
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $NewHostName
    }
    else{
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
    } 
    
    $Json = $PSObj | ConvertTo-Json -Depth 5

    
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($WhatIf){
        Write-JsonRequest
    }

    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
        Resolve-ZXApiResponse -Request $Request
    }        
}


