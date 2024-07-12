<#
.DESCRIPTION
    Searches for all roles that have e-discovery cmdlets.
    Searches for all users / groups that have access to those roles.
.OUTPUTS
    eDiscoveryRoles.csv
    eDiscoveryRoles.xml
    eDiscoveryRoles.json
    eDiscoveryRoleAssignments.csv
    eDiscoveryRoleAssignments.xml
    eDiscoveryRoleAssignments.json
#>
Function Get-OspreyTenantEDiscoveryConfiguration {

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    Out-LogFile "Gathering Tenant information about eDiscovery Configuration" -action

    # Nulling our our role arrays
    [array]$Roles = $null
    [array]$RoleAssignements = $null

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
        [array]$RoleAssignements = $RoleAssignements + (Get-ManagementRoleAssignment -Role $Role.role -Delegating $false)
    }

    Out-LogFile ("Found " + $RoleAssignements.count + " Role Assignements for these Roles")
    $RoleAssignements | Out-MultipleFileType -FilePreFix "eDiscoveryRoleAssignments" -csv -xml -json


}