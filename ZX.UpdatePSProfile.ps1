If (!(Test-Path $profile)){
    New-Item $profile -Force
}
$Content = Get-Content $Profile | Where-Object {$_ -notmatch "PSZabbix"}
$ModulePath = (get-item -Path $PSScriptRoot\PSZabbix7.psm1).FullName
$FirstLine = "Import-Module $ModulePath"
@($FirstLine) + $Content | Set-Content $PROFILE
$AddedLine = Get-Content $Profile | Where-Object {$_ -eq $FirstLine}
if ($AddedLine -ne $null){
    Write-Host -ForegroundColor Green "PowerShell profile was updated"
}