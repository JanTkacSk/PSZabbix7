$ModuleFile = "$PSScriptRoot\..\PSZabbix7.psm1"
$FunctionFiles = Get-ChildItem $PSScriptRoot\..\Public | Select-Object -ExpandProperty FullName
$HelperFunctionFile = Get-Item $PSScriptRoot\..\Private\HelperFunctions.ps1 | Select-Object -ExpandProperty FullName

$ModuleFileContent = ""

$HelperFunctionsContent = Get-Content $HelperFunctionFile | Out-String
$ModuleFileContent += "`n" + $HelperFunctionsContent


foreach ($Function in $FunctionFiles){
    $FunctionContent = Get-Content $Function | Out-String
    $ModuleFileContent += "`n" + $FunctionContent
}

$ModuleFileContent | Out-File $ModuleFile -Force

