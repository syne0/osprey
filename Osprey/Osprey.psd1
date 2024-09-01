@{
	# Script module or binary module file associated with this manifest
	RootModule         = 'Osprey.psm1'
	
	# Version number of this module.
	ModuleVersion      = '1.0.2'
	
	# ID used to uniquely identify this module
	GUID               = '4fe88c1a-f34f-4146-b566-259a7aa73558'
	
	# Author of this module
	Author             = 'Damien Miller-McAndrews'
	
	# Company or vendor of this module
	CompanyName        = 'Leverage Cyber Solutions'
	
	# Copyright statement for this module
	Copyright          = 'Copyright (c) 2024 Damien Miller-McAndrews'
	
	# Description of the functionality provided by this module
	Description        = 'Microsoft 365 Incident Response and Threat Hunting PowerShell tool.
    Osprey is designed to ease the burden on M365 administrators who are performing Cloud forensic tasks for their organization.
    It accelerates the gathering of data from multiple sources in the service that be used to quickly identify malicious presence and activity.'
	
	# Minimum version of the Windows PowerShell engine required by this module
	PowerShellVersion  = '5.0'
	
	# Modules that must be imported into the global environment prior to importing this module
	RequiredModules    = @(
		@{ModuleName = 'PSFramework'; ModuleVersion = '1.9.310' },
		@{ModuleName = 'ExchangeOnlineManagement'; ModuleVersion = '3.4.0' },
		@{ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.19.0' },
		@{ModuleName = 'Microsoft.Graph.Identity.DirectoryManagement'; ModuleVersion = '2.19.0' },
		@{ModuleName = 'Microsoft.Graph.Applications'; ModuleVersion = '2.19.0' },
		@{ModuleName = 'Microsoft.Graph.Users'; ModuleVersion = '2.19.0' }
	)
	
	# Assemblies that must be loaded prior to importing this module
	RequiredAssemblies = @('bin\System.Net.IPNetwork.dll')
	
	# Type files (.ps1xml) to be loaded when importing this module
	# Expensive for import time, no more than one should be used.
	# TypesToProcess = @('xml\Osprey.Types.ps1xml')
	
	# Format files (.ps1xml) to be loaded when importing this module.
	# Expensive for import time, no more than one should be used.
	# FormatsToProcess = @('xml\Osprey.Format.ps1xml')
	
	# Functions to export from this module
	FunctionsToExport  = 'Show-OspreyHelp',
	'Start-Osprey',
	'Update-OspreyModule',
	'Get-OspreyMessageHeader',
	'Get-OspreyTenantConfiguration',
	'Get-OspreyTenantDomainActivity',
	'Get-OspreyTenantEDiscoveryConfiguration',
	'Get-OspreyTenantEDiscoveryLogs',
	'Get-OspreyTenantEntraAdmins',
	'Get-OspreyTenantEntraUsers',
	'Get-OspreyTenantExchangeAdmins',
	'Get-OspreyTenantExchangeLogs',
	'Start-OspreyTenantInvestigation',
	'Get-OspreyTenantAppAndSPNCredentialDetails',
	'Get-OspreyTenantAuthHistory',
	'Get-OspreyTenantInboxRules',
	'Get-OspreyTenantMailItemsAccessed',
	'Search-OspreyTenantActivityByIP',
	'Get-OspreyUserAuthHistory',
	'Get-OspreyUserAutoReply',
	'Get-OspreyUserConfiguration',
	'Get-OspreyUserDevices',
	'Get-OspreyUserEmailActivity',
	'Get-OspreyUserEmailForwarding',
	'Get-OspreyUserInboxRule',
	'Get-OspreyUserMessageTrace',
	'Get-OspreyUserPWNCheck',
	'Start-OspreyUserInvestigation',
	'Get-OspreyUserFileAccess'
	
	# Cmdlets to export from this module
	CmdletsToExport    = ''

	
	# Variables to export from this module
	VariablesToExport  = ''
	
	# Aliases to export from this module
	AliasesToExport    = ''
	
	# List of all files packaged with this module
	FileList           = @()
	
	# Private data to pass to the module specified in ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
	PrivateData        = @{
		
		#Support for PowerShellGet galleries.
		PSData = @{
			
			# Tags applied to this module. These help with module discovery in online galleries.
			Tags         = @('O365', 'Security', 'Audit', 'Breach', 'Investigation', 'Exchange', 'Forensics', 'M365', 'Incident_Response', 'HAWK', 'BEC', 'Business_Email_Compromise')
    
			# A URL to the license for this module.
			LicenseUri   = 'https://github.com/syne0/osprey/blob/master/LICENSE'
    
			# A URL to the main website for this project.
			ProjectUri   = 'https://github.com/syne0/Osprey'
    
			# A URL to an icon representing this module.
			IconUri      = 'https://cybercorner.tech/wp-content/uploads/2024/08/ospreylogo.png'
    
			# ReleaseNotes of this module
			ReleaseNotes = @'
## 1.0.2 (2024-08-31)
- Removed PSAppInsights dependencies and features
- Fixed various bugs found during public testing.
- Removed hidden OOF inbox rule from inbox rule export.
- Transport rules created during investigation period will now flag.

## 1.0.1 (2024-08-16)
- Moved IP lookup API back to IPStack, intention is to eventually allow choice between a few different options.
- Added function Get-OspreyUserFileAccess to get file access and sharing records, and flag suspicious access and anonymous sharing.
- Updated Test-GraphConnection and added to functions it was missing from.

## 1.0.0 (2024-08-15)
- Forked Hawk module, renamed to Osprey.
- Removed JSON and XML export details from appearing in console output.
- Moved JSON output to specific folder.
- Added Start-Osprey function to remove need to connect to EXO and Graph ahead of time, allow for changing investigation parameters or tenant without exiting PowerShell.
- Temporarily deprecated Get-OspreyTenantAppAndSPNCredentialDetails.
- Merged Get-OspreyTenantAzureAppAuditLog and Get-OspreyTenantConsentGrants into one function called Get-OspreyTenantAppsAndConsents.
- Added function to pull list of known suspicious Azure applications from GitHub and flag if any exist in tenant.
- Migrated remaining functions that required deprecated Search-AdminAuditLog command to use output from the UAL, where possible.
- Replaced Azure with Entra, where applicable.
- Added ability for Get-OspreyTenantEntraUsers to get a list of all users created during the investigation period.
- Updated suspicious inbox rule flag to look for rules where emails are redirected into certain known-suspicious folders, or are deleted.
- Moved RBAC obtaining function to Get-ospreyTenantExchangeLogs.
- Moved IPStack API to free alternative temporarily.
- Deprecated Get-OspreyUserAdminAudit as no suitable way to properly migrate to UAL was found.
- Fixed Get-OspreyUserMessageTrace to get 10 days of email instead of 2
- Renamed Get-OspreyUserMobileDevices to Get-OspreyUserDevices and added ability to get Entra joined/registered devices and flag any recently added.
- Attempted to fix Get-OspreyUserEmailActivity. It sort of works but outputs into different CSVs for each activity.
- Moved majority of outputs that did appending into PSCustomObjects to reduce console output noise.
- Removed Get-OspreyUserHiddenRule as -Hidden flag is available in normal Get-InboxRule command.
- Updated Premium license detection to add additional SKUs
- Removed Known Microsoft IP check due to issues, will bring it back eventually.
'@
			
		} # End of PSData hashtable
		
	} # End of PrivateData hashtable
}
