<#
.DESCRIPTION
    Searches the UAL for eDiscovery events
.OUTPUTS
    eDiscoveryLogs.csv
    #>
Function Get-OspreyTenantEDiscoveryLogs {
    
    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    Out-LogFile "Gathering any eDiscovery logs" -action

    # Search UAL audit logs for any eDiscovery activity
    $eDiscoveryLogs = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -RecordType 'Discovery'")
    # If null we found no changes to nothing to do here
    if ($null -eq $eDiscoveryLogs) {
        Out-LogFile "No eDiscovery Logs found"
    }

    # If not null then we must have found some events so flag them
    else {
        Out-LogFile "eDiscovery Activity has been found!" -Notice
        Out-LogFile "Please review eDiscoveryLogs.csv to validate if the activity is legitimate." -Notice
        # Go thru each even and prepare it to output to CSV
        Foreach ($log in $eDiscoveryLogs) {
            $log1 = $log.auditdata | ConvertFrom-Json
            $report = $log1  | Select-Object -Property CreationTime,
            Id,
            Operation,
            Workload,
            UserID,
            Case,
            @{Name = 'CaseID'; Expression = { ($_.ExtendedProperties | Where-Object { $_.Name -eq 'CaseId' }).value } },
            @{Name = 'Cmdlet'; Expression = { ($_.Parameters | Where-Object { $_.Name -eq 'Cmdlet' }).value } }

            $report | Out-MultipleFileType -fileprefix "eDiscoveryLogs" -csv -append
        }

    }
}
