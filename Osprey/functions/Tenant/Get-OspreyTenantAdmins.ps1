<#
.DESCRIPTION
    Exports administrators via Entra and Exchange.
.OUTPUTS
    EntraIDAdministrators.csv
    EntraIDAdministrators.json
    ExchangeAdmins.csv
#>
Function Get-OspreyTenantAdmins {

    Test-EXOConnection
    Test-GraphConnection
    $InformationPreference = "Continue"

    ##Getting Entra Admins##

    Out-LogFile "Gathering Entra ID Administrators"

    #Foreach directory admin role
    $rolesENT = foreach ($role in Get-MgDirectoryRole) {
        $adminsENT = (Get-MgDirectoryRoleMemberAsUser -DirectoryRoleId $role.Id).userprincipalname #get any accounts that is a member
        if ([string]::IsNullOrWhiteSpace($adminsENT)) {
            #if no members were found
            [PSCustomObject]@{
                AdminGroupName = $role.DisplayName
                Members        = "No Members"
            }
        }
        foreach ($admin in $adminsENT) {
            #if a member was found
            [PSCustomObject]@{
                AdminGroupName = $role.DisplayName
                Members        = $admin
            }
        }
    }
    $rolesENT | Out-MultipleFileType -FilePrefix "EntraIDAdmins" -csv -json #export it

    <#
    #filter out the no members member, then select unique members
    $admins2ENT = $rolesENT | Where-Object -property members -notMatch "No Members" | Select-Object -unique -property Members

    #put member names into a variable
    $AllAdmins += $admins2ENT.members
    #>

    Out-LogFile "Completed exporting Entra ID Administrators"

    Out-LogFile "Gathering Exchange Online Administrators"

    #Foreach exchange admin role
    $rolesEXO = foreach ($Role in Get-RoleGroup) {
        $AdminsEXO = Get-RoleGroupMember -Identity $Role.Identity | Select-Object -Property * #get members
        foreach ($admin in $AdminsEXO) {
            if ([string]::IsNullOrWhiteSpace($admin.WindowsLiveId)) {
                #if no windows live ID property
                [PSCustomObject]@{
                    ExchangeAdminGroup = $Role.Name
                    Members            = $admin.DisplayName
                    RecipientType      = $admin.RecipientType
                }
            }
            else {
                [PSCustomObject]@{ #if windowsliveid property exists
                    ExchangeAdminGroup = $Role.Name
                    Members            = $admin.WindowsLiveId
                    RecipientType      = $admin.RecipientType
                }
            }
        }
    }
    $rolesEXO | Out-MultipleFileType -FilePrefix "ExchangeAdmins" -csv #export

    Out-Logfile "Completed exporting Exchange Online Administrators"

    <# failure
    #get all actual accounts that arent just groups, then select unique
    $admins2EXO = $rolesEXO | Where-Object -property RecipientType -Match "UserMailbox" | Select-Object -unique -property Members

    #throw into the admins variable
    $AllAdmins += $admins2EXO.members

    #remove any duplicates
    $AllAdmins = $AllAdmins | Select-Object -unique

    ##Checking for new admins##
    $InvestigateLog = @()
    foreach ($user in $AllAdmins) {
        Get-mguser -userid $user
        if ((get-mguser -userid $user) )
    }
#>
}
