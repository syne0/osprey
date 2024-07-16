<#
.DESCRIPTION
    Searches the Exchange admin audit logs for a number of possible bad actor activities.
    * New/modified/deleted inbox rules
    * Changes to user forwarding configurations
    * Changes to user mailbox permissions
    * Granting of impersonation rights
    * RBAC changes
.OUTPUTS
    New_InboxRules.csv
    Set_InboxRules.csv
    Remove_InboxRules.csv
    Forwarding_Changes.csv
    Impersonation_Roles.csv / Impersonation_Roles.json / Impersonation_Roles.xml
    Impersonation_Rights.csv / Impersonation_Rights.json / Impersonation_Rights.xml
    RBAC_Changes.csv / RBAC_Changes.json / RBAC_Changes.xml
#> 
Function Get-OspreyTenantExchangeLogs {

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    Out-Logfile "Searching Unified Audit Log for Exchange-related activities."

    # Make sure our values are null
    $TenantNewInboxRules = $Null
    $TenantSetInboxRules = $Null
    $TenantRemoveInboxRules = $Null

    Out-LogFile "Searching for ALL Inbox Rules Created, Modified, or Deleted in the last $StartRead days" -action

    ##Search for the creation of ANY inbox rules##

    $TenantNewInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations New-InboxRule")

    # If null we found no rules
    if ($null -eq $TenantNewInboxRules) {
        Out-LogFile "No Inbox Rules created in the last $StartRead days found"
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "New inbox rules have been found" -Notice
        # Go thru each rule and prepare it to output to CSV
        Foreach ($rule in $TenantNewInboxRules) {
            $rule1 = $rule.auditdata | ConvertFrom-Json
            $report = $rule1  | Select-Object -Property CreationTime,
            Id,
            Operation,
            UserID,
            ClientIP,
            @{Name = 'Rule Name'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'Name' }).value } },
            @{Name = 'SentTo'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'SentTo' }).value } },
            @{Name = 'From'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'From' }).value } },
            @{Name = 'FromAddressContains'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'FromAddressContainsWords' }).value } },
            @{Name = 'MoveToFolder'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'MoveToFolder' }).value } },
            @{Name = 'MarkAsRead'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'MarkAsRead' }).value } },
            @{Name = 'DeleteMessage'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'DeleteMessage' }).value } },
            @{Name = 'SubjectContainsWords'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'SubjectContainsWords' }).value } },
            @{Name = 'SubjectOrBodyContainsWords'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'SubjectOrBodyContainsWords' }).value } },
            @{Name = 'ForwardTo'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'ForwardTo' }).value } }

            $report | Out-MultipleFileType -fileprefix "InboxRules_New" -csv -append #-notice ugly

        }
    }

    ##Search for the Modification of ANY inbox rules##

    $TenantSetInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Set-InboxRule")

    # If null we found no rules modified
    if ($null -eq $TenantSetinboxRules) {
        Out-LogFile "No Inbox Rules modified in the last $StartRead days found"
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Modified inbox rules have been found" -Notice
        # Go thru each rule and prepare it to output to CSV
        Foreach ($rule in $TenantSetInboxRules) {
            $rule1 = $rule.auditdata | ConvertFrom-Json
            $report = $rule1  | Select-Object -Property CreationTime,
            Id,
            Operation,
            UserID,
            ClientIP,
            @{Name = 'Rule Name'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'Name' }).value } },
            @{Name = 'SentTo'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'SentTo' }).value } },
            @{Name = 'From'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'From' }).value } },
            @{Name = 'FromAddressContains'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'FromAddressContainsWords' }).value } },
            @{Name = 'MoveToFolder'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'MoveToFolder' }).value } },
            @{Name = 'MarkAsRead'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'MarkAsRead' }).value } },
            @{Name = 'DeleteMessage'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'DeleteMessage' }).value } },
            @{Name = 'SubjectContainsWords'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'SubjectContainsWords' }).value } },
            @{Name = 'SubjectOrBodyContainsWords'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'SubjectOrBodyContainsWords' }).value } },
            @{Name = 'ForwardTo'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'ForwardTo' }).value } }

            $report | Out-MultipleFileType -fileprefix "InboxRules_Set" -csv -append

        }
    }

    ##Search for the deletion of ALL Inbox Rules##

    #This kinda sucks as the remove-inboxrule record doesnt have a lot of information :c
    $TenantRemoveInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Remove-InboxRule")

    if ($null -eq $TenantRemoveinboxRules) {
        Out-LogFile "No Inbox Rules deleted in the last $StartRead days found"
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Deleted inbox rules have been found" -Notice
        # Go thru each rule and prepare it to output to CSV
        Foreach ($rule in $TenantRemoveInboxRules) {
            $rule1 = $rule.auditdata | ConvertFrom-Json
            $report = $rule1  | Select-Object -Property CreationTime, #TODO: fix fix!! also figure out why i needed to fix this lol i dont remember
            Id,
            Operation,
            UserID,
            ClientIP,
            @{Name = 'Identity'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'Identity' }).value } }

            $report | Out-MultipleFileType -fileprefix "InboxRules_Remove" -csv -append

        }
    }

    ##Searching for interesting inbox rules##
    #Deprecating for now until I figure out how to fix this!
    #TODO: Make this work with UAL, but also improve it further to match stuff like suspicious inbox rule names like in the user inbox rule part
    <#
    Out-LogFile "Searching for Interesting Inbox Rules Created in the last $StartRead days" -action

    #[array]$InvestigateInboxRules = Search-AdminAuditLog -StartDate $Osprey.StartDate -EndDate $Osprey.EndDate -cmdlets New-InboxRule -Parameters ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage
    $InvestigateInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations New-InboxRule") #but how pass in attributes that mark as sus?? Well I kno I can use | Where BUT also need to loop? Cant pass | where into Get-AllUnifiedAuditLogEntry

    # if we found a rule report it and output it to the _Investigate files
    if ($InvestigateInboxRules.count -gt 0) {
        Out-LogFile ("Found " + $InvestigateInboxRules.count + " Inbox Rules that should be investigated further.") -notice
        $InvestigateInboxRules | Out-MultipleFileType -fileprefix "_Investigate_New_InboxRules" -xml -txt -Notice
    }
    #>


    ##Look for changes to user forwarding##

    Out-LogFile "Searching for changes to user forwarding" -action
# Getting records from UAL where user forwarding was changed, either enabled or disabled

    $TenantForwardingChanges = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Set-Mailbox -FreeText ForwardingSmtpAddress")
    # If null we found forwarding changes
    if ($null -eq $TenantForwardingChanges) {
        Out-LogFile "No forwarding changes in the last $StartRead days found"
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Forwarding changes have been found" -Notice
        # Go thru each log and prepare it to output to CSV
        Foreach ($log in $TenantForwardingChanges) {
            $log1 = $log.auditdata | ConvertFrom-Json
            $report = $log1  | Select-Object -Property CreationTime,
            Id,
            Operation,
            UserID,
            ClientIP,
            @{Name = 'DeliverToMailboxAndForward'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'DeliverToMailboxAndForward' }).value } },
            @{Name = 'ForwardingSmtpAddress'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'ForwardingSmtpAddress' }).value } }
                
            $report | Out-MultipleFileType -fileprefix "Forwarding_Changes" -csv -append -Notice

        }
    }
    


    ##Look for changes to mailbox permissions##
    #This isnt working properly right now, as system makes too many random changes that throw dozens of false positives
    #TODO: Fix this or remove it

    <#Out-LogFile "Searching for changes to mailbox permissions" -Action
    [array]$TenantMailboxPermissionChanges = Search-AdminAuditLog -StartDate $Osprey.StartDate -EndDate $Osprey.EndDate -cmdlets Add-MailboxPermission
    Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Add-MailboxPermission") -FreeText ForwardingSmtpAddress") #NICE didnt expect that to work!
    if ($TenantMailboxPermissionChanges.count -gt 0) {
        Out-LogFile ("Found " + $TenantMailboxPermissionChanges.count + " changes to mailbox permissions")
        $TenantMailboxPermissionChanges | Out-MultipleFileType -fileprefix "Mailbox_Permission_Changes" -csv -json -xml
    }#>


    ##Look for change to impersonation access##

    Out-LogFile "Searching Impersonation Access" -action
    [array]$TenantImpersonatingRoles = Get-ManagementRoleEntry "*\Impersonate-ExchangeUser"
    $TenantImpersonatingRoles | Out-MultipleFileType -fileprefix "Impersonation_Roles" -csv -json -xml
    if ($TenantImpersonatingRoles.count -gt 1) {
        Out-LogFile ("Found " + $TenantImpersonatingRoles.count + " Impersonation Roles.  Default is 1") -notice
    }

    $Output = $null
    # Search all impersonation roles for users that have access
    foreach ($Role in $TenantImpersonatingRoles) {
        [array]$Output += Get-ManagementRoleAssignment -Role $Role.role -GetEffectiveUsers -Delegating:$false
    }
    $Output | Out-MultipleFileType -fileprefix "Impersonation_Rights" -csv -json -xml
    if ($Output.count -gt 1) {
        Out-LogFile ("Found " + $Output.count + " Users/Groups with Impersonation rights.  Default is 1") -notice
    }
    elseif ($Output.count -eq 1) {
        Out-LogFile ("Found default number of Impersonation users")
    }


    ##Look for any changes to RBAC##

    Out-LogFile "Gathering any changes to RBAC configuration" -action
    $RBACOps = ('Add-ManagementRoleEntry,Add-RoleGroupMember,New-ManagementRole,New-ManagementRoleAssignment,New-ManagementScope,New-RoleAssignmentPolicy,New-RoleGroup,Remove-ManagementRole,Remove-ManagementRoleAssignment,Remove-ManagementRoleEntry,Remove-ManagementScope,Remove-RoleAssignmentPolicy,Remove-RoleGroup,Remove-RoleGroupMember,Set-ManagementRoleAssignment,Set-ManagementRoleEntry,Set-ManagementScope,Set-RoleAssignmentPolicy,Set-RoleGroup,Update-RoleGroupMember')
    [array]$RBACChanges = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -operations $RBACOps")

    # If there are any results push them to an output file
    if ($RBACChanges.Count -gt 0) {
        Out-LogFile ("Found " + $RBACChanges.Count + " Changes made to Roles Based Access Control") -notice
        $RBACChanges | Out-MultipleFileType -FilePrefix "RBAC_Changes" -csv -Notice
        $RBACChanges | Out-MultipleFileType -FilePrefix "RBAC_Changes" -xml -json
    }
    # Otherwise report no results found
    else {
        Out-Logfile "No RBAC Changes found."
    }
}