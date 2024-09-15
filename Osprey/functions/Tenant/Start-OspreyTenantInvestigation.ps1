<#
.DESCRIPTION
	Runs all Osprey Basic tenant related cmdlets and gathers the data.
.OUTPUTS
	See help from individual cmdlets for output list.
	All outputs are placed in the $Osprey.FilePath directory
#> #conf 7/13
Function Start-OspreyTenantInvestigation {

	if ([string]::IsNullOrEmpty($Osprey.FilePath)) {
		Out-LogFile "You need to initialize Osprey first. Running Start-Osprey. Tenant investigation will continue after initialization is finished." -action
		Start-Osprey
	}

	Out-LogFile "Starting Tenant Sweep" -action

	Out-LogFile "Running Get-OspreyTenantConfiguration" -action
	Get-OspreyTenantConfiguration
	Write-Host "------------------------------------------------"

	Out-LogFile "Running Get-OspreyTenantEDiscoveryConfiguration" -action
	Get-OspreyTenantEDiscoveryConfiguration
	Write-Host "------------------------------------------------"

	Out-LogFile "Running Get-OspreyTenantEDiscoveryLogs"
	Get-OspreyTenantEDiscoveryLogs -action
	Write-Host "------------------------------------------------"

	Out-LogFile "Running Get-OspreyTenantExchangeLogs" -action 
	Get-OspreyTenantExchangeLogs
	Write-Host "------------------------------------------------"

	Out-LogFile "Running Get-OspreyTenantDomainActivity" -action 
	Get-OspreyTenantDomainActivity
	Write-Host "------------------------------------------------"

	Out-LogFile "Running Get-OspreyTenantAppsAndConsents" -action
	Get-OspreyTenantAppsAndConsents
	Write-Host "------------------------------------------------"

	Out-LogFile "Running Get-OspreyTenantLinkUsage" -action
	Get-OspreyTenantLinkUsage
	Write-Host "------------------------------------------------"
	
	Out-LogFile "Running Get-OspreyTenantAdmins" -action
	Get-OspreyTenantAdmins
	Write-Host "------------------------------------------------"

	Out-Logfile "Running Get-OspreyTenantEntraUsers" -action
	Get-OspreyTenantEntraUsers
	Write-Host "------------------------------------------------"

	Out-LogFile "Tenant Investigation complete. You can now run Start-OspreyUserInvestigation."
}