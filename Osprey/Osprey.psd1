@{
    # Script module or binary module file associated with this manifest
    RootModule         = 'Osprey.psm1'

    # Version number of this module.
    ModuleVersion      = '1.0.0'

    # ID used to uniquely identify this module
    GUID               = '1f6b6b91-79c4-4edf-83a1-66d2dc8c3d85'

    # Author of this module
    Author             = 'Damien Miller-McAndrews'

    # Company or vendor of this module
    CompanyName        = 'Cloud Forensicator'

    # Copyright statement for this module
    Copyright          = 'Copyright (c) 2024 Damien Miller-McAndrews'

    # Description of the functionality provided by this module
    Description        = 'Microsoft 365 Incident Response and Threat Hunting PowerShell tool.
	The Osprey is designed to ease the burden on M365 administrators who are performing Cloud forensic tasks for their organization.
	It accelerates the gathering of data from multiple sources in the service that be used to quickly identify malicious presence and activity.'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion  = '5.0'

    # Modules that must be imported into the global environment prior to importing
    # this module
    RequiredModules    = @(
        @{ModuleName = 'PSFramework'; ModuleVersion = '1.4.150' },
        @{ModuleName = 'PSAppInsights'; ModuleVersion = '0.9.6' },
        @{ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.0.0' },
        @{ModuleName = 'RobustCloudCommand'; ModuleVersion = '2.0.1' },
        @{ModuleName = 'AzureAD'; ModuleVersion = '2.0.2.140' },
        @{ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '1.23.0' },
        @{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion = '1.23.0' }
    )

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @('bin\System.Net.IPNetwork.dll')

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @('xml\Osprey.Types.ps1xml')

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @('xml\Osprey.Format.ps1xml')

    # Functions to export from this module
    FunctionsToExport  =
    'Get-OspreyTenantConfiguration',
    'Get-OspreyTenantEDiscoveryConfiguration',
    'Get-OspreyTenantInboxRules',
    'Get-OspreyTenantConsentGrants',
    'Get-OspreyTenantRBACChanges',
    'Get-OspreyTenantAzureAuditLog',
    'Get-OspreyUserAuthHistory',
    'Get-OspreyUserConfiguration',
    'Get-OspreyUserEmailForwarding',
    'Get-OspreyUserInboxRule',
    'Get-OspreyUserMailboxAuditing',
    'Initialize-OspreyGlobalObject',
    'Search-OspreyTenantActivityByIP',
    'Search-OspreyTenantEXOAuditLog',
    'Show-OspreyHelp',
    'Start-OspreyTenantInvestigation',
    'Start-OspreyUserInvestigation',
    'Update-OspreyModule',
    'Get-OspreyUserAdminAudit',
    'Get-OspreyTenantAuthHistory',
    'Get-OspreyUserHiddenRule',
    'Get-OspreyMessageHeader',
    'Get-OspreyUserPWNCheck',
    'Get-OspreyUserAutoReply',
    'Get-OspreyUserMessageTrace',
    'Get-OspreyUserMobileDevice',
    'Get-OspreyTenantAZAdmins',
    'Get-OspreyTenantEXOAdmins',
    'Get-OspreyTenantMailItemsAccessed',
    'Get-OspreyTenantAppAndSPNCredentialDetails',
    'Get-OspreyTenantAzureADUsers',
    'Get-OspreyTenantDomainActivity',
    'Get-OspreyTenantEDiscoveryLogs'

    # Cmdlets to export from this module
    # CmdletsToExport = ''

    # Variables to export from this module
    # VariablesToExport = ''

    # Aliases to export from this module
    # AliasesToExport = ''

    # List of all modules packaged with this module
    ModuleList         = @()

    # List of all files packaged with this module
    FileList           = @()

    # Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData        = @{

        #Support for PowerShellGet galleries.
        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @("O365", "Security", "Audit", "Breach", "Investigation", "Exchange", "EXO", "Compliance", "Logon", "M365", "Incident-Response", "Solarigate")

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/T0pCyber/Osprey/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/T0pCyber/Osprey'

            # A URL to an icon representing this module.
            IconUri      = 'https://i.ibb.co/XXH4500/Osprey.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/T0pCyber/Osprey/Osprey/changelog.md'

        } # End of PSData hashtable

    } # End of PrivateData hashtable
} Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        # Tags = @("O365","Security","Audit","Breach","Investigation","Exchange","EXO","Compliance","Logon","M365","Incident-Response","Solarigate","HAWK")

        # A URL to the license for this module.
        # LicenseUri = 'https://github.com/syne0/Osprey/LICENSE'

        # A URL to the main website for this project.
        # ProjectUri = 'https://github.com/syne0/Osprey'

        # A URL to an icon representing this module.
        # IconUri = 'https://cybercorner.tech/osprey.png'

        # ReleaseNotes of this module
        # ReleaseNotes = 'https://github.com/syne0/Osprey/Osprey/changelog.md'

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

