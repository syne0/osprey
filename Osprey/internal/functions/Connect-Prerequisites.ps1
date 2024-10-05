Function Connect-Prerequisites {
    #Connects to the modules Osprey needs to run.
    if (Get-Module -FullyQualifiedName @{ModuleName = "ExchangeOnlineManagement"; RequiredVersion = "3.4.0" } -ListAvailable) {
        Write-Host "Supported ExchangeOnlineManagment version installed"
        Write-Host "Importing supported version"
    }
    else {
        Write-Host "Supported ExchangeOnlineManagment version not installed"
        Write-Host "Installing supported version"
        remove-module exchangeonlinemanagement -ErrorAction SilentlyContinue
        Install-module exchangeonlinemanagement -requiredversion 3.4.0
    }
    Try {
        Write-Host "Importing ExchangeOnlineManagment"
        Import-module exchangeonlinemanagement -RequiredVersion 3.4.0 -scope Local -ErrorAction Stop
        Write-Host "Connecting to Exchange Online Powershell"
        Connect-ExchangeOnline
    }
    catch {
        Write-Host "Failed to import and connect to Exchange Online Powershell"
    }

    Write-Host "Connecting to Graph API"
    Connect-Graph -Scopes "User.Read.All", "Group.Read.All", "Domain.Read.All", "Directory.Read.All", "Application.Read.All"

    #this is a little problematic due to graph dependencies and the bulk associated with importing the entire graph suite
    <#if (Get-Module -FullyQualifiedName @{ModuleName = "Microsoft.Graph.Authentication"; RequiredVersion = "2.19.0" } -ListAvailable) {
        Write-Host "Supported Graph API version installed"
        Write-Host "Importing supported version"
    }
    else {
        Write-Host "Supported Graph API version not installed"
        Write-Host "Installing supported version"
        remove-module Microsoft.Graph -ErrorAction SilentlyContinue
        Install-module Microsoft.Graph.Authentication -requiredversion 2.19.0
        Install-module Microsoft.Graph.Identity.DirectoryManagement -requiredversion 2.19.0
        Install-module Microsoft.Graph.Applications -requiredversion 2.19.0
        Install-module Microsoft.Graph.Users requiredversion 2.19.0
    }
    Try {
        Write-Host "Importing Graph API"
        Import-module Microsoft.Graph -RequiredVersion 2.19.0 -scope Local -ErrorAction Stop
        Write-Host "Connecting to Graph API"
        Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All", "Domain.Read.All", "Directory.Read.All", "Application.Read.All"
    }
    catch {
        Write-Host "Failed to import and connect to Graph API"
    }#>
} 