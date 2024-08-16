Function Search-OspreyTenantActivityByIP {
    <#
.SYNOPSIS
    Gathers logon activity based on a submitted IP Address.
.DESCRIPTION
    Pulls logon activity from the Unified Audit log based on a provided IP address.
    Processes the data to highlight successful logons and the number of users accessed by a given IP address.
.PARAMETER IPaddress
    IP address to investigate
.OUTPUTS
    All_Events.csv \ All_Events.xml \ All_Events.json
    Login_Success_Events.csv \ Login_Success_Events.xml \ Login_Success_Events.json
    Login_Failure_Events.csv \ Login_Failure_Events.xml \ Login_Failure_Events.json
    Unique_Users_Login.csv \ Unique_Users_Login.xml \ Unique_Users_Login.json
.EXAMPLE
    Search-OspreyTenantActivityByIP -IPAddress 10.234.20.12
    Searches for all Logon activity from IP 10.234.20.12.
#>
    param
    (
        [parameter(Mandatory = $true)]
        [string]$IpAddress
    )

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"
    $InformationPreference = "Continue"

    # Replace an : in the IP address with . since : isn't allowed in a directory name
    $DirectoryName = $IpAddress.replace(":", ".")

    # Make sure we got only a single IP address
    if ($IpAddress -like "*,*") {
        Out-LogFile "Please provide a single IP address to search."
        Write-Error -Message "Please provide a single IP address to search." -ErrorAction Stop
    }

    Out-LogFile ("Searching for login events related to " + $IpAddress) -action

    ##Gather all of the events related to these IP addresses##
    Out-LogFile ("Hold tight, this may take some time...")

    [array]$ipevents = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -RecordType AzureActiveDirectoryStsLogon -IPAddresses " + $IPAddress )

    # If we didn't get anything back log it
    if ($null -eq $ipevents) {
        Out-LogFile ("No IP login events found for IP "	+ $IpAddress)
    }
    # If we did then process it
    else {

        ##Expand out the Data and convert from JSON##
        [array]$ipeventsexpanded = $ipevents | Select-object -ExpandProperty AuditData | ConvertFrom-Json
        Out-LogFile ("Found " + $ipeventsexpanded.count + " related to provided IP" )
        $ipeventsexpanded | Out-MultipleFileType -FilePrefix "All_Login_Events" -csv -json -xml -User $DirectoryName

        ##Get the logon events that were a success##
        [array]$successipevents = $ipeventsexpanded | Where-Object { $_.Operation -eq "UserLoggedIn" }
        if ($null -eq $successipevents) {
            Out-LogFile ("No successful logon events found for IP "	+ $IpAddress)
        }
        else {
            Out-LogFile ("Found " + $successipevents.Count + " successful logons related to provided IP")
            $successipevents | Out-MultipleFileType -FilePrefix "Login_Success_Events" -csv -json -xml -User $DirectoryName
        }

        ##Get the logon events that were a failure##
        [array]$failedipevents = $ipeventsexpanded | Where-Object { $_.Operation -eq "UserLoginFailed" }
        if ($null -eq $successipevents) {
            Out-LogFile ("No failed logon events found for IP "	+ $IpAddress)
        }
        else {
            Out-LogFile ("Found " + $failedipevents.Count + " failed logons related to provided IP")
            $failedipevents | Out-MultipleFileType -FilePrefix "Login_Failure_Events" -csv -json -xml -User $DirectoryName
        }

        # Select all unique users accessed by this IP
        [array]$uniqueuserlogons = Select-UniqueObject -ObjectArray $ipeventsexpanded -Property "UserID"
        Out-LogFile ("IP " + $ipaddress + " has tried to access " + $uniqueuserlogons.count + " users") -notice
        $uniqueuserlogons | Out-MultipleFileType -FilePrefix "Unique_Users_Login" -csv -json -User $DirectoryName -Notice

    }

}