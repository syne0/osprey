<#
.DESCRIPTION
	Searches the EXO Audit logs for the following commands being run.
	Set-AcceptedDomain
	Add-FederatedDomain
	New-AcceptedDomain
	Update Domain
	Add Verified Domain
	Add Unverified Domain
	Remove Unverified Domain
.OUTPUTS
	Domain_Changes.csv
#> #conf 7/13
Function Get-OspreyTenantDomainActivity {
	
	Test-EXOConnection
	Send-AIEvent -Event "CmdRun"
	$InformationPreference = "Continue"
	Out-LogFile "Gathering any changes to Domain configuration settings" -action

	# Search UAL audit logs for any Domain configuration changes
	$DomainConfigurationEvents = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -RecordType 'AzureActiveDirectory' -Operations 'Update Domain','Add verified domain','Add unverified domain','remove unverified domain'")
	# If null we found no changes to nothing to do here
	if ($null -eq $DomainConfigurationEvents) {
		Out-LogFile "No Domain configuration changes found."
	}
	# If not null then we must have found some events so flag them
	else {
		Out-LogFile "Domain configuration changes found!" -Notice
		Out-LogFile "Please review Domain_Changes.csv to ensure any changes are legitimate." -Notice

		# Go thru each event and prepare it to output to CSV
		Foreach ($event in $DomainConfigurationEvents) {
			$log1 = $event.auditdata | ConvertFrom-Json
			$report = $log1  | Select-Object -Property CreationTime,
			Id,
			Operation,
			UserID,
			@{Name = 'Target'; Expression = { ($_.Target.ID) } }
                
			$report | Out-MultipleFileType -fileprefix "Domain_Changes" -csv -append
				
		}
	}

	Out-LogFile "Completed gathering Domain configuration changes"

}