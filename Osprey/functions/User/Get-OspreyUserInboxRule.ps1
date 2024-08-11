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
#>
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
        #setting the log value back to null
        $InvestigateLog = @()
        [string]$User = $Object.UserPrincipalName

        # Get Inbox rules
        Out-LogFile ("Gathering Inbox Rules: " + $User) -action
        $InboxRules = Get-InboxRule -mailbox  $User
        
        #if we found no rules
        if ($null -eq $InboxRules) { Out-LogFile "No Inbox Rules found" }
        #if we found rules
        else {
            #export report of all properties for all rules in inbox
            $InboxRules | Out-MultipleFileType -FilePreFix "InboxRules" -User $user -csv -json 

            $InboxRules | Out-MultipleFileType -FilePreFix "All_UserInboxRules" -csv -json -append 

            #also get a simpler report with only certain properties and export that
            $SimpleInboxRules = $InboxRules | Select-Object Enabled, Name, RuleIdentity, From, DeleteMessage, MarkAsRead, MoveToFolder, ForwardTo, ForwardAsAttachmentTo, RedirectTo, SubjectContainsWords, SubjectOrBodyContainsWords
            $SimpleInboxRules | Out-MultipleFileType -FilePreFix "Simple_InboxRules" -User $user -csv

            #then for each rule we check for investigate rules
            foreach ($Rule in $SimpleInboxRules) {
                $Investigate = $false #reset var

                # Evaluate each of the properties that we know bad actors like to use and flip the flag if needed
                if ($rule.DeleteMessage -eq $true) { $Investigate = $true }
                if (!([string]::IsNullOrEmpty($rule.ForwardAsAttachmentTo))) { $Investigate = $true }
                if (!([string]::IsNullOrEmpty($rule.ForwardTo))) { $Investigate = $true }
                if (!([string]::IsNullOrEmpty($rule.RedirectTo))) { $Investigate = $true }
                if ($rule.MoveToFolder -in "Archive", "Conversation History", "RSS Subscription") { $Investigate = $true }
                
                #if we found some investigate rules, let the user know
                if ($Investigate -eq $true) {
                    $InvestigateLog += $rule
                    Out-LogFile ("Possible Investigate inbox rule found! ID:" + $rule.RuleIdentity + " Rule Name:" + $Rule.Name) -notice
                }
            }
            #if we have some in the log, output it
            if ($null -ne $InvestigateLog) {
                $InvestigateLog | Out-MultipleFileType -fileprefix "_Investigate_InboxRules" -csv -notice
            }
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
