<#
.DESCRIPTION
    After connecting to Exchange Online, this script will enumerate Exchange Online
    role group members and export the results to a .CSV file. Reviewing EXO admins can assist with determining
    who can change Exchange Online configurations.
.OUTPUTS
    ExchangeAdmins.csv
#> #conf 7/13
Function Get-OspreyTenantExchangeAdmins {
    
        Out-LogFile "Gathering Exchange Online Administrators"
        Test-EXOConnection
        Send-AIEvent -Event "CmdRun"

        $roles = foreach ($Role in Get-RoleGroup) {
            $ExchangeAdmins = Get-RoleGroupMember -Identity $Role.Identity | Select-Object -Property *
            foreach ($admin in $ExchangeAdmins) {
                if ([string]::IsNullOrWhiteSpace($admin.WindowsLiveId)) {
                    [PSCustomObject]@{
                        ExchangeAdminGroup = $Role.Name
                        Members            = $admin.DisplayName
                        RecipientType      = $admin.RecipientType
                    }
                }
                else {
                    [PSCustomObject]@{
                        ExchangeAdminGroup = $Role.Name
                        Members            = $admin.WindowsLiveId
                        RecipientType      = $admin.RecipientType
                    }
                }
            }
        }
        $roles | Out-MultipleFileType -FilePrefix "ExchangeAdmins" -csv

        Out-Logfile "Completed exporting Exchange Online Admins"
}
