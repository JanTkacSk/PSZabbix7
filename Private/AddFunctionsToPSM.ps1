$ModuleFile = "$PSScriptRoot\..\PSZabbix7.psm1"
$FunctionFiles = Get-ChildItem $PSScriptRoot\..\Public | Select-Object -ExpandProperty FullName
$ModuleFileContent = ""
foreach ($Function in $FunctionFiles){
    $FunctionContent = Get-Content $Function | Out-String
    $ModuleFileContent += "`n" + $FunctionContent
}

$ModuleFileContent | Out-File $ModuleFile -Force

