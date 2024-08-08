﻿<#
.DESCRIPTION
Pulls the values of ForwardingSMTPAddress and ForwardingAddress to see if the user has these configured.
.OUTPUTS
File: _Investigate_Users_WithForwarding.csv
File: User_ForwardingReport.csv
File: ForwardingReport.csv
#>  #conf 7/13
Function Get-OspreyUserEmailForwarding {

    param
    (
        [Parameter(Mandatory = $true)]
        [array]$UserPrincipalName
    )

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    # Verify our UPN input
    [array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

    foreach ($Object in $UserArray) {

        [string]$User = $Object.UserPrincipalName

        # Looking for email forwarding stored in AD
        Out-LogFile ("Gathering possible Forwarding changes for: " + $User) -action
        Out-LogFile "Collecting AD Forwarding Settings" -action
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

        # Add all users searched to a generic output
        $mbx | Select-Object DisplayName, UserPrincipalName, PrimarySMTPAddress, ForwardingSMTPAddress, ForwardingAddress, DeliverToMailboxAndForward, WhenChangedUTC | Out-MultipleFileType -FilePreFix "User_ForwardingReport" -append -csv -json
        # Also add to an output specific to this user
        $mbx | Select-Object DisplayName, UserPrincipalName, PrimarySMTPAddress, ForwardingSMTPAddress, ForwardingAddress, DeliverToMailboxAndForward, WhenChangedUTC | Out-MultipleFileType -FilePreFix "ForwardingReport" -user $user -csv -json

    }
}