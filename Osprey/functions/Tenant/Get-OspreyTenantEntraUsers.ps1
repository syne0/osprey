<#
.DESCRIPTION
    This function will export all the Azure Active Directory users to .csv file. It will also get all user creation
    activity during the investigation period from the UAL.
.OUTPUTS
    EntraIDUsers.csv
    New_Users.csv
#>
Function Get-OspreyTenantEntraUsers {
    
    Out-LogFile "Gathering Entra ID Users"
    Send-AIEvent -Event "CmdRun"

    #Obtaining all users in the tenant and outputting details to a csv
    $TenantUsers = Get-MgUser -all -Property UserPrincipalName,DisplayName,UserType,CreatedDateTime,AccountEnabled,Id,Mail,LastPasswordChangeDateTime | select-object UserPrincipalName,DisplayName,UserType,CreatedDateTime,AccountEnabled,Id,Mail,LastPasswordChangeDateTime
    $TenantUsers | Out-MultipleFileType -fileprefix "EntraIDUsers" -csv

    Out-Logfile "Completed exporting Entra ID users"

    #Getting all user creation events from the investigation period and exporting to a CSV
    $UserCreationLog = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operation 'Add user.'")

    if ($null -eq $UserCreationLog) {
        Out-LogFile "No user creation activity found"
    }
    # If not null then we must have found some events so flag them
    else {
        foreach ($log in $UserCreationLog) {
            $log1 = $log.auditdata | ConvertFrom-Json
            $report = $log1 | Select-Object -Property CreationTime,
            Id,
            Operation,
            UserID,
            @{Name = 'User Added'; Expression = { ($_.Target[3].ID) } }

            $report | Out-MultipleFileType -fileprefix "New_Users" -csv -append 
        }
    }

}