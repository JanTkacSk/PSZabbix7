$ModuleFile = "$PSScriptRoot\..\PSZabbix7.psm1"
$FunctionFiles = Get-ChildItem $PSScriptRoot\..\Public | Select-Object -ExpandProperty FullName
$PrivateFunctionFile = Get-Item $PSScriptRoot\..\Private\PrivateFunctions.ps1 | Select-Object -ExpandProperty FullName

$ModuleFileContent = ""

$PrivateFunctionsContent = Get-Content $PrivateFunctionFile | Out-String
$ModuleFileContent += "`n" + $PrivateFunctionsContent

$ModuleFileContent += "# -----------Public Functions---------- #"


foreach ($Function in $FunctionFiles){
    $FunctionContent = Get-Content $Function | Out-String
    $ModuleFileContent += "`n" + $FunctionContent
}

$ModuleFileContent += 'Export-ModuleMember -Function `
    Add-ZXHostGroup, `
    Add-ZXHostNameSuffix, `
    Add-ZXHostTag, `
    Copy-ZXHostParameters, `
    Disable-ZXTrigger, `
    Enable-ZXTrigger, `
    Get-ZXAction, `
    Get-ZXAlert, `
    Get-ZXApiVersion, `
    Get-ZXAuditLog, `
    Get-ZXDiscoveryRule, `
    Get-ZXEvent, `
    Get-ZXHistory, `
    Get-ZXHost, `
    Get-ZXHostGroup, `
    Get-ZXHostInterface, `
    Get-ZXItem, `
    Get-ZXItemPrototype, `
    Get-ZXMaintenance, `
    Get-ZXProblem, `
    Get-ZXProxy, `
    Get-ZXService, `
    GEt-ZXSession, `
    Get-ZXTemplate, `
    Get-ZXTrigger, `
    Get-ZXTriggerPrototype, `
    Invoke-ZXTask, `
    New-ZXHost, `
    New-ZXProblemTagList, `
    New-ZXService, `
    New-ZXTagFilter, `
    New-ZXTagList, `
    New-ZXTokenSession, `
    Remove-ZXDiscoveryRule, `
    Remove-ZXHost, `
    Remove-ZXHostGroup, `
    Remove-ZXHostNameSuffix, `
    Remove-ZXHostTag, `
    Remove-ZXItem, `
    Remove-ZXMaintenance, `
    Remove-ZXTrigger, `
    Remove-ZXTriggerPrototype, `
    Set-ZXHostLetterCase, `
    Set-ZXHostName, `
    Set-ZXHostStatus, `
    Stop-ZXSession, `
    Update-ZXHostTagList, `
    Update-ZXHostTemplateList, `
    Update-ZXMaintenance, `
    Update-ZXService'


$ModuleFileContent | Out-File $ModuleFile -Force

