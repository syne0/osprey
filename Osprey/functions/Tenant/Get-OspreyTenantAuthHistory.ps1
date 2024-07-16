
<#
.DESCRIPTION
    Connects to EXO and searches the unified audit log file only a date time filter.
    Searches in 15 minute increments to ensure that we gather all data.
    Should be used once you have used other commands to determine a "window" that needs more review.
.OUTPUTS
    Audit_Log_Full_<date>.csv
    Audit_Log_Full_<date>.json
#>
Function Get-OspreyTenantAuthHistory {

Param (
        [Parameter(Mandatory = $true)]
        [datetime]$StartDate,
        [int]$IntervalMinutes = 15
    )

    # Make sure the start date isn't more than 180 days in the past
    if ((Get-Date).adddays(-181) -gt $StartDate) {
        Out-Logfile "[ERROR] - Start date is over 180 days in the past"
        break
    }

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    # Setup inial start and end time for the search
    [datetime]$CurrentStart = $StartDate
    [datetime]$CurrentEnd = $StartDate.AddMinutes($IntervalMinutes)

    # Hard stop for the end time for 48 hours this is to be a good citizen and to ensure that we actually get the data back
    [datetime]$end = $StartDate.AddHours(48)

    # Setup our file prefix so we can run multiple times with out collision
    [string]$prefix = Get-Date ($StartDate) -UFormat %Y_%d_%m

    # Current count so we can setup a file name and other stuff
    [int]$CurrentCount = 0

    # Create while loop so we go thru things in intervals until we hit the end
    while ($currentStart -lt $end) {
        # Pull the unified audit log results
        [array]$output = Get-AllUnifiedAuditLogEntry -UnifiedSearch "Search-UnifiedAuditLog" -StartDate $currentStart -EndDate $currentEnd

        # See if we have results if so push to csv file
        if ($null -eq $output) {
            Out-LogFile ("No results found for time period " + $CurrentStart + " - " + $CurrentEnd)
        }
        else {
            $output | Out-MultipleFileType -FilePrefix "Audit_Log_Full_$prefix" -Append -csv -json
        }

        # Move our start and end times forward
        $currentStart = $currentEnd
        $currentEnd = $currentEnd.AddMinutes($intervalMinutes)

        # Increment our count
        $CurrentCount++
    }
}