<#
.DESCRIPTION
    This function will export all the Azure Active Directory users to .csv file. It will also get all user creation
    activity during the investigation period from the UAL.
.OUTPUTS
    EntraIDUsers.csv
    New_Users.csv
#>
Function Get-OspreyTenantEntraUsers {
    
    Test-GraphConnection
    $InformationPreference = "Continue"
    Send-AIEvent -Event "CmdRun"
    
    Out-LogFile "Gathering Entra ID Users"

    #Obtaining all users in the tenant and outputting details to a csv
    $TenantUsers = Get-MgUser -all -Property UserPrincipalName, DisplayName, UserType, CreatedDateTime, AccountEnabled, Id, Mail, LastPasswordChangeDateTime | select-object UserPrincipalName, DisplayName, UserType, CreatedDateTime, AccountEnabled, Id, Mail, LastPasswordChangeDateTime
    $TenantUsers | Out-MultipleFileType -fileprefix "EntraIDUsers" -csv

    Out-Logfile "Completed exporting Entra ID users"

    #Getting all user creation events from the investigation period and exporting to a CSV
    $UserCreations = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -Operation 'Add user.'")

    if ($null -eq $UserCreations) {
        Out-LogFile "No user creation activity found"
    }
    # If not null then we must have found some events so flag them
    else {
        Out-Logfile "User creation activity found"
        $UserCreationReport = foreach ($log in $UserCreations) {
            $log1 = $log.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime = $log1 | Select-Object -ExpandProperty CreationTime
                Id           = $log1 | Select-Object -ExpandProperty Id
                Operation    = $log1 | Select-Object -ExpandProperty Operation
                UserID       = $log1 | Select-Object -ExpandProperty UserID
                UserAdded    = $log1 | Select-Object -ExpandProperty ObjectId
            }
        }
        $UserCreationReport | Out-MultipleFileType -fileprefix "New_Users" -csv
    }
}