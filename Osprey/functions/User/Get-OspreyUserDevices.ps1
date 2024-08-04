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

    Test-EXOConnection
    Send-AIEvent -Event "CmdRun"

    # Verify our UPN input
    [array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

    # Gather the trace
    foreach ($Object in $UserArray) {

        [string]$User = $Object.UserPrincipalName


        ##Get all mobile devices##

        Out-Logfile ("Gathering Mobile Devices for: " + $User)
        [array]$MobileDevices = Get-MobileDevice -mailbox $User

        if ($Null -eq $MobileDevices) {
            Out-Logfile ("No devices found for user: " + $User)
        }
        else {
            Out-Logfile ("Found " + $MobileDevices.count + " Devices")

            # Check each device to see if it was NEW
            # If so flag it for investigation
            foreach ($Device in $MobileDevices){
                if ($Device.FirstSyncTime -gt $Osprey.StartDate){
                    Out-Logfile ("Device found that was first synced inside investigation window") -notice
                    Out-LogFile ("DeviceID: " + $Device.DeviceID) -notice
                    $Device | Out-MultipleFileType -FilePreFix "_Investigate_MobileDevice" -user $user -csv -json -append -Notice
                }
            }
            # Output all mobile devices found
            $MobileDevices | Out-MultipleFileType -FilePreFix "MobileDevices" -user $user -csv -json


            ##Get all Entra joined/registered devices##

            # Get all devices
            $EntraDevices = Get-MgUserRegisteredDevice -UserId $user

            # For each device we found
            foreach ($Device in $EntraDevices){
                # Get information about the device using graph and export that
                Get-MGDevice -deviceID $Device.Id 
                $Device | Out-MultipleFileType -FilePreFix "RegisteredDevices" -user $user -csv -xml -json -append
                
                # Export a simple version as well
                Get-MGDevice -deviceID $Device.Id | select DisplayName,RegistrationDateTime,Id,OperatingSystem,OperatingSystemVersion,EnrollmentType
                $Device | Out-MultipleFileType -FilePreFix "Simple_RegisteredDevices" -user $user -csv -append

                # If a device was found that was registered during investigation window, flag that for review
                if ($Device.RegistrationDateTime -gt $Osprey.StartDate){
                    Out-LogFile ("Device found that was registered during investigation window.")
                    $Device | Out-MultipleFileType -FilePreFix "_Investigate_RegisteredDevices" -user $user -csv -append -Notice
                }
            }



        }
    }
}
