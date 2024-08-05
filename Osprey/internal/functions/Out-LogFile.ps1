<#
.SYNOPSIS
    Writes output to a log file with a time date stamp
.DESCRIPTION
    Writes output to a log file with a time date stamp
.PARAMETER string
    Log Message
.PARAMETER action
    What is happening
.PARAMETER notice
    Verbose notification
.PARAMETER silentnotice
    Silent notification
.EXAMPLE
    Out-LogFile
    Sends messages to the log file
.NOTES
    This is will depracted soon. #TODO: Will it? determine why this was, though I'm assuming it was due to overhaul to ps framework.
#> 
Function Out-LogFile {
    Param
    (
        [string]$string,
        [switch]$action,
        [switch]$notice,
        [switch]$silentnotice,
        [switch]$silentoutput
	)

	Write-PSFMessage -Message $string -ModuleName Osprey -FunctionName (Get-PSCallstack)[1].FunctionName

    # Get our log file path
    $LogFile = Join-path $Osprey.FilePath "Osprey.log"
    $ScreenOutput = $true
    $LogOutput = $true

    # Get the current date
    [string]$date = Get-Date -Format G

    # Deal with each switch and what log string it should put out and if any special output

    # Action indicates that we are starting to do something
    if ($action) {
        [string]$logstring = ( "[" + $date + "] - [ACTION] - " + $string)

    }
    # If notice is true the we should write this to interesting.txt as well
    elseif ($notice) {
        [string]$logstring = ( "[" + $date + "] - ## INVESTIGATE ## - " + $string)

        # Build the file name for Investigate stuff log
        [string]$InvestigateFile = Join-Path (Split-Path $LogFile -Parent) "_Investigate.txt"
        $logstring | Out-File -FilePath $InvestigateFile -Append
    }
    # For silent we need to supress the screen output
    elseif ($silentnotice) {
        [string]$logstring = ( "Addtional Information: " + $string)
        # Build the file name for Investigate stuff log
        [string]$InvestigateFile = Join-Path (Split-Path $LogFile -Parent) "_Investigate.txt"
        $logstring | Out-File -FilePath $InvestigateFile -Append

        # Supress screen and normal log output
        $ScreenOutput = $false
        $LogOutput = $false

    }
    # Normal output
    else {
        [string]$logstring = ( "[" + $date + "] - " + $string)
    }

    # Write everything to our log file
    if ($LogOutput) {
        if ($silentoutput){

            $logstring | Out-File -FilePath $LogFile -Append
            $ScreenOutput = $false

        }
        else{
        $logstring | Out-File -FilePath $LogFile -Append
        }
    }

    # Output to the screen
    if ($ScreenOutput) {
        Write-Information -MessageData $logstring -InformationAction Continue
    }

}