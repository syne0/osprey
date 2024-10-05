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
    param(
        [switch]$SkipLogging
    )
    
    $OspreyAppdataPath = $env:LOCALAPPDATA + "\Osprey\Osprey.json"
    # check to see if our json file is there
    if (test-path $OspreyAppdataPath) {
        if (!$SkipLogging) { Out-LogFile ("Reading file " + $OspreyAppdataPath) }
        $global:OspreyAppData = Get-Content $OspreyAppdataPath | ConvertFrom-Json
    }
}