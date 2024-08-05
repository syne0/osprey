<#
.DESCRIPTION
    Searches the Exchange admin audit logs for a number of possible bad actor activities.
    * New/modified/deleted inbox rules
    * Changes to user forwarding configurations
    * Changes to user mailbox permissions
    * Granting of impersonation rights
    * RBAC changes
.OUTPUTS
    New_Inboxrule.csv
    _Investigate_New_Inboxrule
    Set_InboxRule.csv
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

    Out-LogFile "Searching for ALL Inbox Rules Created, Modified, or Deleted during the investigation period." -action

    ##Search for the creation of ANY inbox rules##

    $TenantNewInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations New-InboxRule")

    # If null we found no rules
    if ($null -eq $TenantNewInboxRules) {
        Out-LogFile "No Inbox Rules created during the investigation period found."
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "New inbox rules have been found" -Notice
        # Go thru each rule and prepare it to output to CSV

        $NewRuleReport = foreach ($rule in $TenantNewInboxRules) {
            #throwing all new inbox rules created into custom object
            $rule1 = $rule.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime               = $rule1 | Select-Object -ExpandProperty CreationTime
                Id                         = $rule1 | Select-Object -ExpandProperty id
                Operation                  = $rule1 | Select-Object -ExpandProperty Operation
                UserID                     = $rule1 | Select-Object -ExpandProperty UserID
                ClientIP                   = $rule1 | Select-Object -ExpandProperty ClientIP
                RuleName                   = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq name | Select-Object -expandproperty value
                SentTo                     = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq SentTo | Select-Object -expandproperty value
                RecievedFrom               = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq From | Select-Object -expandproperty value
                FromAddressContains        = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq FromAddressContains | Select-Object -expandproperty value
                MoveToFolder               = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq MoveToFolder | Select-Object -expandproperty value
                MarkAsRead                 = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq MarkAsRead | Select-Object -expandproperty value
                DeleteMessage              = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq DeleteMessage | Select-Object -expandproperty value
                SubjectContainsWords       = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq SubjectContainsWords | Select-Object -expandproperty value
                SubjectOrBodyContainsWords = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq SubjectOrBodyContainsWords | Select-Object -expandproperty value
                ForwardTo                  = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq ForwardTo | Select-Object -expandproperty value
            }
        }
        $NewRuleReport | Out-MultipleFileType -fileprefix "New_InboxRule" -csv
        $InvestigateNewInboxRule = @()
        Foreach ($rule in $NewRuleReport) {

            $Investigate = $false
            if ($rule.DeleteMessage -eq $true) { $Investigate = $true }
            if (!([string]::IsNullOrEmpty($rule.ForwardAsAttachmentTo))) { $Investigate = $true }
            if (!([string]::IsNullOrEmpty($rule.ForwardTo))) { $Investigate = $true }
            if (!([string]::IsNullOrEmpty($rule.RedirectTo))) { $Investigate = $true }
            if ($rule.MoveToFolder -in "Archive", "Conversation History", "RSS Subscription") { $Investigate = $true }
            
            if ($Investigate -eq $true) {
                $InvestigateNewInboxRule += $rule
                Out-LogFile ("Possible Investigate inbox rule found! ID:" + $rule.Id) -notice
                $InvestigateNewInboxRule | Out-MultipleFileType -fileprefix "_Investigate_New_InboxRule" -csv
            }
        }
    }


    ##Search for the Modification of ANY inbox rules##

    $TenantSetInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Set-InboxRule")

    # If null we found no rules modified
    if ($null -eq $TenantSetinboxRules) {
        Out-LogFile "No Inbox Rules modified during the investigation period found."
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Modified inbox rules have been found"
        # Go thru each rule and prepare it to output to CSV

        $SetRuleReport = foreach ($rule in $TenantSetInboxRules) {
            #throwing all edited inbox rules created into custom object
            $rule1 = $rule.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime               = $rule1 | Select-Object -ExpandProperty CreationTime
                Id                         = $rule1 | Select-Object -ExpandProperty id
                Operation                  = $rule1 | Select-Object -ExpandProperty Operation
                UserID                     = $rule1 | Select-Object -ExpandProperty UserID
                ClientIP                   = $rule1 | Select-Object -ExpandProperty ClientIP
                RuleName                   = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq name | Select-Object -expandproperty value
                SentTo                     = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq SentTo | Select-Object -expandproperty value
                RecievedFrom               = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq From | Select-Object -expandproperty value
                FromAddressContains        = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq FromAddressContains | Select-Object -expandproperty value
                MoveToFolder               = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq MoveToFolder | Select-Object -expandproperty value
                MarkAsRead                 = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq MarkAsRead | Select-Object -expandproperty value
                DeleteMessage              = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq DeleteMessage | Select-Object -expandproperty value
                SubjectContainsWords       = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq SubjectContainsWords | Select-Object -expandproperty value
                SubjectOrBodyContainsWords = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq SubjectOrBodyContainsWords | Select-Object -expandproperty value
                ForwardTo                  = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq ForwardTo | Select-Object -expandproperty value
            }
        }
        $SetRuleReport | Out-MultipleFileType -fileprefix "Set_InboxRule" -csv
    }

    ##Search for the deletion of ALL Inbox Rules##

    #This kinda sucks as the remove-inboxrule record doesnt have a lot of information :c
    $TenantRemoveInboxRules = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Remove-InboxRule")

    if ($null -eq $TenantRemoveinboxRules) {
        Out-LogFile "No Inbox Rules deleted during the investigation period found."
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Deleted inbox rules have been found"
        # Go thru each rule and prepare it to output to CSV

        $RemoveRuleReport = foreach ($rule in $TenantRemoveInboxRules) {
            #throwing all new inbox rules created into custom object
            $rule1 = $rule.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime = $rule1 | Select-Object -ExpandProperty CreationTime
                Id           = $rule1 | Select-Object -ExpandProperty id
                Operation    = $rule1 | Select-Object -ExpandProperty Operation
                UserID       = $rule1 | Select-Object -ExpandProperty UserID
                ClientIP     = $rule1 | Select-Object -ExpandProperty ClientIP
                Identity     = $rule1 | Select-object -ExpandProperty Parameters | Where-Object name -eq Identity | Select-Object -expandproperty value
            }
        }
        $RemoveRuleReport | Out-MultipleFileType -fileprefix "Remove_InboxRule" -csv
    }


    ##Look for changes to user forwarding##

    Out-LogFile "Searching for changes to user forwarding" -action
    # Getting records from UAL where user forwarding was changed, either enabled or disabled

    $TenantForwardingChanges = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Set-Mailbox -FreeText ForwardingSmtpAddress")
    # If null we found forwarding changes
    if ($null -eq $TenantForwardingChanges) {
        Out-LogFile "No forwarding changes during the investigation period found."
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Forwarding changes have been found"
        # Go thru each log and prepare it to output to CSV
        $ForwardingChangeReport = Foreach ($log in $TenantForwardingChanges) {
            $log1 = $log.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime      = $log1 | Select-Object -ExpandProperty CreationTime
                Id                = $log1 | Select-Object -ExpandProperty id
                Operation         = $log1 | Select-Object -ExpandProperty Operation
                UserID            = $log1 | Select-Object -ExpandProperty UserID
                ClientIP          = $log1 | Select-Object -ExpandProperty ClientIP
                ForwardingStatus  = $log1 | Select-object -ExpandProperty Parameters | Where-Object name -eq DeliverToMailboxAndForward | Select-Object -expandproperty value
                ForwardingAddress = $log1 | Select-object -ExpandProperty Parameters | Where-Object name -eq ForwardingSmtpAddress | Select-Object -expandproperty value
            }
        }
    }
    $ForwardingChangeReport | Out-MultipleFileType -fileprefix "Forwarding_Changes" -csv


    ##Look for changes to mailbox permissions##

    Out-LogFile "Searching for changes to mailbox permissions" -Action
    $TenantMailboxPermissionChanges = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operations Add-MailboxPermission")

    if ($null -eq $TenantMailboxPermissionChanges) {
        Out-LogFile "No permission changes during the investigation period found."
    }
    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Mailbox permission changes have been found. Please review non-system changes. Note: target and user with permission details are via ID."
        # Go thru each log and prepare it to output to CSV
        Foreach ($change in $TenantMailboxPermissionChanges) {
            $change1 = $change.auditdata | ConvertFrom-Json
            $report = $change1  | Select-Object -Property CreationTime,
            Id,
            Operation,
            UserID,
            ClientIP,
            @{Name = 'Target ID'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'User' }).value } },
            @{Name = 'User with Access ID'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'Identity' }).value } },
            @{Name = 'Access Rights'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'AccessRights' }).value } }
                
            $report | Out-MultipleFileType -fileprefix "Mailbox_Permission_Changes" -csv -append

        }
    }


    ##Looking for changes to impersonation access##

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
        $RBACChanges | Out-MultipleFileType -FilePrefix "RBAC_Changes" -csv -xml -json
    }
    # Otherwise report no results found
    else {
        Out-Logfile "No RBAC Changes found."
    }
}