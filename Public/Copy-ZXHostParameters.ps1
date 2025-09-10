function Copy-ZXHostParameters {
    param (
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$true)]
        [string]$sampleHost,

        [string]$alias,
        [string]$newIp,
        [string]$newDns
    )

    # Get host data
    $hostData = Get-ZXHost -name $sampleHost -IncludeTags -IncludeMacros -IncludeParentTemplates -IncludeInterfaces -IncludeHostGroups -InterfaceProperties extend | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5

    if(!$hostData){
        Write-Host -ForegroundColor Yellow "Sample host not found, use a name that exactly matches the host name"
        return
    }

    # Remove unwanted properties
    $hostData.PSObject.Properties.Remove("hostid")
    $hostData.groups | ForEach-Object { $_.PSObject.Properties.Remove("name") }
    $hostData.parentTemplates | ForEach-Object { $_.PSObject.Properties.Remove("name") }
    $hostData.interfaces | ForEach-Object {
        $_.PSObject.Properties.Remove("available")
        $_.PSObject.Properties.Remove("error")
        $_.PSObject.Properties.Remove("errors_from")
        $_.PSObject.Properties.Remove("disable_until")
    }

    # Clean up macros: keep only macro and value
    $cleanMacros = @()
    foreach ($macro in $hostData.macros) {
        $cleanMacros += @{
            macro = $macro.macro
            value = $macro.value
        }
    }

    # Rename ParentTemplates to templates
    $hostData | Add-Member -MemberType NoteProperty -Name templates -Value $hostData.parentTemplates
    $hostData.PSObject.Properties.Remove("parentTemplates")

    # Replace host and name
    $hostData.host = $name
    $hostData.name = if ($alias) { $alias } else { $name }

    # Update IP and DNS if provided
    if ($newIp) { $hostData.interfaces[0].ip = $newIp }
    if ($newDns) { $hostData.interfaces[0].dns = $newDns }

    # Final params object for API call
    $params = @{
        host       = $hostData.host
        name       = $hostData.name
        status     = $hostData.status
        macros     = $cleanMacros
        templates  = $hostData.templates
        groups     = $hostData.groups
        interfaces = $hostData.interfaces
        tags       = $hostData.tags
    }

    return $params
}
