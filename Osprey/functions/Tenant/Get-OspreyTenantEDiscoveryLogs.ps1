<#
.DESCRIPTION
    Searches the UAL for eDiscovery events
.OUTPUTS
    eDiscoveryLogs.csv
    #> #conf 7/13
Function Get-OspreyTenantEDiscoveryLogs {
    
    Test-EXOConnection
    $InformationPreference = "Continue"

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
            CreationTime = $log1 | Select-Object -ExpandProperty CreationTime
            Id = $log1 | Select-Object -ExpandProperty Id
            Name = $log1 | Select-Object -ExpandProperty ObjectId
            Operation = $log1 | Select-Object -ExpandProperty Operation
            UserID = $log1 | Select-Object -ExpandProperty UserID
            }
        }
        $eDiscoveryOutput | Out-MultipleFileType -fileprefix "eDiscoveryLogs" -csv

    }
}
