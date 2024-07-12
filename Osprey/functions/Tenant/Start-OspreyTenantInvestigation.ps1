<#
.DESCRIPTION
	Runs all Osprey Basic tenant related cmdlets and gathers the data.
.OUTPUTS
	See help from individual cmdlets for output list.
	All outputs are placed in the $Osprey.FilePath directory
#> 
Function Start-OspreyTenantInvestigation {

	if ([string]::IsNullOrEmpty($Osprey.FilePath)) {
		Out-LogFile "You need to initialize Osprey first. Running Start-Osprey. Tenant investigation will continue after initialization is finished." -action
		Start-Osprey
	}

	Out-LogFile "Starting Tenant Sweep" -action
	Send-AIEvent -Event "CmdRun"

	Out-LogFile "Running Get-OspreyTenantConfiguration" -action
	Get-OspreyTenantConfiguration

	Out-LogFile "Running Get-OspreyTenantEDiscoveryConfiguration" -action
	Get-OspreyTenantEDiscoveryConfiguration

	Out-LogFile "Running Get-OspreyTenantEDiscoveryLogs"
	Get-OspreyTenantEDiscoveryLogs -action

	Out-LogFile "Running Get-OspreyTenantExchangeLogs" -action 
	Get-OspreyTenantExchangeLogs

	Out-LogFile "Running Get-OspreyTenantDomainActivity" -action 
	Get-OspreyTenantDomainActivity

	Out-LogFile "Running Get-OspreyTenantAppsAndConsents" -action
	Get-OspreyTenantAppsAndConsents

	Out-LogFile "Running Get-OspreyTenantExchangeAdmins" -action
	Get-OspreyTenantExchangeAdmins

	Out-LogFile "Running Get-OspreyTenantEntraAdmins" -action
	Get-OspreyTenantEntraAdmins

	Out-Logfile "Running Get-OspreyTenantEntraUsers" -action
	Get-OspreyTenantEntraUsers

	Out-LogFile "Tenant Investigation complete. You can now run Start-OspreyUserInvestigation."
}