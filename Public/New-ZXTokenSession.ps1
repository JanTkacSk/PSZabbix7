function New-ZXTokenSession{
    param(
        [switch]$Save,
        [switch]$RemoveAllSettings,
        [switch]$Load,
        [string]$Url,
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf

    )

    #Create the tokens.txt file if it does not exist yet
    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Login\Tokens.txt"
    if (!( Test-Path $SaveLocation)){
        New-Item -ItemType File $SaveLocation -Force
    }

    # Set the variables for the current powershell session without saving them into registry
    if(!$RemoveAllSettings -and !$Load){
        $Global:ZXAPIToken = Read-Host -AsSecureString -Prompt "Enter the zabbix API Token"
        if ($URL){
            $Global:ZXAPIUrl = $URL
        }
        else{
            $Global:ZXAPIUrl = Read-Host -Prompt "Enter the zabbix API URL"
        }
    }

    # Save the settings to registry. The settins are saved in a new subkey that has the same name as the zabbix api url
    # If you save the the settings for the same url again they will be overwritten
    if($Save){
        
        $NewObj = [pscustomobject]@{
            "Id" = ""
            "URL" = $ZXAPIUrl
            "Token" = $ZXAPIToken | ConvertFrom-SecureString
        }

        #Get the data from the Tokens.txt, filter out the entry with the same URL you have entered in case it exists.
        #This way you can enter the same url again and the record with this url will be overwritten
        $LogonData = @(Get-Content $SaveLocation | ConvertFrom-Json | Where-Object {$_.URL -ne $NewObj.URL })
        #Add the data you entered into read-host prompt
        $LogonData += $NewObj
        #Add an Id to each object
        $LogonData | ForEach-Object -Begin {$i=0} -Process { $_.Id = $i;$i++} -End {Remove-Variable i}
        #Save the object
        $LogonData | ConvertTo-Json | Out-File $SaveLocation -Force
        
    }

    #Remove the whole HKCU:\SOFTWARE\ZXModule subkey
    if($RemoveAllSettings){
        Remove-Item $SaveLocation
    }

    #Load the settings - load all subkeys under HKCU:\SOFTWARE\ZXModule and let the user choose which one to load
    if($Load -and -not $Url){
        $LogonData = Get-Content $SaveLocation | ConvertFrom-Json
        $LogonData | ForEach-Object {
            Write-Host -NoNewline "[$($_.Id)]"; 
            Write-Host -ForegroundColor Yellow " $($_.URL)";
        }
        $Choice = Read-Host -Prompt "Select the number and press enter"

        $ZXAPIToken = $LogonData[$Choice].Token | ConvertTo-SecureString
        $Global:ZXApiURL = $LogonData[$Choice].URL

    }

    if($Load -and $Url){
        $LogonData = (Get-Content $SaveLocation | ConvertFrom-Json) | Where-Object {$_.URL -eq $Url}
        $Global:ZXAPIToken = $LogonData.Token | ConvertTo-SecureString
        $Global:ZXAPIUrl = $LogonData.URL
        if($Global:ZXAPIToken -ne $null -and $Global:ZXAPIToken -ne ""  -and $Global:ZXAPIUrl -ne $null -and $Global:ZXAPIUrl -ne ""){
            Write-Host -ForegroundColor Green "Loaded the token for $($Global:ZXAPIUrl)"
        }
    }

    $PSObj = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.checkAuthentication";
        "params" = [PSCustomObject]@{
            "token" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($ZXAPIToken)));
        };
        "id" = "1"
    }

        
    #Show JSON Request if -ShowJsonRequest switch is used
    If ($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObj | ConvertTo-Json | ConvertFrom-Json
        if($PSObjShow.params.token){
            $PSObjShow.params.token = "*****"
        }
        $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
        Write-Host -ForegroundColor Cyan $JsonShow
    }
    
    $JSON = $PSObj | ConvertTo-Json -Depth 5

    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post
    }

    if($null -ne $Request.error){
        $Request.error
        return
    } 
    else {
        if($Request.result){
            if($ShowSessionID){
                $Request.result
            }
            elseif($request.result.sessionid) {
                $request.result.sessionid = "*****"
                $request.result
            }
            else{
                $request.result
            }
        }
     }
}
