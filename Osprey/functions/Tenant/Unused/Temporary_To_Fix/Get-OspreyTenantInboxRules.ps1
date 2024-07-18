Function Get-OspreyTenantInboxRules {
    <#
.DESCRIPTION
    Uses Start-RobustCloudCommand to gather data from each mailbox in the org.
    Gathers inbox rules with Get-OspreyUserInboxRule
    Gathers forwarding with Get-OspreyUserEmailForwarding
.OUTPUTS
    All_Mailboxes.csv / All_Mailboxes.json
    Outputs any user email rules, suspicious email rules, or forwarding changes to the User's folder in the Osprey folder.
#>
    param (
        [string]$UserPrincipalName
    )

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    # Prompt the user that this is going to take a long time to run
    $title = "Long Running Command"
    $message = "Running this search can take a very long time to complete (~1min per user). `nDo you wish to continue?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Continue operation"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Exit Cmdlet"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    # If yes log and continue
    # If no log error and exit
    switch ($result) {
        0 { Out-LogFile "Starting full Tenant Search" }
        1 { Write-Error -Message "User Stopped Cmdlet" -ErrorAction Stop }
    }

    $AllMailboxes = Get-Recipient -RecipientTypeDetails UserMailbox -ResultSize Unlimited | Select-Object -Property DisplayName, PrimarySMTPAddress 
    $Allmailboxes | Out-MultipleFileType -FilePrefix "All_Mailboxes" -csv -json
    
    # Report how many mailboxes we are going to operate on
    Out-LogFile ("Found " + $AllMailboxes.count + " Mailboxes")

    foreach ($mailbox in $AllMailboxes) {
        Get-OspreyUserInboxRule -UserPrincipalName $mailbox.PrimarySMTPAddress
        Get-OspreuUserEmailForwarding -UserPrincipalName $mailbox.PrimarySMTPAddress
    }

}