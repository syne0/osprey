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

    Get-MgUser -all -Property UserPrincipalName, DisplayName, UserType, CreatedDateTime, AccountEnabled, Id, Mail, LastPasswordChangeDateTime | select-object UserPrincipalName, DisplayName, UserType, CreatedDateTime, AccountEnabled, Id, Mail, LastPasswordChangeDateTime | Out-MultipleFileType -fileprefix "EntraIDUsers" -csv #good enough
    
    Out-Logfile "Completed exporting Entra ID users"
}