# -----------Private Functions---------- #

# Formats and displays the json request that is used in the API call, it removes the API token value and replaces it with *****
Function Write-JsonRequest {
    Write-Host -ForegroundColor Yellow "JSON REQUEST"
    $PSObjShow = $PSObj | ConvertTo-Json -Depth 5 | ConvertFrom-Json
    if($PSObjShow.auth) {$PSObjShow.auth = "*****"}
    $JsonShow = $PSObjShow | ConvertTo-Json -Depth 5
    Write-Host -ForegroundColor Cyan $JsonShow
}

# Basic PS Object wich will be edited based on the used parameters and finally converted to json
Function New-ZXApiRequestObject ($Method){
        return [PSCustomObject]@{
        "jsonrpc" = "2.0"; 
        "method" = "$Method"; 
        "params" = [PSCustomObject]@{}; 
        "auth" = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR(($Global:ZXAPIToken))); #This is the same as $Global:ZXAPIToken | ConvertFrom-SecureString -AsPlainText but this worsk also for PS 5.1
        "id" = "1"
    }
}

function Resolve-ZXApiResponse {
    param (
        [Parameter(Mandatory=$true)]
        $Request
    )
    
    if ($null -ne $Request.error) {
        $Request.error
        return
    }
    elseif ($null -ne $Request.result) {
        $Request.result
        return
    }
    else {
        Write-Host -ForegroundColor Yellow "No result"
        return
    }
}

#Function to add a filter parameter to the PS object
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
    #Check if search is already in the object or not and if not, add it.
    if ($null -eq $PSObj.params.search){
        $PSObj.params | Add-Member -MemberType NoteProperty -Name "search" -Value ([PSCustomObject]@{})
    }
    #Add a specific property to the filter
    $PSObj.params.search | Add-Member -MemberType NoteProperty -Name $PropertyName -Value $PropertyValue
}

function ConvertFrom-UnixTime{
    param(
        [array]$UnixTime
    )
    
    # Get the local time zone info
    #$LocalTimeZone = [System.TimeZoneInfo]::Local
    #This is when unix epoch started - 01 January 1970 00:00:00.
    #$Origin = [datetime]::UnixEpoch
    $Origin = [datetime]::SpecifyKind([datetime]::Parse("1970-01-01T00:00:00"), [System.DateTimeKind]::Utc)
    foreach ($UT in $UnixTime){
        #$TimeZoneToDisplay = LocalTimeZone.DisplayName
        $StandardTime = $Origin.AddSeconds($UT).ToLocalTime()
        Write-Output $StandardTime
    }
}

function ConvertTo-UnixTime{
    param(
        [datetime]$StandardTime
    )

    #This is when unix epoch started - 01 January 1970 00:00:00.
    #$Origin = [datetime]::UnixEpoch
    $Origin = [datetime]::SpecifyKind([datetime]::Parse("1970-01-01T00:00:00"), [System.DateTimeKind]::Utc)
    foreach ($ST in $StandardTime){
        $UnixTime = $ST - $Origin | Select-Object -ExpandProperty TotalSeconds
        Write-Output $UnixTime
    }
}


<# Create an array of objects from a simple array. Each object has only one property $PropertyName (you choose the name).
# For example from the following array "1234" it creates an object like" 
{
"request": {
    "itemid": 1234
},
"type": "6"
}
#>
function ConvertArrayToObjects($PropertyName,$Array){
    $Result = @()
    foreach ($item in $Array){
        $Result += @{"type"="6";
            "request"=[PSCustomObject]@{
                "$PropertyName" = "$item"
            }
        }
    }
    $Result
    return
}



