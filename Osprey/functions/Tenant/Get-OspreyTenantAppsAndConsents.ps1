<#
.DESCRIPTION
	Gathers application consents from the investigation period. Also gathers list of all applications, their permissions, and compares that list to a hardcoded list
    of known-suspicious applications.

.OUTPUTS
    Entra_App_Consents.csv
    Entra_App_Consents.json
    Suspicious_App_List.txt
    Tenant_Applications.csv
    Tenant_Applications.json
#> #conf 7/13
Function Get-OspreyTenantAppsAndConsents {
    
    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"
    $InformationPreference = "Continue"

    # Make sure our variables are null
    $AzureApplicationActivityEvents = $null
    $MatchingApps = $null

    ##Search the unified audit log for events related to application activity##
    Out-LogFile "Searching Unified Audit Log for application-related activitied in Entra." -Action

    $AzureApplicationActivityEvents = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -RecordType 'AzureActiveDirectory' -Operations 'Add OAuth2PermissionGrant.','Consent to application.' ")

    # If null we found no changes to nothing to do here
    if ($null -eq $AzureApplicationActivityEvents) {
        Out-LogFile "No Application related events found in the search time frame."
    }

    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Application consent activity found. Please review Entra_App_Consents.csv to ensure any changes are legitimate."
        Foreach ($event in $AzureApplicationActivityEvents) {
            $report = $event.auditdata | ConvertFrom-Json | Select-Object -Property Id, CreationTime, UserID, Operation, @{Name = 'Application Name'; Expression = { ($_.Target[3].ID) } }

            $report  | Out-MultipleFileType -fileprefix "Entra_App_Consents" -csv -json -append
        }

    }

    ##Searching for known malicious applications##

    $AllTenantApps = @(Get-MgServicePrincipal) #get display name of all apps in tenant
    #TODO: use MS apps json i put on GH and exclude stuff inside of that list
    
    $SuspiciousApps = Invoke-RestMethod -URI https://raw.githubusercontent.com/randomaccess3/detections/main/M365_Oauth_Apps/MaliciousOauthAppDetections.json #pull list of malicious oauth apps from github

    #TODO: ps custom object to get properties from both outputs
    $MatchingApps = $($AllTenantApps | Where-Object displayname -in $SuspiciousApps.applications.name; $AllTenantApps | Where-Object appid -in $SuspiciousApps.appid) | Sort-Object appid -unique

    if ($null -eq $MatchingApps) {
        Out-LogFile "No suspicious applications found in tenant"
    }
    else {
        Out-LogFile "Suspicious application consents found within tenant! Please review applications." -notice
        $MatchingApps | Out-MultipleFileType -FilePrefix "_Investigate_Suspicious_App_List" -txt -notice
    }

    <#
    ##Gathering all apps and their principles and permissions##
    # Using the script from the article https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/detect-and-remediate-illicit-consent-grants

    [array]$Grants = Get-AzureADPSPermissions -ShowProgress
    # [bool]$flag = $false

    #This isnt super helpful since it always grabs some apps that are from Microsoft
    #TODO: Improve this bit to be more useful in situations of admin compromise
    
    # Search the Grants for the listed bad grants that we can detect
    if ($Grants.consenttype -contains 'AllPrinciples') {
        Out-LogFile "Found at least one `'AllPrinciples`' Grant" -notice
        $flag = $true
    }
    if ([bool]($Grants.permission -match 'all')) {
        Out-LogFile "Found at least one `'All`' Grant" -notice
        $flag = $true
    }

    if ($flag) {
        Out-LogFile 'Review the information at the following link to understand these results' -notice
        Out-LogFile 'https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/detect-and-remediate-illicit-consent-grants#inventory-apps-with-access-in-your-organization' -notice
    }
    else {
        Out-LogFile "To review this data follow:"
        Out-LogFile "https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/detect-and-remediate-illicit-consent-grants#inventory-apps-with-access-in-your-organization"
    }


    $Grants | Out-MultipleFileType -FilePrefix "Tenant_Applications" -csv -json
#>
}