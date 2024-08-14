<#
.SYNOPSIS
    Read in Osprey app data if it is there
.DESCRIPTION
    Read in Osprey app data if it is there
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#> 
Function Read-OspreyAppData {
    $OspreyAppdataPath = join-path $env:LOCALAPPDATA "Osprey\Osprey.json"

    # check to see if our xml file is there
    if (test-path $OspreyAppdataPath) {
        Out-LogFile ("Reading file " + $OspreyAppdataPath)
        $global:OspreyAppData = ConvertFrom-Json -InputObject ([string](Get-Content $OspreyAppdataPath))
    }
    # if we don't have an xml file then do nothing
    else {
        Out-LogFile ("No OspreyAppData File found " + $OspreyAppdataPath)
    }
}