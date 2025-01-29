$Functions = Get-ChildItem $PSScriptRoot\Public | Select-Object -ExpandProperty FullName

foreach ($Function in $Functions){
    . $Function
}