# Changelog
## 1.0.2 (2024-08-31)
- Removed PSAppInsights dependencies and features.
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
