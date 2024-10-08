﻿Function Get-OspreyUserMessageTrace {
    <#
.SYNOPSIS
    Pull that last 10 days of message trace data for the specified user.
.DESCRIPTION
        Pulls the basic message trace data for the specified user.
        Can only pull the last 10 days as that is all we keep in get-messagetrace

        Further investigation will require Start-HistoricalSearch
.PARAMETER UserPrincipalName
Single UPN of a user, comma separated list of UPNs, or array of objects that contain UPNs.
.OUTPUTS

    File: Message_Trace.csv
    Path: \<User>
    Description: Output of Get-MessageTrace -Sender <primarysmtpaddress>
.EXAMPLE

    Get-OspreyUserMessageTrace -UserPrincipalName user@contoso.com

    Gets the message trace for user@contoso.com for the last 7 days
#>

    param
    (
        [Parameter(Mandatory = $true)]
        [array]$UserPrincipalName
    )

    Test-EXOConnection
    $InformationPreference = "Continue"

    # Verify our UPN input
    [array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

    [DateTime]$MTEndDate = Get-Date
    [DateTime]$MTStartDate = ((Get-Date).AddDays(-10)).Date
    # Gather the trace
    foreach ($Object in $UserArray) {

        [string]$User = $Object.UserPrincipalName

        [string]$PrimarySMTP = (Get-Mailbox -identity $User).primarysmtpaddress

        if ([string]::IsNullOrEmpty($PrimarySMTP)) {
            Out-LogFile ("[ERROR] - Failed to find Primary SMTP Address for user: " + $User)
            Write-Error ("Failed to find Primary SMTP Address for user: " + $User)
        }
        else {
            # Get the 7 day message trace for the primary SMTP address as the sender
            Out-LogFile ("Gathering messages sent by:$PrimarySMTP in the last 10 days") -action

            (Get-MessageTrace -SenderAddress $PrimarySMTP -StartDate $MTStartDate -EndDate $MTEndDate) | Out-MultipleFileType -FilePreFix "Sent_MessageTrace" -user $User -csv -json
        }
    }
}
