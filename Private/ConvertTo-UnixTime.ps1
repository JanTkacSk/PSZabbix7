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