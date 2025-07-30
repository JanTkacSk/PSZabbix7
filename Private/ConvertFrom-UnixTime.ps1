function ConvertFrom-UnixTime{
    param(
        [array]$UnixTime
    )
    
    # Get the local time zone info
    #$LocalTimeZone = [System.TimeZoneInfo]::Local
    #This is when unix epoch started - 01 January 1970 00:00:00.
    $Origin = [datetime]::UnixEpoch
    foreach ($UT in $UnixTime){
        #$TimeZoneToDisplay = LocalTimeZone.DisplayName
        $StandardTime = $Origin.AddSeconds($UT).ToLocalTime()
        Write-Output $StandardTime
    }
}