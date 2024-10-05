<#
.DESCRIPTION
    Gathers AutoReply configuration for the provided users.
    Looks for AutoReplyState of Enabled and exports the config.
.OUTPUTS
    File: AutoReply.txt
#>
Function Get-OspreyUserAutoReply {

    param
    (
        [Parameter(Mandatory = $true)]
        [array]$UserPrincipalName

    )

    Test-EXOConnection
    $InformationPreference = "Continue"

    # Verify our UPN input
    [array]$UserArray = Test-UserObject -ToTest $UserPrincipalName

    foreach ($Object in $UserArray) {

        [string]$User = $Object.UserPrincipalName

        # Get Autoreply Configuration
        Out-LogFile ("Retrieving Autoreply Configuration: " + $User) -action
        $AutoReply = Get-MailboxAutoReplyConfiguration -Identity  $User

        # Check if the Autoreply is Disabled
        if ($AutoReply.AutoReplyState -eq 'Disabled') {

            Out-LogFile "AutoReply is not enabled or not configured."
        }
        # Output Enabled AutoReplyConfiguration to a generic txt
        else {

            $AutoReply | Out-MultipleFileType -FilePreFix "AutoReply" -User $user -txt
        }
    }

}
