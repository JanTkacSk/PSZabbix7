function Copy-ZXHostParameters {
    param (
        [Parameter(Mandatory=$true)]
        [string]$NewName,

        [Parameter(Mandatory=$true)]
        [string]$HostTemplate,

        [string]$NewAlias,
        [string]$NewDescription,
        [string]$NewIp,
        [string]$NewDns
    )

    # Define read-only properties
    $readOnlyProps = @(
        "hostid", "flags", "maintenanceid", "maintenance_status", "maintenance_type",
        "maintenance_from", "active_available", "assigned_proxyid", "templateid", "uuid",
        "vendor_name", "vendor_version", "proxy_groupid"
    )

    # Get host data
    $HostData = Get-ZXHost -name $HostTemplate -IncludeTags -Includemacros -IncludeParentTemplates -IncludeInterfaces -IncludeHostGroups -InterfaceProperties extend -Output extend | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5

    if (!$HostData) {
        Write-Host -ForegroundColor Yellow "Sample host not found, use a name that exactly matches the host name"
        return
    }

    # Remove read-only properties
    foreach ($prop in $readOnlyProps) {
        $HostData.PSObject.Properties.Remove($prop)
    }

    # Clean up nested properties
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
    foreach ($Macro in $HostData.macros) {
        $CleanMacros += @{
            macro = $Macro.macro
            value = $Macro.value
        }
    }

    # Rename ParentTemplates to templates
    $HostData | Add-Member -MemberType NoteProperty -Name templates -Value $HostData.parentTemplates
    $HostData.PSObject.Properties.Remove("parentTemplates")

    # Replace host and name
    $HostData.host = $NewName
    $HostData.name = if ($NewAlias) { $NewAlias } else { $NewName }

    # Update IP and DNS if provided
    if ($NewDns) { $HostData.interfaces[0].dns = $NewDns }
    if ($NewIp) { $HostData.interfaces[0].ip = $NewIp }
    if ($NewDescription) { $HostData.description = $NewDescription }

    # Final params object for API call
    $HostData.macros = $CleanMacros
    $params = $HostData

    return $params
}
