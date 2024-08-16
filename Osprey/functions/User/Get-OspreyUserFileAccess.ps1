function Get-OspreyUserFileAccess {
    <#
.DESCRIPTION
    Pulls SharePoint and OneDrive Related Activity. Also flags any records that contain access to files with
    potentially sensitive information.
.PARAMETER UserPrincipalName
    Single UPN of a user, comma separated list of UPNs, or array of objects that contain UPNs.
.OUTPUTS
    File_Access_Audit.csv
    _Investigate_Sensitive_File_Access.csv
    .EXAMPLE
    Get-OspreyUserFileAccess -UserPrincipalName user@contoso.com
    Search for all file access logs from user@contoso.com
    .EXAMPLE
    Get-OspreyUserFileAccess -UserPrincipalName (get-mailbox -Filter {Customattribute1 -eq "C-level"})
    Search for all file access logs for all users who have "C-Level" set in CustomAttribute1
#>
    param
    (
        [Parameter(Mandatory = $true)]
        [array]$UserPrincipalName
    )

    Test-EXOConnection

    # Verify our UPN input
    [array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

    foreach ($Object in $UserArray) {
        [string]$User = $Object.UserPrincipalName

        ##Search for file access records##

        Out-LogFile ("Attempting to Gather File Access Activity for user " + $User) -action

        #UAL search for specific operations
        $FileAccessRecords = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -UserIDs " + $User + " -Operations 'FileAccessed','FileDownloaded','FileModified','FileModifiedExtended','FilePreviewed','FileUploaded','FolderCreated','FolderModified'")

        #If we found nothing
        if ($null -eq $FileAccessRecords) {
            Out-LogFile "No File Access activity found."
        }
        else {
            #if we found something
            Out-LogFile ("Found " + $FileAccessRecords.Count + " file access records") 
            #Create a custom object of what we found
            $FileReport = foreach ($record in $FileAccessRecords) {
                $record1 = $record.auditdata | ConvertFrom-Json
                [PSCustomObject]@{
                    CreationTime = $record1.CreationTime
                    RecordId     = $record1.Id
                    Operation    = $record1.Operation
                    Workload     = $record1.Workload
                    UserID       = $record1.UserID
                    ClientIP     = $record1.ClientIP
                    ItemType     = $record1.ItemType
                    FileName     = $record1.SourceFileName
                    SiteURL      = $record1.SiteURL
                    FullURL      = $record1.ObjectID
                    Application  = $record1.ApplicationDisplayName
                }
            }
            #output it
            $FileReport | Out-MultipleFileType -FilePrefix "FileAccessRecords" -User $user -csv -json -xml

            #investigate records for any that are suspicious

            $InvestigateLog = @() #set empty array
            Foreach ($file in $FileReport) {
                #for each record in the report
                $Investigate = $false #set flag back to false
                
                #see if the filename matches specific keywords
                #this is insanely ugly but it's the best way i can find to do this in a way that properly matches stuff
                if ($file.FileName -like "*credit*" -or $file.FileName -like "*visa*" -or $file.FileName -like "*debit*" -or $file.FileName -like "*passport*" -or $file.FileName -like "*license*" -or $file.FileName -like "*SSN*" -or $file.FileName -like "*SIN*" -or $file.FileName -like "*password*" -or $file.FileName -like "*login*" -or $file.FileName -like "*invoice*" -or $file.FileName -like "*collection*" -or $file.FileName -like "*receivable*"  ) { $investigate = $true }
                
                #if it does, add it into the log array
                if ($Investigate) {
                    $InvestigateLog += $file
                }
            }
            #If our count of records in the array are equal to or greater than 1
            if ($InvestigateLog.count -ge 1) { 
                #say we found something and output the file
                Out-LogFile ("Access to potentially sensitive files found! Please review access to determine if legitimate.") -notice
                $InvestigateLog | Out-MultipleFileType -fileprefix "_Investigate_FileAccess" -User $user -csv -notice
            }

            ##Looking for file sharing activity##

            Out-LogFile ("Attempting to Gather Sharing Activity for user " + $User) -action

            #UAL search for Sharepoint sharing operations
            $AllSharingRecords = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -UserIDs " + $User + " -RecordType SharePointSharingOperation")
            
            #grab anonymous records in array so I can count it
            $AnonymousSharingRecords = @($AllSharingRecords | Where-Object { $_.Operations -eq "AnonymousLinkCreated" })

            if ($null -eq $AnonymousSharingRecords) {
                Out-LogFile "No File Access activity found."
            }
            else {
                #if we found something
                Out-LogFile ("Found " + $AnonymousSharingRecords.count + " anonymous links") 
                #Create a custom object of what we found
                $AnonReport = foreach ($record in $AnonymousSharingRecords) {
                    $record1 = $record.auditdata | ConvertFrom-Json
                    [PSCustomObject]@{
                        CreationTime = $record1.CreationTime
                        RecordId     = $record1.Id
                        Operation    = $record1.Operation
                        Workload     = $record1.Workload
                        UserID       = $record1.UserID
                        ClientIP     = $record1.ClientIP
                        ItemType     = $record1.ItemType
                        FileName     = $record1.SourceFileName
                        SiteURL      = $record1.SiteURL
                        FullURL      = $record1.ObjectID
                        EventData    = $record1.EventData
                    }
                }
                #output it
                $AnonReport | Out-MultipleFileType -FilePrefix "_Investigate_Anonymous_Links" -User $user -csv -notice
            }

            #Exporting all sharing records as well
            $AllSharingRecords.AuditData | ConvertFrom-Json | Out-MultipleFileType -FilePrefix "All_Sharing_Activity" -User $user -csv -json -xml
        }
    }
}