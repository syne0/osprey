<#
.SYNOPSIS
    Add objects to the Osprey app data
.DESCRIPTION
    Add objects to the Osprey app data
.PARAMETER Name
    Name variable
.PARAMETER Value
    Value of of retrieved data
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
Function Add-OspreyAppData {
    param
    (
        [string]$Name,
        [string]$Value,
        [switch]$SkipLogging
        
    )

    if (!$SkipLogging) { Out-LogFile ("Adding " + $value + " to " + $Name + " in OspreyAppData") }

    # Test if our OspreyAppData variable exists
    if ($ospreyappdata) {
        $global:OspreyAppData | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -ErrorAction SilentlyContinue
    }
    else {
        $global:OspreyAppData = New-Object -TypeName PSObject
        $global:OspreyAppData | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }

    # make sure we then write that out to the appdata storage
    if ($SkipLogging) { Out-OspreyAppData -SkipLogging }else { Out-OspreyAppData }

}