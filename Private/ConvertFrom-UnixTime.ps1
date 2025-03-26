function ConvertFrom-UnixTime{
    param(
        [array]$UnixTime
    )
    
    #This is when unix epoch started - 01 January 1970 00:00:00.
    $Origin = [datetime]::UnixEpoch
    foreach ($UT in $UnixTime){
        $StandardTime = $Origin.AddSeconds($UT)
        Write-Output $StandardTime
    }
}