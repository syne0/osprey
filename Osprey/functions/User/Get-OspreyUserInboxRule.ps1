﻿# Gets user inbox rules and looks for Investigate rules
<#
.DESCRIPTION
    Gathers inbox rules and sweep rules for the provided users.
    Looks for rules that forward,delete, or redirect email to specific sus folders and flags them.
.OUTPUTS
    _Investigate_InboxRules.csv
    InboxRules.csv
    All_InboxRules.csv
    SweepRules.csv
    All_SweepRules.csv
#>  #conf 7/13
Function Get-OspreyUserInboxRule {

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

        # Get Inbox rules
        Out-LogFile ("Gathering Inbox Rules: " + $User) -action
        $InboxRules = Get-InboxRule -mailbox  $User

        if ($null -eq $InboxRules) { Out-LogFile "No Inbox Rules found" }
        else {
            # If the rules contains one of a number of known suspicious properties flag them
            foreach ($Rule in $InboxRules) {
                # Set our flag to false
                $Investigate = $false

                # Evaluate each of the properties that we know bad actors like to use and flip the flag if needed
                if ($Rule.DeleteMessage -eq $true) { $Investigate = $true }
                if (!([string]::IsNullOrEmpty($Rule.ForwardAsAttachmentTo))) { $Investigate = $true }
                if (!([string]::IsNullOrEmpty($Rule.ForwardTo))) { $Investigate = $true }
                if (!([string]::IsNullOrEmpty($Rule.RedirectTo))) { $Investigate = $true }
                if ($Rule.MoveToFolder -in "Archive", "Conversation History", "RSS Subscription") { $Investigate = $true }

                # If we have set the Investigate flag then report it and output it to a separate file
                if ($Investigate -eq $true) {
                    Out-LogFile ("Possible Investigate inbox rule found ID:" + $Rule.Identity + " Rule:" + $Rule.Name) -notice
                    # Description is multiline
                    $Rule.Description = $Rule.Description.replace("`r`n", " ").replace("`t", "")
                    $Rule | Out-MultipleFileType -FilePreFix "_Investigate_InboxRules" -user $user -csv -json -append -Notice
                }
            }

            # Description is multiline
            $inboxrulesRawDescription = $InboxRules
            $InboxRules = New-Object -TypeName "System.Collections.ArrayList"

            $inboxrulesRawDescription | ForEach-Object {
                $_.Description = $_.Description.Replace("`r`n", " ").replace("`t", "")

                $null = $InboxRules.Add($_)
            }

            # Output all of the inbox rules to a generic csv
            $InboxRules | Out-MultipleFileType -FilePreFix "InboxRules" -User $user -csv -json

            # Add all of the inbox rules to a generic collection file
            $InboxRules | Out-MultipleFileType -FilePrefix "All_InboxRules" -csv -json -Append
        }

        # Get any Sweep Rules
        # Suggested by Adonis Sardinas
        Out-LogFile ("Gathering Sweep Rules: " + $User) -action
        $SweepRules = Get-SweepRule -Mailbox $User

        if ($null -eq $SweepRules) { Out-LogFile "No Sweep Rules found" }
        else {

            # Output all rules to a user CSV
            $SweepRules | Out-MultipleFileType -FilePreFix "SweepRules" -user $User -csv -json

            # Add any found to the whole tenant list
            $SweepRules | Out-MultipleFileType -FilePreFix "All_SweepRules" -csv -json -append

        }
    }
}
