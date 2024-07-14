<#
.DESCRIPTION
    This function will export all the Azure Active Directory users to .csv file. This data can be used
    as a reference for user presence and details about the user for additional context at a later time. This is a point
    in time users enumeration. Date created can be of help when determining account creation date.
.OUTPUTS
    EntraIDUsers.csv
#>
Function Get-OspreyTenantEntraUsers {
    
    Out-LogFile "Gathering Entra ID Users"
    Send-AIEvent -Event "CmdRun"

    Get-MgUser -all -Property UserPrincipalName, DisplayName, UserType, CreatedDateTime, AccountEnabled, Id, Mail, LastPasswordChangeDateTime | select-object UserPrincipalName, DisplayName, UserType, CreatedDateTime, AccountEnabled, Id, Mail, LastPasswordChangeDateTime | Out-MultipleFileType -fileprefix "EntraIDUsers" -csv
    #TODO: If admin comp, mark list of users created during investigate period as needing further investigation.
    #also more can be done with this probably.
    Out-Logfile "Completed exporting Entra ID users"
}