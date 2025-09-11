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

    # Get host data
    $HostData = Get-ZXHost -name $HostTemplate -IncludeTags -Includemacros -IncludeParentTemplates -IncludeInterfaces -IncludeHostGroups -InterfaceProperties extend -Output host,name,status,description | ConvertTo-Json -Depth 5 | ConvertFrom-Json -Depth 5

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
    $params = @{
        host        = $HostData.host
        name        = $HostData.name
        status      = $HostData.status
        description = $HostData.description
        macros      = $CleanMacros
        templates   = $HostData.templates
        groups      = $HostData.groups
        interfaces  = $HostData.interfaces
        tags        = $HostData.tags
    }

    return $params
}
