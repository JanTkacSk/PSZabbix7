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

$ModuleFileContent | Out-File $ModuleFile -Force

