# String together the Osprey user functions to pull data for a single user
Function Start-OspreyUserInvestigation {
	<#
.SYNOPSIS
	Gathers common data about a provided user.
.DESCRIPTION
	Runs all Osprey users related cmdlets against the specified user and gathers the data.

	Cmdlet								Information Gathered
	-------------------------			-------------------------
	Get-OspreyUserConfiguration           Basic User information
	Get-OspreyUserInboxRule               Searches the user for Inbox Rules
	Get-OspreyUserEmailForwarding         Looks for email forwarding configured on the user
	Get-OspreyUserAutoReply				Looks for enabled AutoReplyConfiguration
	Get-OspreyuserAuthHistory             Searches the unified audit log for users logons
	Get-OspreyUserMailboxAuditing         Searches the unified audit log for mailbox auditing information
	Get-OspreyUserAdminAudit				Searches the EXO Audit logs for any commands that were run against the provided user object.
	Get-OspreyUserMessageTrace			Pulls the email sent by the user in the last 7 days.
.PARAMETER UserPrincipalName
	Single UPN of a user, comma separated list of UPNs, or array of objects that contain UPNs.
.OUTPUTS
	See help from individual cmdlets for output list.
	All outputs are placed in the $Osprey.FilePath directory
.EXAMPLE
	Start-OspreyUserInvestigation -UserPrincipalName bsmith@contoso.com

	Runs all Get-OspreyUser* cmdlets against the user with UPN bsmith@contoso.com
.EXAMPLE

	Start-OspreyUserInvestigation -UserPrincipalName (get-mailbox -Filter {Customattribute1 -eq "C-level"})

	Runs all Get-OspreyUser* cmdlets against all users who have "C-Level" set in CustomAttribute1
#>

	param
	(
		[Parameter(Mandatory = $true)]
		[array]$UserPrincipalName
	)

	Out-LogFile "Investigating Users"
	Send-AIEvent -Event "CmdRun"

	# Verify our UPN input
	[array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

	foreach ($Object in $UserArray) {
		[string]$User = $Object.UserPrincipalName

		Out-LogFile "Running Get-OspreyUserConfiguration" -action
		Get-OspreyUserConfiguration -User $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserInboxRule" -action
		Get-OspreyUserInboxRule -User $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserEmailForwarding" -action
		Get-OspreyUserEmailForwarding -User $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserAutoReply" -action
		Get-OspreyUserAutoReply -User $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserAuthHistory" -action
		Get-OspreyUserAuthHistory -User $user -ResolveIPLocations
		Write-Host "------------------------------------------------"
		
		Out-LogFile "Running Get-OspreyUserEmailActivity" -action
		Get-OspreyUserEmailActivity -User $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserMessageTrace" -action
		Get-OspreyUserMessageTrace -user $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserDevices" -action
		Get-OspreyUserDevices -user $User
		Write-Host "------------------------------------------------"

		Out-LogFile "Running Get-OspreyUserFileAccess" -action
		Get-OspreyUserFileAccess -user $User
		Write-Host "------------------------------------------------"

		Out-LogFile "User investigation complete"
	}
}