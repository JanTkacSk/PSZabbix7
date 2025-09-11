function Copy-ZXHostParameters {
    param (
        [Parameter(Mandatory=$true)]
        [string]$name,

        [Parameter(Mandatory=$true)]
        [string]$HostTemplate,

        [string]$NewAlias,
        [string]$NewIp,
        [string]$NewDns
    )

    # Get host data
    $HostData = Get-ZXHost -name $HostTemplate -IncludeTags -IncludeMacros -IncludeParentTemplates -IncludeInterfaces -IncludeHostGroups -InterfaceProperties extend | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5

    if(!$HostData){
        Write-Host -ForegroundColor Yellow "Sample host not found, use a name that exactly matches the host name"
        return
    }

    # Remove unwanted properties
    $HostData.PSObject.Properties.Remove("hostid")
    $HostData.groups | ForEach-Object { $_.PSObject.Properties.Remove("name") }
    $HostData.parentTemplates | ForEach-Object { $_.PSObject.Properties.Remove("name") }
    $HostData.interfaces | ForEach-Object {
        $_.PSObject.Properties.Remove("available")
        $_.PSObject.Properties.Remove("error")
        $_.PSObject.Properties.Remove("errors_from")
        $_.PSObject.Properties.Remove("disable_until")
    }

    # Clean up macros: keep only macro and value
    $CleanMacros = @()
    foreach ($macro in $HostData.macros) {
        $CleanMacros += @{
            Macro = $Macro.macro
            value = $Macro.value
        }
    }

    # Rename ParentTemplates to templates
    $HostData | Add-Member -MemberType NoteProperty -Name templates -Value $HostData.parentTemplates
    $HostData.PSObject.Properties.Remove("parentTemplates")

    # Replace host and name
    $HostData.host = $name
    $HostData.name = if ($NewAlias) { $NewAlias } else { $name }

    # Update IP and DNS if provided
    if ($NewIp) { $HostData.interfaces[0].ip = $NewIp }
    if ($NewDns) { $HostData.interfaces[0].dns = $NewDns }

    # Final params object for API call
    $params = @{
        host       = $HostData.host
        name       = $HostData.name
        status     = $HostData.status
        macros     = $CleanMacros
        templates  = $HostData.templates
        groups     = $HostData.groups
        interfaces = $HostData.interfaces
        tags       = $HostData.tags
    }

    return $params
}
