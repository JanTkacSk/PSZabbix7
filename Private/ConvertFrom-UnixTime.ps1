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