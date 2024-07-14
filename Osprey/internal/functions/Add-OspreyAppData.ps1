<#
.SYNOPSIS
    Add objects to the Osprey app data
.DESCRIPTION
    Add objects to the Osprey app data
.PARAMETER Name
    Name variable
.PARAMETER Value
    Value of of retieved data
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
        [string]$Value
    )

    Out-LogFile ("Adding " + $value + " to " + $Name + " in OspreyAppData")

    # Test if our OspreyAppData variable exists
    if ([bool](get-variable OspreyAppData -ErrorAction SilentlyContinue)) {
        $global:OspreyAppData | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }
    else {
        $global:OspreyAppData = New-Object -TypeName PSObject
        $global:OspreyAppData | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
    }

    # make sure we then write that out to the appdata storage
    Out-OspreyAppData

}