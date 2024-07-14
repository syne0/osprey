<#
.DESCRIPTION
	Gather basic tenant configuration and saves the output to a text file
	Gathers information about tenant wide settings
	* Audit Log Configuration
	* Organization Configuration
	* Remote domains
	* Transport Rules
	* Transport Configuration
.OUTPUTS
	AuditLogConfig.txt
	AuditLogConfig.xml
	OrgConfig.txt
	OrgConfig.xml
	RemoteDomain.txt
	RemoteDomain.xml
	RemoteDomain.json
	TransportRules.txt
	TransportRules.xml
	TransportRules.json
	TransportConfig.txt
	TransportConfig.xml
	TransportConfig.json
#> #conf 7/13
Function Get-OspreyTenantConfiguration {

	Test-EXOConnection
	Send-AIEvent -Event "CmdRun"
	$InformationPreference = "Continue"

	#Check Audit Log Config Setting and make sure it is enabled
	Out-LogFile "Gathering Tenant Configuration Information" -action

	Out-LogFile "Admin Audit Log"
	Get-AdminAuditLogConfig | Out-MultipleFileType -FilePrefix "AuditLogConfig" -txt -xml

	if (-not (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled) {
		Out-Logfile "!WARNING! Audit logging is NOT enabled. Attempting to enable audit logging now. Osprey results will be limited as UAL was not enabled. Post-incident enabling of UAL does not allow visibility into past events." -notice
		Enable-OrganizationCustomization
		Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
		Out-LogFile "Attempted to enable UAL. Please verify if UAL is enabled and attempt to enable it using a Global Admin account if it's not." -notice
	}

	Out-LogFile "Organization Configuration"
	Get-OrganizationConfig | Out-MultipleFileType -FilePrefix "OrgConfig" -xml -txt

	Out-LogFile "Remote Domains"
	Get-RemoteDomain | Out-MultipleFileType -FilePrefix "RemoteDomain" -xml -csv -json

	Out-LogFile "Transport Rules"
	Get-TransportRule | Format-List | Out-MultipleFileType -FilePrefix "TransportRules" -xml -csv -json

	Out-LogFile "Transport Configuration"
	Get-TransportConfig | Out-MultipleFileType -FilePrefix "TransportConfig" -xml -csv -json
}