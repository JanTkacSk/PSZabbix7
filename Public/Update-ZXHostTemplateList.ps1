function Update-ZXHostTemplateList{
    param(
        [string]$HostName,
        [string]$HostId,
        [string]$LinkTemplateID, 
        [string]$UnlinkTemplateID,
        [string]$UnlinkClearTemplateID,
        [switch]$WhatIf,
        [Alias("SaveRes")]
        [bool]$SaveJsonRequest=$true,
        [Alias("SaveReq")]
        [bool]$SaveJsonResponse=$true,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse

    )
    #Funcions
    function DateToString{
        (Get-Date).ToString("2024-MM-dd_HH.mm.ss.ffff")
    }

    #A function that formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
    function ShowJsonRequest {
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Variables
    $DateTime = DateToString
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Request-Response_$DateTime"

    #CreateaRequestResponseDirectory
    New-Item $SaveLocation -ItemType Directory

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObj  = [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "host.update"; 
        "params" = [PSCustomObject]@{
            "hostid" = $HostId
        }; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }

    if($LinkTemplateID -or $UnlinkTemplateID){

        if($HostId){
            $ZXHost = Get-ZXHost -HostID $HostId -IncludeParentTemplates
        }
        elseif ($HostName){
            $ZXHost = Get-ZXHost -Name $HostName -IncludeParentTemplates
        }
        $PSObj.params.hostid = $ZXHost.hostid
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        $TemplateList = $ZXHost.ParentTemplates

        if($LinkTemplateID){
            $TemplateList =  $TemplateList += @{"templateid"= $LinkTemplateID}
        } 
    
        if($UnlinkTemplateID){
            $TemplateList = $TemplateList | Where-Object {$_.templateid -ne $UnlinkTemplateID}
        } 

        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "templates" -Value @($TemplateList)

    }
    
    if($UnlinkClearTemplateID){
        if($HostId){$ZXHost = Get-ZXHost -HostID $HostId -IncludeParentTemplates}
        elseif ($HostName){($ZXHost = Get-ZXHost -Name $HostName -IncludeParentTemplates)}

        $TemplatesToClear = $ZXHost.ParentTemplates | Where-Object {$_.templateid -eq $UnlinkClearTemplateID}

        $PSObj.params.hostid = $HostId
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "host" -Value $ZXHost.host
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "name" -Value $ZXHost.name
        $PSObj.params |  Add-Member -MemberType NoteProperty -Name "templates_clear" -Value @($TemplatesToClear)
    } 

    $Json = $PSObj | ConvertTo-Json -Depth 5

    #Save JSON Request if -SaveJsonRequest is not $false. Default is $true.
    If ($SaveJsonRequest){
        $Json | Out-File -FilePath "$SaveLocation\Set-ZXHost_JSON_Request_$DateTime.json"
        Write-Host -ForegroundColor Yellow "Request saved to:"
        Write-Host "$SaveLocation\Set-ZXHost_JSON_Request_$DateTime.json"
    }

    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj
        $PSObjShow.auth = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    #Make the API call
    if(!$Whatif){
        $Request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    #Save JSON Request if -SaveJsonResponse is not $false. Default is $true.
    If ($SaveJsonResponse){
        if($null -ne $Request.error){
            $request.error | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Set-ZXHost_JSON_Response_$DateTime.json"
        }
        else{
            $request.result | ConvertTo-Json -Depth 5 | Out-File -FilePath "$SaveLocation\Set-ZXHost_JSON_Response_$DateTime.json"
        }
        Write-Host -ForegroundColor Yellow "Response saved to:"
        Write-Host "$SaveLocation\Set-ZXHost_JSON_Response_$DateTime.json"
    }

    If ($ShowJsonResponse){
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($request.result | ConvertTo-Json -Depth 5)
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


