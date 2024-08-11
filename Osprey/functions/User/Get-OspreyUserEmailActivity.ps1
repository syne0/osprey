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

        ##Searching for Update records##
        #These records will show what emails a threat actor may have accessed

        Out-LogFile "Searching Unified Audit Log for Update events."
        $UALUpdateRecords = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -UserIDs " + $User + " -RecordType ExchangeItem -operation update")
            
        if ($null -eq $UALUpdateRecords) {
            Out-LogFile "No Update activity found."
        }
        # If not null then we must have found some events so export them
        else {
            Out-LogFile ("Found " + $UALUpdateRecords.Count + " email Update records") 

            #build custom object out of UAL records to get the most important information
            $UpdateReport = Foreach ($record in $UALUpdateRecords) {
                $record1 = $record.auditdata | ConvertFrom-Json
                [PSCustomObject]@{
                    CreationTime      = $record1.CreationTime
                    RecordId          = $record1.Id
                    Operation         = $record1.Operation
                    UserID            = $record1.UserID
                    ClientIP          = $record1.ClientIP
                    Subject           = $record1.Item | Select-Object -ExpandProperty Subject
                    ParentFolder      = $record1.Item | Select-Object -ExpandProperty ParentFolder  | Select-object -expandproperty Path
                    Attachments       = $record1.Item | Select-Object Attachments | Select-object -expandproperty Attachments
                    InternetMessageId = $record1.Item | Select-Object -ExpandProperty InternetMessageId
                    Id                = $record1.Item | Select-Object -ExpandProperty Id
                }
            }
            #output the object
            $UpdateReport | Out-MultipleFileType -FilePrefix "Email_Update_Records" -User $user -csv -json -xml
        }

        ##Searching for Delete records##
        Out-LogFile "Searching Unified Audit Log for Delete events."
        $UALDeleteRecords = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -UserIDs " + $User + " -RecordType ExchangeItemGroup")

        if ($null -eq $UALDeleteRecords) {
            Out-LogFile "No Delete activity found."
        }
        else {
            Out-LogFile ("Found " + $UALDeleteRecords.Count + " email Delete records")

            #build custom object out of UAL records to get the most important information
            #this is a bit screwy right now due to the occasional multiple records returned in one record. will fix eventually.
            $DeleteReport = Foreach ($record in $UALDeleteRecords) {
                $record1 = $record.auditdata | ConvertFrom-Json
                [PSCustomObject]@{
                    CreationTime = $record1.CreationTime
                    RecordId     = $record1.Id
                    Operation    = $record1.Operation
                    UserID       = $record1.UserID
                    ClientIP     = $record1.ClientIP
                    Subject      = $record1.AffectedItems | Select-object Subject | Select-object -expandproperty subject
                    Folder       = $record1.AffectedItems | Select-Object -ExpandProperty ParentFolder  | Select-object -expandproperty Path
                }
            }
            #output the object
            $DeleteReport | Out-MultipleFileType -FilePrefix "Email_Delete_Records" -User $user -csv -json -xml
        }

        ##Searching for Create records##
        Out-LogFile "Searching Unified Audit Log for Create events."
        $UALCreateRecords = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -UserIDs " + $User + " -RecordType ExchangeItem -operation create")
            
        if ($null -eq $UALCreateRecords) {
            Out-LogFile "No Create activity found."
        }
        # If not null then we must have found some events so export them
        else {
            Out-LogFile ("Found " + $UALCreateRecords.Count + " email Create records") 

            #build custom object out of UAL records to get the most important information
            $CreateReport = Foreach ($record in $UALCreateRecords) {
                $record1 = $record.auditdata | ConvertFrom-Json
                [PSCustomObject]@{
                    CreationTime      = $record1.CreationTime
                    RecordId          = $record1.Id
                    Operation         = $record1.Operation
                    UserID            = $record1.UserID
                    ClientIP          = $record1.ClientIP
                    Subject           = $record1.Item | Select-Object -ExpandProperty Subject
                    ParentFolder      = $record1.Item | Select-Object -ExpandProperty ParentFolder  | Select-object -expandproperty Path
                    InternetMessageId = $record1.Item | Select-Object -ExpandProperty InternetMessageId
                    Id                = $record1.Item | Select-Object -ExpandProperty Id
                }
            }
            #output the object
            $CreateReport | Out-MultipleFileType -FilePrefix "Email_Create_Records" -User $user -csv -json -xml
        }

    }
}

