function ConvertTo-UnixTime{
    param(
        [datetime]$StandardTime
    )

    #This is when unix epoch started - 01 January 1970 00:00:00.
    $Origin = [datetime]::UnixEpoch
    foreach ($ST in $StandardTime){
        $UnixTime = $ST - $Origin | Select-Object -ExpandProperty TotalSeconds
        Write-Output $UnixTime
    }
}