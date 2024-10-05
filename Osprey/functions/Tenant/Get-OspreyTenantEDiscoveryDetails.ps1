<#
.DESCRIPTION
    Searches for all roles that have e-discovery cmdlets.
    Searches for all users / groups that have access to those roles.
    Searches the UAL for eDiscovery events
.OUTPUTS
    eDiscoveryRoles.csv / eDiscoveryRoles.xml / eDiscoveryRoles.json
    eDiscoveryRoleAssignments.csv / eDiscoveryRoleAssignments.xml / eDiscoveryRoleAssignments.json
    eDiscoveryLogs.csv
#>
Function Get-OspreyTenantEDiscoveryDetails {

    Test-EXOConnection
    $InformationPreference = "Continue"
    
    Out-LogFile "Gathering Tenant information about eDiscovery Configuration" -action

    # Nulling our our role arrays
    [array]$Roles = $null
    [array]$RoleAssignments = $null

    # Look for E-Discovery Roles and who they might be assigned to
    $EDiscoveryCmdlets = "New-MailboxSearch", "Search-Mailbox"

    # Find any roles that have these critical ediscovery cmdlets in them
    # Bad actors with sufficient rights could have created new roles so we search for them
    Foreach ($cmdlet in $EDiscoveryCmdlets) {
        [array]$Roles = $Roles + (Get-ManagementRoleEntry ("*\" + $cmdlet))
    }

    # Select just the unique entries based on role name
    $UniqueRoles = Select-UniqueObject -ObjectArray $Roles -Property Role

    Out-LogFile ("Found " + $UniqueRoles.count + " Roles with eDiscovery Rights")
    $UniqueRoles | Out-MultipleFileType -FilePrefix "eDiscoveryRoles" -csv -xml -json

    # Get everyone who is assigned one of these roles
    Foreach ($Role in $UniqueRoles) {
        [array]$RoleAssignments = $RoleAssignments + (Get-ManagementRoleAssignment -Role $Role.role -Delegating $false)
    }

    Out-LogFile ("Found " + $RoleAssignments.count + " Role Assignments for these Roles")
    $RoleAssignments | Out-MultipleFileType -FilePreFix "eDiscoveryRoleAssignments" -csv -xml -json

    Out-LogFile "Gathering any eDiscovery logs" -action

    # Search UAL audit logs for any eDiscovery activity
    $eDiscoveryLogs = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -RecordType 'Discovery'")
    # If null we found no changes to nothing to do here
    if ($null -eq $eDiscoveryLogs) {
        Out-LogFile "No eDiscovery Logs found"
    }

    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "eDiscovery Activity has been found! Please review eDiscoveryLogs.csv to validate if the activity is legitimate." -Notice
        # Go thru each even and prepare it to output to CSV
        $eDiscoveryOutput = Foreach ($log in $eDiscoveryLogs) {
            $log1 = $log.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime = $log1.CreationTime
                Id           = $log1.Id
                Name         = $log1.ObjectId
                Operation    = $log1.Operation
                UserID       = $log1.UserID
            }
        }
        $eDiscoveryOutput | Out-MultipleFileType -fileprefix "eDiscoveryLogs" -csv

    }
}