@{
    # Script module or binary module file associated with this manifest
    RootModule = 'PSZabbix-7.psm1'

    # Version number of this module.
    ModuleVersion = '0.0.3'

    # ID used to uniquely identify this module
    GUID = 'd3e66cb0-4c68-4f07-9d70-b92a15a26c7a'

    # Author of this module
    Author = 'Jan Tkac'

    # Company or vendor of this module
    CompanyName = 'Jan Tkac'

    # Copyright statement for this module
    Copyright = '(c) 2025 Jan Tkac. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for managing Zabbix via API.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport = '*'

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module
    AliasesToExport = '*'

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Zabbix', 'API', 'Monitoring')

            # ReleaseNotes of this module
            ReleaseNotes = 'Refactioring Get-ZXTemplate, Get-ZXTrigger, Get-ZXTriggerPrototype.'
        }
    }
}
