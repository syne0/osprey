<#
.DESCRIPTION
	Gathers application consents from the investigation period. Also gathers list of all applications, their permissions, and compares that list to a hardcoded list
    of known-suspicious applications.

.OUTPUTS
    Entra_App_Consents.csv
    Entra_App_Consents.json
    Suspicious_App_List.csv
    Tenant_Applications.csv
    Tenant_Applications.json
#>
Function Get-OspreyTenantAppsAndConsents {
    
    Test-EXOConnection
    Test-GraphConnection
    $InformationPreference = "Continue"

    # Make sure our variables are null
    $AppConsentActivity = $null
    $MatchingApps = $null

    ##Search the unified audit log for events related to application activity##
    Out-LogFile "Searching Unified Audit Log for application-related activities in Entra." -action

    $AppConsentActivity = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -RecordType 'AzureActiveDirectory' -Operations 'Add OAuth2PermissionGrant.','Consent to application.' ")

    # If null we found no changes to nothing to do here
    if ($null -eq $AppConsentActivity) {
        Out-LogFile "No Application related events found in the search time frame."
    }

    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "Application consent activity found. Please review Entra_App_Consents.csv to ensure consents are legitimate."
        $AppConsentReport = Foreach ($log in $AppConsentActivity) {
            $log1 = $log.auditdata | ConvertFrom-Json
            [PSCustomObject]@{
                CreationTime    = $log1 | Select-Object -ExpandProperty CreationTime
                Id              = $log1 | Select-Object -ExpandProperty Id
                UserID          = $log1 | Select-Object -ExpandProperty UserID
                Operation       = $log1 | Select-Object -ExpandProperty Operation
                ApplicationName = $log1 | Select-Object -ExpandProperty Target | Select-Object -ExpandProperty ID | Select-object -index 3
            }
        }
        $AppConsentReport  | Out-MultipleFileType -fileprefix "Entra_App_Consents" -csv -json
    }
    ##Searching for known malicious applications##

    $AllTenantApps = @(Get-MgServicePrincipal -all) #get all apps in tenant
    
    $SuspiciousApps = Invoke-RestMethod -URI https://raw.githubusercontent.com/randomaccess3/detections/main/M365_Oauth_Apps/MaliciousOauthAppDetections.json #pull list of malicious oauth apps from github

    $MatchingApps = $($AllTenantApps | Where-Object displayname -in $SuspiciousApps.applications.name; $AllTenantApps | Where-Object appid -in $SuspiciousApps.appid) | Sort-Object appid -unique #compare apps and record down any matches

    if ($null -eq $MatchingApps) {
        Out-LogFile "No known suspicious applications found in tenant."
    }
    else {
        Out-LogFile "Suspicious application consents found within tenant! Please review applications." -notice

        $AppOutput = foreach ($match in $MatchingApps) {
            #do this for each app match we found

            [PSCustomObject]@{ #build a custom object that takes information from various sources and outputs it
                ApplicationName  = $match.DisplayName #from entra
                ApplicationID    = $match.AppId #from entra
                Enabled          = $match.AccountEnabled #from entra
                Created          = $match.AdditionalProperties.createdDateTime #from entra
                Description      = $SuspiciousApps.applications | Where-Object appid -match $match.AppId | Select-object -expandproperty description #from github list
                UsersAssigned    = Get-MgServicePrincipalAppRoleAssignedTo -serviceprincipalid $match.id | Select-Object -expandproperty PrincipalDisplayname | Out-String #need to pull from additional cmd
                References       = $SuspiciousApps.applications | Where-Object appid -match $match.AppId | Select-object -expandproperty references | Out-String  #from github list
                KnownPermissions = $SuspiciousApps.applications | Where-Object appid -match $match.AppId | Select-object -expandproperty Permissions | Out-String #from github list  
            }
        }
        $AppOutput | Out-MultipleFileType -FilePrefix "_Investigate_Suspicious_App_List" -csv -notice
    }

    <#
    ##Gathering all apps and their principles and permissions##
    # Using the script from the article https://docs.microsoft.com/en-us/microsoft-365/security/office-365-security/detect-and-remediate-illicit-consent-grants

    [array]$Grants = Get-AzureADPSPermissions -ShowProgress
    # [bool]$flag = $false

    #This isn't super helpful since it always grabs some apps that are from Microsoft and is noisy
    #TODO: Improve this bit to be more useful in situations of admin compromise
    #clipping this out for now, will update after 1.0 is published
    
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