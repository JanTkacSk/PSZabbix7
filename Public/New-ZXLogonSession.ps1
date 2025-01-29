function New-ZXLogonSession {
    param(
        [switch]$UserData,
        [switch]$Load,
        [string]$UserName,
        [string]$Url, 
        [switch]$ShowJsonRequest,
        [switch]$ShowJsonResponse,
        [switch]$WhatIf,
        [switch]$ShowSessionID

    )
    
    #Read the user input
    if(!$RemoveAllSettings -and !$Load){
        if (!$Url){
            $Global:ZXAPIUrl = Read-Host -Prompt "Enter the zabbix API URL"
        }
        else {
            $Global:ZXAPIUrl = $Url
        }

        if (!$UserName){
            $UserName = Read-Host -Prompt "Enter the zabbix API User Name"
        }
        $Password = Read-Host -AsSecureString -Prompt "Enter your password"
    }

    $SaveLocation = "$($env:LOCALAPPDATA)\ZXModule\Login\LogonData.txt"
    if (!( Test-Path $SaveLocation)){
        New-Item -ItemType File $SaveLocation -Force
    }

    #New logon data object
    $NewLogonData = [pscustomobject]@{
        "Id" = ""
        "URL" = $Global:ZXAPIUrl
        "UserName" = $UserName
        "Password" = $Password | ConvertFrom-SecureString
        "SessionID" = ""
    }
    #Get the data from the LogonData.txt, filter out the entry with the same URL you have entered in case it exists.
    #This way you can enter the same url again and the password and name will be overwritten in the next steps
     
    function CheckForAHangingSession{
        $LogonDataList = @(Get-Content $SaveLocation | ConvertFrom-Json)
        $LoadedLogonData = $LogonDataList | Where-Object {$_.URL -eq $Global:ZXAPIUrl}
        # If there is an url and username match between currently entered data and data saved in user profile json file, check if session id is not empty
        # if it is not empty, it means the user did nod log off the session properly, try to use the same session id again.
        if ($LoadedLogonData.SessionID -ne "" -and $LoadedLogonData.SessionID -ne $null){
            $Global:ZXAPIToken = $LoadedLogonData.SessionID | ConvertTo-SecureString
            Write-Host -ForegroundColor Yellow "The last session was not terminated properly.Trying to use the old session..."
            $CheckAuthObj = [PSCustomObject]@{
                "jsonrpc" = "2.0";
                "method" = "user.checkAuthentication";
                "params" = [PSCustomObject]@{
                    "sessionid" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken)));
                };
                "id" = "1"
            }
            $CheckAuthJSON = $CheckAuthObj | ConvertTo-Json -Depth 5

            $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $CheckAuthJSON -ContentType "application/json" -Method Post -SessionVariable global:websession

            if($null -ne $Request.error){
                $Request.error
                exit
            } 
            else {
                if($Request.result){
                    if($ShowSessionID){
                        $Request.result
                        exit
                    }
                    elseif($request.result.sessionid) {
                        $request.result.sessionid = "*****"
                        $request.result
                        exit
                    }
                    else{
                        $request.result
                        exit
                    }
                }
            }   
            #End the sript here even if it fails, you have to make sure the session was terminated
            Write-Host "Exiting the script!"
        }
    }

    CheckForAHangingSession

    #Check for a hanging session
    CheckForAHangingSession

    if($Load -and !$Url){
        $LogonDataList | ForEach-Object {
            Write-Host -NoNewline "[$($_.Id)]"; 
            Write-Host -NoNewline -ForegroundColor Yellow " $($_.URL)"; 
            Write-Host " - $($_.UserName)"
        }
        $Choice = Read-Host -Prompt "Select the number and press enter"

        $UserName = $LogonDataList[$Choice].UserName
        $Password = $LogonDataList[$Choice].Password | ConvertTo-SecureString
        $Global:ZXApiURL = $LogonDataList[$Choice].URL
        #Check for a hanging session first
        CheckForAHangingSession
    }

    if($Load -and $Url){
        $LogonDataList = (Get-Content $SaveLocation | ConvertFrom-Json) | Where-Object {$_.URL -eq $Url}
        $UserName = $LogonDataList.UserName
        $Password = $LogonData.Password | ConvertTo-SecureString
        $Global:ZXApiURL = $LogonData.URL
        #Check for a hanging session first
        CheckForAHangingSession
    }

    #Basic PS Object wich will be edited based on the used parameters and finally converted to json
    $PSObject = [PSCustomObject]@{
        "jsonrpc" = "2.0";
        "method" = "user.login";
        "params" = @{
            "username" = $UserName;
            "password" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Password)));
            "userData" = "$([bool]$UserData)"
        }
        "id" = "1"
    }

    $JSON = $PSObject | ConvertTo-Json
    
    if($ShowJsonRequest){
        Write-Host -ForegroundColor Yellow "JSON REQUEST"
        $PSObjShow = $PSObject | ConvertTo-Json | ConvertFrom-Json
        $PSObjShow.params.password = "*****"
        $JsonShow = $PSObjShow | ConvertTo-Json
        Write-Host -ForegroundColor Cyan $JsonShow
    }

    #Make the API call
    if(!$WhatIf){
        $request = Invoke-RestMethod -Uri $ZXAPIUrl -Body $Json -ContentType "application/json" -Method Post -SessionVariable global:websession
    }

    If ($ShowJsonResponse){
        #Create a deep copy of the $Request Object. This is necessary because otherwise changing the $PSObjShow is referencing the same object in memory as $Request
        $PSObjShow = $Request.result | ConvertTo-Json -Depth 5 | ConvertFrom-Json 
        if($PSObjShow.sessionid) {
            $PSObjShow.sessionid = "*****"
        }
        Write-Host -ForegroundColor Yellow "JSON RESPONSE"
        Write-Host -ForegroundColor Cyan $($PSObjShow | ConvertTo-Json -Depth 5)
    }
    
    #Save the logon data
    $NewLogonData.SessionID = $Request.result.sessionid | ConvertTo-SecureString -asPlainText -Force | ConvertFrom-SecureString 
    #Add the new logondata item into logondatalist, first filter out the entry with the same url, that entry will be overwritten by $NewLogonData
    $LogonDataList = $LogonDataList | Where-Object {$_.URL -ne $NewLogonData.URL}
    $LogonDataList += $NewLogonData
    $LogonDataList | ConvertTo-Json | Out-File $SaveLocation -Force

    
    if($null -ne $Request.error){
        #This will be returned by the function in case of error
        $Request.error
        return
    }     
    else {
        #Add the session id into the global variable.
        $Global:ZXAPIToken = $Request.result.sessionid | ConvertTo-SecureString -AsPlainText -Force
        #This will be returned by the function if there is no error and if showsessionid parameter is used  
        if($ShowSessionID){
            $Request.result
            return   
        }
        else{
            #This will be returned by the function if there is no error and showsessionid is NOT used. 
            $request.result.sessionid = "*****"
            $Request.result
            return    
        }
    }   
}