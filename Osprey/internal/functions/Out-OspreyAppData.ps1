<#
.SYNOPSIS
    Output Osprey appdata to a file
.DESCRIPTION
    Output Osprey appdata to a file
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
Function Out-OspreyAppData {
    $OspreyAppdataPath = join-path $env:LOCALAPPDATA "Osprey\Osprey.json"
    $OspreyAppdataFolder = join-path $env:LOCALAPPDATA "Osprey"

    # test if the folder exists
    if (test-path $OspreyAppdataFolder) { }
    # if it doesn't we need to create it
    else {
        $null = New-Item -ItemType Directory -Path $OspreyAppdataFolder
    }

    Out-LogFile ("Recording OspreyAppData to file " + $OspreyAppdataPath)
    $global:OspreyAppData | ConvertTo-Json | Out-File -FilePath $OspreyAppdataPath -Force
}