<#
.DESCRIPTION
	Connects to the necessary modules and gathers information needed for user to run Osprey. Gives suggestions on commands user can run.
    Includes functions to reinitialize an osprey session and change parameters or tenant.
#>
[CmdletBinding()]
param
(
    [switch]$Force,
    [switch]$IAgreeToTheEula,
    [switch]$SkipUpdate,
    [switch]$AdminInvestigation,
    [int]$DaysToLookBack,
    [DateTime]$StartDate,
    [DateTime]$EndDate,
    [string]$FilePath
)

Function Test-LoggingPath {
    #good -s
    param([string]$PathToTest)

    # First test if the path we were given exists
    if (Test-Path $PathToTest) {

        # If the path exists verify that it is a folder
        if ((Get-Item $PathToTest).PSIsContainer -eq $true) {
            Return $true
        }
        # If it is not a folder return false and write an error
        else {
            Write-Information ("Path provided " + $PathToTest + " was not found to be a folder.")
            Return $false
        }
    }
    # If it doesn't exist then return false and write an error
    else {
        Write-Information ("Directory " + $PathToTest + " Not Found")
        Return $false
    }
}
Function New-LoggingFolder {
    #good but validate graph works consistently. sometimes doesn't!
    param([string]$RootPath)

    # Create a folder ID based on date
    [string]$TenantName = (Get-MGDomain | Where-Object { $_.isDefault }).ID
    [string]$FolderID = "Osprey_" + $TenantName.Substring(0, $TenantName.IndexOf('.')) + "_" + (Get-Date -UFormat %Y%m%d_%H%M).tostring()

    # Add that ID to the given path
    $FullOutputPath = Join-Path $RootPath $FolderID

    # Just in case we run this twice in a min lets not throw an error
    if (Test-Path $FullOutputPath) {
        Write-Information "Path Exists"
    }
    # If it is not there make it
    else {
        Write-Information ("Creating subfolder with name " + $FullOutputPath)
        $null = New-Item $FullOutputPath -ItemType Directory
    }

    Return $FullOutputPath
}
Function Set-LoggingPath {
    #good -s
    param ([string]$Path)

    # If no value of Path is provided prompt and gather from the user
    if ([string]::IsNullOrEmpty($Path)) {

        # Setup a while loop so we can get a valid path
        Do {

            # Ask the customer for the output path
            [string]$UserPath = Read-Host "Please provide an output directory"

            # If the path is valid then create the subfolder
            if (Test-LoggingPath -PathToTest $UserPath) {

                $Folder = New-LoggingFolder -RootPath $UserPath
                $ValidPath = $true
            }
            # If the path if not valid then we need to loop thru again
            else {
                Write-Information ("Path not a valid Directory " + $UserPath)
                $ValidPath = $false
            }

        }
        While ($ValidPath -eq $false)
    }
    # If a value if provided go from there
    else {
        # If the provided path is valid then we can create the subfolder
        if (Test-LoggingPath -PathToTest $Path) {
            $Folder = New-LoggingFolder -RootPath $Path
        }
        # If the provided path fails validation then we just need to stop
        else {
            Write-Error ("Provided Path is not valid " + $Path) -ErrorAction Stop
        }
    }

    Return $Folder
}
Function Get-Eula {
    Write-Information ('
    DISCLAIMER:
    
    Osprey is based on Hawk, so the original license and disclaimer applies.

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
            ')

    # Prompt the user to agree with EULA
    $title = "Disclaimer"
    $message = "Do you agree with the above disclaimer?"
    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Logs agreement and continues use of the Osprey Functions."
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Stops execution of Osprey Functions"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $result = $host.ui.PromptForChoice($title, $message, $options, 0)
    # If yes log and continue
    # If no log error and exit
    switch ($result) {
        0 {
            Write-Information "`n"
                    
        }
        1 {
            Write-Information "Aborting Cmdlet"
            Write-Error -Message "Failure to agree with EULA" -ErrorAction Stop
            break
        }
    }

}

###MAIN###

Function Start-Osprey {
    #some helpful comment here
    $InformationPreference = "Continue"
    $OspreyInitialized = $false

    if ([string]::IsNullOrEmpty($Osprey.FilePath)) {
        Write-Information "Running Start-Osprey..."
    }
    else {
        $OspreyInitialized = $true
    }
    #triggers if Start-Osprey is rerun, will allow you to choose if you want to reinitialize 
    if ($OspreyInitialized) {

        $title = "Osprey Is Initialized"
        $message = "Osprey has already been initialized. Would you like to reinitialize Osprey with different parameters or on a different tenant?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Reruns Osprey initialization."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Does not reinitialize Osprey."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, $message, $options, 0)
        switch ($result) {
            0 {
                Write-Host "Reinitializing Osprey..." -ForegroundColor DarkGreen
                $reinit = $true
            }
            1 {
                Write-Host "Osprey will not be reinitialized... Ending Start-Osprey" -ForegroundColor DarkRed
                exit
            }
        }
    }

    if ($reinit) {
        $title = "Change Tenant?"
        $message = "Osprey is being reinitialized. Would you like to change tenants?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Disconnects currently connected modules, reconnects them, reruns initialization."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Continues reinitialization with current tenant."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, $message, $options, 0)
        switch ($result) {
            0 {
                Write-Host "Disconnecting currently connected tenant"
                Disconnect-ExchangeOnline
                Disconnect-graph #TODO: required? determine..
                Write-Host "Connecting to prerequisites with new tenant."
                Connect-Prerequisites
            }
            1 {
                Write-Host "Continuing as usual..."
            }

        }
    }

    #gives some info on what Osprey is
    if ($OspreyInitialized -ne $true) {
        
        Write-Host ('
        Welcome to Osprey, a Powershell-based tool for gathering information about O365 breaches.
        Osprey is a fork of Hawk and started as a personal project to remove deprecated dependent
        modules and implement QoL improvements.
        
        Osprey would not have been possible without the years of work that the community put into
        maintaining Osprey. A sincere thank you to the Osprey maintainers for everything you have done
        for the M365 IR and BEC community. <3

        More information about Osprey can be found at https://cybercorner.tech/osprey.
                ') -ForegroundColor Cyan #not sure if that will be the final URL, may change that. just an idea. -s

        Read-Host -Prompt "Press any key to continue..."

    }

    #update checking
    if ($OspreyInitialized -ne $true) {
        # If we are skipping the update log it
        if ($SkipUpdate) {
            Write-Information "Skipping Update Check"
        }
        # Check to see if there is an Update for Osprey
        else {
            Update-OspreyModule
        }
    }


    <#EULA stuff. Should only ever do this ONCE per Osprey install! but is broken.
    if ($OspreyInitialized -ne $true) {
        #gets EULA info from appdata variable
        if ($null -eq $OspreyAppData.IAgreeToTheEula) {
            Write-Information "You must agree with the EULA to continue"
            Get-Eula
        }
        else {
            Write-Information "Already agreed to the EULA"
        }
    }#>

    Get-Eula

    Write-Information "Setting Up Osprey environment" 
    
    if ($OspreyInitialized -ne $true) {
        Connect-Prerequisites #Connects to the prerequisite modules
    }
    
    ##Get path and set subdirectory##
    # If we have a path passed in then we need to check that otherwise ask
    if ([string]::IsNullOrEmpty($FilePath)) {
        [string]$OutputPath = Set-LoggingPath
    }
    else {
        [string]$OutputPath = Set-LoggingPath -path $FilePath
    }
    
    ##Get Time Period##
    $StartRead = Read-Host "`nFirst Day of Search Window (1-180, Date, Default 90)"
                
    # Determine if the input was a date time
    # True means it was NOT a datetime
    if ($Null -eq ($StartRead -as [DateTime])) {
                
        # if we have a null entry (just hit enter) then set startread to the default of 90
        if ([string]::IsNullOrEmpty($StartRead)) { $StartRead = 90 }
                
        # Calculate our startdate setting it to midnight
        Write-Information ("Calculating Start Date from current date minus " + $StartRead + " days.")
        [DateTime]$StartDate = ((Get-Date).AddDays(-$StartRead)).Date
        Write-Information ("Setting StartDate by Calculation to " + $StartDate + "`n")
    }
    elseif (!($null -eq ($StartRead -as [DateTime]))) {
        #### DATE TIME Provided ####
                
        # Convert the input to a date time object
        [DateTime]$StartDate = (Get-Date $StartRead).Date
                
        # Test to make sure the date time is > 180 and < today
        if ($StartDate -ge ((Get-date).AddDays(-180).Date) -and ($StartDate -le (Get-Date).Date)) {
            #Valid Date do nothing
        }
        else {
            Write-Information ("Date provided beyond acceptable range of 180 days.")
            Write-Information ("Setting date to default of Today - 180 days.")
            [DateTime]$StartDate = ((Get-Date).AddDays(-180)).Date
        }
                
        Write-Information ("Setting StartDate by Date to " + $StartDate + "`n")
    }
    else {
        Write-Error "Invalid date information provided.  Could not determine if this was a date or an integer." -ErrorAction Stop
    }
                
    $EndRead = Read-Host "`nLast Day of search Window (1-180, date, Default Today)"
                
    # Determine if the input was a date time
    # True means it was NOT a datetime
    if ($Null -eq ($EndRead -as [DateTime])) {
        #### Not a Date time ####
                
        # if we have a null entry (just hit enter) then set endread to the default of 1
        if ([string]::IsNullOrEmpty($EndRead)) {
            Write-Information ("Setting End Date to Today")
            [DateTime]$EndDate = ((Get-Date).AddDays(1)).Date
        }
        else {
            # Calculate our startdate setting it to midnight
            Write-Information ("Calculating End Date from current date minus " + $EndRead + " days.")
            # Subtract 1 from the EndRead entry so that we get one day less for the purpose of how searching works with times
            [DateTime]$EndDate = ((Get-Date).AddDays( - ($EndRead - 1))).Date
        }
                
        # Validate that the start date is further back in time than the end date
        if ($StartDate -gt $EndDate) {
            Write-Error "StartDate Cannot be More Recent than EndDate" -ErrorAction Stop
        }
        else {
            Write-Information ("Setting EndDate by Calculation to " + $EndDate + "`n")
        }
    }
    elseif (!($null -eq ($EndRead -as [DateTime]))) {
        #### DATE TIME Provided ####
                
        # Convert the input to a date time object
        [DateTime]$EndDate = ((Get-Date $EndRead).AddDays(1)).Date
                
        # Test to make sure the end date is newer than the start date
        if ($StartDate -gt $EndDate) {
            Write-Information "EndDate Selected was older than start date."
            Write-Information "Setting EndDate to today."
            [DateTime]$EndDate = ((Get-Date).AddDays(1)).Date
        }
        elseif ($EndDate -gt (get-Date).AddDays(2)) {
            Write-Information "EndDate too Far in the future."
            Write-Information "Setting EndDate to Today."
            [DateTime]$EndDate = ((Get-Date).AddDays(1)).Date
        }
                
        Write-Information ("Setting EndDate by Date to " + $EndDate + "`n")
    }
                
    else {
        Write-Error "Invalid date information provided.  Could not determine if this was a date or an integer." -ErrorAction Stop
    }
    
    
    # Determine if we have access to a P1 or P2 Azure Ad License
    if ([bool] (Get-MgSubscribedSku | Where-Object { ($_.SkuPartNumber -like "*aad_premium*") -or ($_.SkuPartNumber -like "*EMS*") -or ($_.SkuPartNumber -like "*E5*") -or ($_.SkuPartNumber -like "*G5*") -or ($_.SkuPartNumber -like "*SPB*") -or ($_.SkuPartNumber -like "*A3*") -or ($_.SkuPartNumber -like "*A5*") -or ($_.SkuPartNumber -like "*F1*")} )) {
        Write-Information "Advanced Entra ID License Found"
        [bool]$AdvancedEntraLicense = $true
    }
    else {
        Write-Information "Advanced Entra ID License NOT Found"
        [bool]$AdvancedEntraLicense = $false
    }
    
    $Output = [PSCustomObject]@{
        FilePath             = $OutputPath
        StartDate            = $StartDate
        EndDate              = $EndDate
        AdvancedAzureLicense = $AdvancedEntraLicense
    }
    

    # Create the script Osprey variable
    Write-Information "Setting up Script Osprey environment variable`n"
    New-Variable -Name Osprey -Scope Script -value $Output -Force
    Out-LogFile "Script Variable Configured"
    Out-LogFile ("*** Version " + (Get-Module Osprey).version + " ***")
    Out-LogFile $Osprey

    if ([string]::IsNullOrEmpty($Osprey.FilePath)) {
        Out-LogFile "Osprey initialization may have ran into an issue. Please rerun Start-Osprey, or visit https://cybercorner.tech/osprey for help."
    }
    else {
        Write-Host "Osprey is now initialized. You may run Start-OspreyTenantInvestigation to continue" -ForegroundColor Cyan
    }

}


