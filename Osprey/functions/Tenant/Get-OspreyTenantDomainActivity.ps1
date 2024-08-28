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
#>
Function Get-OspreyTenantDomainActivity {
	
	Test-EXOConnection
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
		Out-LogFile "Domain configuration changes found! Please review Domain_Changes.csv to ensure any changes are legitimate." -Notice

		# Go thru each event and prepare it to output to CSV
		$DomainChangesReport = Foreach ($log in $DomainConfigurationEvents) {
			$log1 = $log.auditdata | ConvertFrom-Json
			[PSCustomObject]@{
			CreationTime = $log1.CreationTime 
			Id = $log1.Id 
			Operation = $log1.Operation
			UserID = $log1.UserId 
			Domain = $log1.Target | Select-Object -ExpandProperty ID
			}
				
		}
		$DomainChangesReport | Out-MultipleFileType -fileprefix "Domain_Changes" -csv
	}

}