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
	$InformationPreference = "Continue"

	#Check Audit Log Config Setting and make sure it is enabled
	Out-LogFile "Gathering Tenant Configuration Information" -action

	Out-LogFile "Gathering Audit Log Configuration"
	Get-AdminAuditLogConfig | Out-MultipleFileType -FilePrefix "AuditLogConfig" -txt -xml

	if (-not (Get-AdminAuditLogConfig).UnifiedAuditLogIngestionEnabled) {
		Out-Logfile "!WARNING! Audit logging is NOT enabled. Post-incident enabling of UAL does not allow visibility into past events." -notice
	}

	Out-LogFile "Getting Organization Configuration"
	Get-OrganizationConfig | Out-MultipleFileType -FilePrefix "OrgConfig" -xml -txt

	Out-LogFile "Getting Remote Domains"
	Get-RemoteDomain | Out-MultipleFileType -FilePrefix "RemoteDomain" -xml -csv -json

	Out-LogFile "Getting Transport Rules"
	$TransportRules = Get-TransportRule
	$TransportRules | Out-MultipleFileType -FilePrefix "TransportRules" -xml -csv -json

	$InvestigateLog = @()
	foreach ($rule in $transportrules) {
		if ($rule.WhenChanged -gt $Osprey.StartDate) {
			$InvestigateLog += $rule #append flagged rules
		}
	}
	if ($InvestigateLog.count -gt 0) {
		Out-Logfile "Found Transport Rules modified during investigation window."
		$InvestigateLog | Out-MultipleFileType -fileprefix "_Investigate_TransportRules" -csv -json -xml -notice
	}

	Out-LogFile "Getting Transport Configuration"
	Get-TransportConfig | Out-MultipleFileType -FilePrefix "TransportConfig" -xml -csv -json
}