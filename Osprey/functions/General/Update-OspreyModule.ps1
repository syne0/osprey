Function Update-OspreyModule {
<#
.SYNOPSIS
    Osprey upgrade check
.DESCRIPTION
    Osprey upgrade check
.PARAMETER ElevatedUpdate
    Update Module
.EXAMPLE
    Update-OspreyModule
    Checks for update to Osprey Module on PowerShell Gallery
.NOTES
    General notes
#> #TODO: Update
    param
    (
        [switch]$ElevatedUpdate
    )

    # If ElevatedUpdate is true then we are running from a forced elevation and we just need to run without prompting
    if ($ElevatedUpdate) {
        # Set upgrade to true
        $Upgrade = $true
    }
    else {

        # See if we can do an upgrade check
        if ($null -eq (Get-Command Find-Module)) { }

        # If we can then look for an updated version of the module
        else {
            Write-Output "Checking for latest version online"
            $onlineversion = Find-Module -name Osprey -erroraction silentlycontinue
            $Localversion = (Get-Module Osprey | Sort-Object -Property Version -Descending)[0]
            Write-Output ("Found Version " + $onlineversion.version + " Online")

            if ($null -eq $onlineversion){
                Write-Output "[ERROR] - Unable to check Osprey version in Gallery"
            }
            elseif (([version]$onlineversion.version) -gt ([version]$localversion.version)) {
                Write-Output "New version of Osprey module found online"
                Write-Output ("Local Version: " + $localversion.version + " Online Version: " + $onlineversion.version)

                # Prompt the user to upgrade or not
                $title = "Upgrade version"
                $message = "A Newer version of the Osprey Module has been found Online. `nUpgrade to latest version?"
                $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Stops the function and provides directions for upgrading."
                $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Continues running current function"
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
                $result = $host.ui.PromptForChoice($title, $message, $options, 0)

                # Check to see what the user choose
                switch ($result) {
                    0 { $Upgrade = $true; Send-AIEvent -Event Upgrade -Properties @{"Upgrade" = "True" }
                    }
                    1 { $Upgrade = $false; Send-AIEvent -Event Upgrade -Properties @{"Upgrade" = "False" }
                    }
                }
            }
            # If the versions match then we don't need to upgrade
            else {
                Write-Output "Latest Version Installed"
            }
        }
    }

    # If we determined that we want to do an upgrade make the needed checks and do it
    if ($Upgrade) {
        # Determine if we have an elevated powershell prompt
        If (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            # Update the module
            Write-Output "Downloading Updated Osprey Module"
            Update-Module Osprey -Force
            Write-Output "Update Finished"
            Start-Sleep 3

            # If Elevated update then this prompt was created by the Update-OspreyModule function and we can close it out otherwise leave it up
            if ($ElevatedUpdate) { exit }

            # If we didn't elevate then we are running in the admin prompt and we need to import the new Osprey module
            else {
                Write-Output "Starting new PowerShell Window with the updated Osprey Module loaded"

                # We can't load a new copy of the same module from inside the module so we have to start a new window
                Start-Process powershell.exe -ArgumentList "-noexit -Command Import-Module Osprey -force" -Verb RunAs
                Write-Warning "Updated Osprey Module loaded in New PowerShell Window. `nPlease Close this Window."
                break
            }

        }
        # If we are not running as admin we need to start an admin prompt
        else {
            # Relaunch as an elevated process:
            Write-Output "Starting Elevated Prompt"
            Start-Process powershell.exe -ArgumentList "-noexit -Command Import-Module Osprey;Update-OspreyModule -ElevatedUpdate" -Verb RunAs -Wait

            Write-Output "Starting new PowerShell Window with the updated Osprey Module loaded"

            # We can't load a new copy of the same module from inside the module so we have to start a new window
            Start-Process powershell.exe -ArgumentList "-noexit -Command Import-Module Osprey -force"
            Write-Warning "Updated Osprey Module loaded in New PowerShell Window. `nPlease Close this Window."
            break
        }
    }
    # Since upgrade is false we log and continue
    else {
        Write-Output "Skipping Upgrade"
    }
}