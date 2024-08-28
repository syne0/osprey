Function Get-OspreyUserDevices {
    <#
.DESCRIPTION
    Pulls all mobile devices attached to them mailbox using get-mobiledevice.
    Gets all devices registered to the user using Get-MgUserRegisteredDevice.
.OUTPUTS
    MobileDevices.csv
    _Investigate_MobileDevices.csv
    Entra_Devices.csv
    _Investigate_Entra_Devices.csv
#> 

    param
    (
        [Parameter(Mandatory = $true)]
        [array]$UserPrincipalName

    )

    Test-GraphConnection
    Test-EXOConnection
    $InformationPreference = "Continue"

    # Verify our UPN input
    [array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

    # Gather the trace
    foreach ($Object in $UserArray) {

        [string]$User = $Object.UserPrincipalName


        ##Get all mobile devices##

        Out-Logfile ("Gathering Mobile Devices for: " + $User)
        [array]$MobileDevices = Get-MobileDevice -mailbox $User

        if ($Null -eq $MobileDevices) {
            Out-Logfile ("No mobile devices found for user: " + $User)
        }
        else {
            Out-Logfile ("Found " + $MobileDevices.count + " Devices")

            # Output all mobile devices found
            $MobileDevices | Out-MultipleFileType -FilePreFix "MobileDevices" -user $user -csv -json

            # Check each device to see if it was NEW
            # If so flag it for investigation
            $InvestigateLog = @()
            foreach ($Device in $MobileDevices) {
                if ($Device.FirstSyncTime -gt $Osprey.StartDate) {
                    Out-Logfile ("Device found that was first synced inside investigation window. DeviceID: " + $Device.DeviceID) -notice
                    $InvestigateLog += $Device #append flagged devices
                }
            }

            #if investigation-worthy devices  were found, output those to csv.
            if ($InvestigateLog.count -gt 0) {
                $InvestigateLog | Out-MultipleFileType -fileprefix "_Investigate_MobileDevice" -user $user -csv -json -notice
            }
        }

        ##Get all Entra joined/registered devices##
        Out-Logfile ("Gathering Entra registered or joined devices for: " + $User)
        # Get all devices
        $EntraDevices = Get-MgUserRegisteredDevice -UserId $user
        if ($Null -eq $EntraDevices) {
            Out-Logfile ("No Entra devices found for user: " + $User)
        }
        else {
            # For each device we found
            $DeviceLog = @()
            foreach ($device in $EntraDevices) {
                # Get information about the device using graph and export that by appending it into an array
                $device1 = Get-MGDevice -deviceID $device.Id 
                $DeviceLog += $device1
            }
            $DeviceLog | Out-MultipleFileType -fileprefix "EntraDevices" -user $user -csv -json -xml

            # Export a simple version as well
            $SimpleDeviceReport = foreach ($Device in $EntraDevices) {
                # Get information about the device using graph and export that by appending it into an array
                $device1 = Get-MGDevice -deviceID $Device.Id 
                [PSCustomObject]@{
                    DisplayName            = $device1.DisplayName
                    RegistrationDateTime   = $device1.RegistrationDateTime
                    Id                     = $device1.Id
                    OperatingSystem        = $device1.OperatingSystem
                    OperatingSystemVersion = $device1.OperatingSystemVersion
                    EnrollmentType         = $device1.EnrollmentType
                }
                    
            }
            $SimpleDeviceReport | Out-MultipleFileType -FilePreFix "Simple_EntraDevices" -user $user -csv

            # If a device was found that was registered during investigation window, flag that for review
            $InvestigateLog = @()
            foreach ($Device in $EntraDevices) {
                $device1 = Get-MGDevice -deviceID $Device.Id | Select-Object Displayname, RegistrationDateTime, Id, OperatingSystem, OperatingSystemVersion, EnrollmentType
                if ($device1.RegistrationDateTime -gt $Osprey.StartDate) {
                    Out-Logfile ("Device found that was first added inside investigation window. DeviceID: " + $Device1.Id) -notice
                    $InvestigateLog += $device1
                }
            }
            if ($InvestigateLog.count -gt 0) {
                $InvestigateLog | Out-MultipleFileType -fileprefix "_Investigate_EntraDevices" -user $user -csv -notice
            }
        }
    }
} 

