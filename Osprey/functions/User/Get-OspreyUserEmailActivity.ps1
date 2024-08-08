function Get-OspreyUserEmailActivity {
    <#
.DESCRIPTION
    Pulls email-related activity (Update, Delete, Send) for a user from the UAL. Does NOT pull MailItemsAccessed record.
.PARAMETER UserPrincipalName
    Single UPN of a user, comma separated list of UPNs, or array of objects that contain UPNs.
.OUTPUTS

    File: Exchange_UAL_Audit.csv
    Path: \<User>
    Description: All Exchange related audit events found in the Unified Audit Log.

    File: Exchange_Mailbox_Audit.csv
    Path: \<User>
    Description: All Exchange related audit events found in the Mailbox Audit Log.
    .EXAMPLE

    Get-OspreyUserMailboxAuditing -UserPrincipalName user@contoso.com

    Search for all Mailbox Audit logs from user@contoso.com
    .EXAMPLE

    Get-OspreyUserMailboxAuditing -UserPrincipalName (get-mailbox -Filter {Customattribute1 -eq "C-level"})

    Search for all Mailbox Audit logs for all users who have "C-Level" set in CustomAttribute1
#>

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

        Out-LogFile ("Attempting to Gather Email Activity from the UAL for " + $User) -action

        # Test if mailbox auditing is enabled
        $mbx = Get-Mailbox -identity $User
        if ($mbx.AuditEnabled -eq $true) {
            # if enabled pull the mailbox auditing from the unified audit logs
            Out-LogFile "Searching Unified Audit Log for Exchange Related Events"

            $UALExchangeItemRecords = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -UserIDs " + $User + " -RecordType ExchangeItem -operation update")
            
            if ($null -eq $UALExchangeItemRecords) {
                Out-LogFile "No Exchange activity found."
            }
            # If not null then we must have found some events so flag them
            else {
                Out-LogFile ("Found " + $UALExchangeItemRecords.Count + " Exchange audit records.") 
                
                #TODO: fix this all asap next
                #Issue: for this i need to extract stuff from Item in some records, but i cant do it like with the inbox rules or apps
                #since it seems that it's just a bunch of string data
                Foreach ($record in $UALExchangeItemRecords) {
                    $record1 = $record.auditdata | ConvertFrom-Json
                    $report = $record1  | Select-Object -Property CreationTime,
                    Id,
                    Operation,
                    UserID,
                    ClientIP,
                    @{Name = 'thing'; Expression = { ($_.Item) } }

                    $report 
                    # | Out-MultipleFileType -fileprefix "ExchangeItems" -csv -append temp comment out for testing
        
                }
            }
            # Output the data we found
            $UnifiedAuditLogs | Out-MultipleFileType -FilePrefix "Exchange_UAL_Audit" -User $User -csv -json

            # Search the MailboxAuditLogs as well since they may have different/more information
            Out-LogFile "Searching Exchange Mailbox Audit Logs (this can take some time)"

            $MailboxAuditLogs = Get-MailboxAuditLogsFiveDaysAtATime -StartDate $Osprey.StartDate -EndDate $Osprey.EndDate -User $User
            Out-LogFile ("Found " + $MailboxAuditLogs.Count + " Exchange Mailbox audit records.")

            # Output the data we found
            $MailboxAuditLogs | Out-MultipleFileType -FilePrefix "Exchange_Mailbox_Audit" -User $User -csv -json

        }
        # If auditing is not enabled log it and move on
        else {
            Out-LogFile ("Auditing not enabled for " + $User)
        }
    }
}
