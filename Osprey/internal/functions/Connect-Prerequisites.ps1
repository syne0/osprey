Function Connect-PrereqModules {
    #Connects to the modules Osprey needs to run.
    Write-Information "Connecting to AzureAD Powershell (remove this eventually OK!)"
    Connect-AzureAD
    Write-Information "Connecting to Exchange Online Powershell"
    Connect-ExchangeOnline
    Write-Information "Connecting to Graph API"
    Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Domain.Read.All", "Directory.Read.All", "Application.Read.All"
}