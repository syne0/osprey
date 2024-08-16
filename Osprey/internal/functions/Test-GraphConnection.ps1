<#
.SYNOPSIS
    Test if we are connected to Graph and connect if not
.DESCRIPTION
    Test if we are connected to Graph and connect if not
.EXAMPLE
    PS C:\> <example usage>
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    https://learn.microsoft.com/en-us/powershell/microsoftgraph/get-started?view=graph-powershell-1.0
#>
Function Test-GraphConnection {
    
    # Get context to check for graph
    if ($null -eq (Get-MGContext)) {
        Write-Output "Connecting to MGGraph using MGGraph Module"
        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Domain.Read.All", "Directory.Read.All", "Application.Read.All"
    }

}#End Function Test-GraphConnection