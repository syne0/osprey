<#
.DESCRIPTION
	Gathers and records baseline information about the provided user.
	* Get-EXOMailbox
	* Get-EXOMailboxStatistics
	* Get-EXOMailboxFolderStatistics
	* Get-CASMailbox
.OUTPUTS
	Mailbox_Info.txt
	Mailbox_Statistics.txt
	Mailbox_Folder_Statistics.txt
	CAS_Mailbox_Info.txt
#>  #conf 7/13
Function Get-OspreyUserConfiguration {

	param
	(
		[Parameter(Mandatory = $true)]
		[array]$UserPrincipalName
	)

	Test-EXOConnection
	Send-AIEvent -Event "CmdRun"
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
	}
}
