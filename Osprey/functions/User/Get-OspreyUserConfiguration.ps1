<#
.DESCRIPTION
	Gathers and records baseline information about the provided user.
	* Get-EXOMailbox
	* Get-EXOMailboxStatistics
	* Get-EXOMailboxFolderStatistics
	* Get-CASMailbox
	Also gets autoreply and forwarding information.
.OUTPUTS
	Mailbox_Info.txt
	Mailbox_Statistics.txt
	Mailbox_Folder_Statistics.txt
	CAS_Mailbox_Info.txt
	AutoReply.txt
	_Investigate_Users_WithForwarding.csv
	User_ForwardingReport.csv
	ForwardingReport.csv
#>
Function Get-OspreyUserConfiguration {

	param
	(
		[Parameter(Mandatory = $true)]
		[array]$UserPrincipalName
	)

	Test-EXOConnection
	$InformationPreference = "Continue"

	# Verify our UPN input
	[array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

	foreach ($Object in $UserArray) {
		[string]$User = $Object.UserPrincipalName

		Out-LogFile ("Gathering information about " + $User) -action

		#Gather mailbox information
		Out-LogFile "Gathering Mailbox Information"
		$mbx = Get-EXOMailbox -Identity $user 

		# Test to see if we have an archive and include that info as well
		if (!($null -eq $mbx.archivedatabase)) {
			Get-EXOMailboxStatistics -identity $user -Archive | Out-MultipleFileType -FilePrefix "Mailbox_Archive_Statistics" -user $user -txt
		}

		$mbx | Out-MultipleFileType -FilePrefix "Mailbox_Info" -User $User -txt
		Get-EXOMailboxStatistics -Identity $user | Out-MultipleFileType -FilePrefix "Mailbox_Statistics" -User $User -txt
		Get-EXOMailboxFolderStatistics -identity $user | Out-MultipleFileType -FilePrefix "Mailbox_Folder_Statistics" -User $User -txt

		# Gather cas mailbox sessions
		Out-LogFile "Gathering CAS Mailbox Information"
		Get-EXOCasMailbox -identity $user | Out-MultipleFileType -FilePrefix "CAS_Mailbox_Info" -User $User -txt

		##Autoreply##

		# Get Autoreply Configuration
		Out-LogFile ("Retrieving Autoreply Configuration: " + $User) -action
		$AutoReply = Get-MailboxAutoReplyConfiguration -Identity  $User

		# Check if the Autoreply is Disabled
		if ($AutoReply.AutoReplyState -eq 'Disabled') {

			Out-LogFile "AutoReply is not enabled or not configured."
		}
		# Output Enabled AutoReplyConfiguration to a generic txt
		else {

			$AutoReply | Out-MultipleFileType -FilePreFix "AutoReply" -User $user -txt
		}

		##forwarding##
		
		# Looking for email forwarding stored in AD
		Out-LogFile ("Gathering possible Forwarding changes for: " + $User) -action
		$mbx = Get-Mailbox -identity $User

		# Check if forwarding is configured by user or admin
		if ([string]::IsNullOrEmpty($mbx.ForwardingSMTPAddress) -and [string]::IsNullOrEmpty($mbx.ForwardingAddress)) {
			Out-LogFile "No forwarding configuration found"
		}
		# If populated report it and add to a CSV file of positive finds
		else {
			Out-LogFile ("Found Email forwarding User:" + $mbx.primarySMTPAddress + " ForwardingSMTPAddress:" + $mbx.ForwardingSMTPAddress + " ForwardingAddress:" + $mbx.ForwardingAddress) -notice
			$mbx | Select-Object DisplayName, UserPrincipalName, PrimarySMTPAddress, ForwardingSMTPAddress, ForwardingAddress, DeliverToMailboxAndForward, WhenChangedUTC | Out-MultipleFileType -FilePreFix "_Investigate_Users_WithForwarding" -append -csv -json -notice
		}
	}
}
