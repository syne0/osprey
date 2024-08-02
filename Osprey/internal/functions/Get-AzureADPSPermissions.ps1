Function Get-AzureADPSPermissions {
    <# 
    .SYNOPSIS
        Lists delegated permissions (OAuth2PermissionGrants) and application permissions (AppRoleAssignments).
    .DESCRIPTION
        ists delegated permissions (OAuth2PermissionGrants) and application permissions (AppRoleAssignments).
    .PARAMETER DelegatedPermissions
        If set, will return delegated permissions. If neither this switch nor the ApplicationPermissions switch is set,
        both application and delegated permissions will be returned.
    .PARAMETER ApplicationPermissions
        If set, will return application permissions. If neither this switch nor the DelegatedPermissions switch is set,
        both application and delegated permissions will be returned.
    .PARAMETER UserProperties
        The list of properties of user objects to include in the output. Defaults to DisplayName only.
    .PARAMETER ServicePrincipalProperties
        The list of properties of service principals (i.e. apps) to include in the output. Defaults to DisplayName only.
    .PARAMETER ShowProgress
        Whether or not to display a progress bar when retrieving application permissions (which could take some time).
    .PARAMETER PrecacheSize
        The number of users to pre-load into a cache. For tenants with over a thousand users,
        increasing this may improve performance of the script.
    .EXAMPLE
        PS C:\> .\Get-AzureADPSPermissions.ps1 | Export-Csv -Path "permissions.csv" -NoTypeInformation
        Generates a CSV report of all permissions granted to all apps.
    .EXAMPLE
        PS C:\> .\Get-AzureADPSPermissions.ps1 -ApplicationPermissions -ShowProgress | Where-Object { $_.Permission -eq "Directory.Read.All" }
        Get all apps which have application permissions for Directory.Read.All.
    .EXAMPLE
        PS C:\> .\Get-AzureADPSPermissions.ps1 -UserProperties @("DisplayName", "UserPrincipalName", "Mail") -ServicePrincipalProperties @("DisplayName", "AppId")
        Gets all permissions granted to all apps and includes additional properties for users and service principals.
    
    .LINK
    https://gist.github.com/psignoret/9d73b00b377002456b24fcb808265c23
    
    #>
    
    [CmdletBinding()]
    param(
        [Alias("DelegatedPermissions")]
        [switch] $DelegatedPermissionGrants,
    
        [Alias("ApplicationPermissions")]
        [switch] $AppRoleAssignments,
    
        [string[]] $UserProperties = @("DisplayName"),
    
        [string[]] $ServicePrincipalProperties = @("DisplayName"),
    
        [switch] $ShowProgress,
    
        [int] $PrecacheSize = 999,
    
        [switch] $VeryVerbose
    )
    
    # Check that we've connected to Microsoft Graph
    $context = Get-MgContext
    if (-not $context)
    {
        throw "You must call Connect-MgGraph -Scopes `"Application.Read.All User.Read.All`" before running this script."
    }
    
    # If neither are selected, retrieve both
    if (-not ($DelegatedPermissionGrants -or $AppRoleAssignments))
    {
        $DelegatedPermissionGrants = $true
        $AppRoleAssignments = $true
    }
    
    # An in-memory cache of objects by {object ID} andy by {object class, object ID}
    $script:ObjectByObjectId = @{}
    $script:ObjectByObjectClassId = @{}
    
    # Function get object type
    function GetObjectType ($Object) {
        if ($Object) {
            $typeName = $Object.GetType().Name
            if ($typeName -match "MicrosoftGraph([A-Za-z]+)") {
                return $Matches[1]
            } else {
                Write-Warning "Unable to determine object type: '$($typeName)'"
                return "Unknown"
            }
        }
    } 
    
    # Function to add an object to the cache
    function CacheObject ($Object, $ObjectType = $null) {
        if ($Object) {
            if (-not $ObjectType) {
                $ObjectType = GetObjectType -Object $Object
            }
            if (-not $script:ObjectByObjectClassId.ContainsKey($ObjectType)) {
                $script:ObjectByObjectClassId[$ObjectType] = @{}
            }
            $script:ObjectByObjectClassId[$ObjectType][$Object.Id] = $Object
            $script:ObjectByObjectId[$Object.Id] = $Object
        }
    }
    
    $ODataObjectTypeMap = @{
        "#microsoft.graph.user" = @( "User", [Microsoft.Graph.PowerShell.Models.MicrosoftGraphUser] )
        "#microsoft.graph.group" = @( "Group", [Microsoft.Graph.PowerShell.Models.MicrosoftGraphGroup] )
        "#microsoft.graph.servicePrincipal" = @( "ServicePrincipal", [Microsoft.Graph.PowerShell.Models.MicrosoftGraphServicePrincipal] )
    }
    
    $ConsistencyLevelHeader = @{ "ConsistencyLevel" = "eventual" }
    
    # Function to retrieve an object from the cache (if it's there), or from Microsoft Graph (if not).
    function GetObjectByObjectId ($ObjectId) {
        if (-not $script:ObjectByObjectId.ContainsKey($ObjectId)) {
            if ($script:VeryVerbose) {
                Write-Verbose ("Querying Microsoft Graph for single object ID '{0}'" -f $ObjectId)
            }
            try {
                $object = Get-MgDirectoryObject -DirectoryObjectId $ObjectId
                ResolveTypeAndCacheObject -Object $object
            } catch {
                Write-Warning "Single object $($ObjectId) not found."
            }
        }
        return $script:ObjectByObjectId[$ObjectId]
    }
    
    # Function to retrieve the objects for a list of object IDs and store it in the cache
    function LoadObjectsByObjectIds ($ObjectIds, $objectTypes, $properties) {
        $ObjectIds = @($ObjectIds | Where-Object { -not $script:ObjectByObjectId.ContainsKey($_) })
        if ($ObjectIds) {
            if ($script:VeryVerbose) {
                Write-Verbose ("Fetching {0} objects by object IDs" -f $ObjectIds.Count)
            }
            try {
                Get-MgDirectoryObjectById -BodyParameter @{ 
                    "ids" = $ObjectIds
                    "types" = @("servicePrincipal", "user")
                } | ForEach-Object {
                    ResolveTypeAndCacheObject -Object $_
                }
            } catch {
                Write-Warning "Error fetching objects by object IDs."
            }
        }
    }
    
    # Get-MgDirectoryObject and Get-MgDirectoryObjectById are returned as generic directory objects, with the
    # type and most properties in AdditionalProperties. This function detects the type, casts the object to
    # that type, and puts it in the cache.
    function ResolveTypeAndCacheObject ($Object) {
        ($objectType, $type) = $script:ODataObjectTypeMap[$Object.AdditionalProperties.'@odata.type']
        if ($type) {
            $Object = $Object -as $type
            CacheObject -Object $object -ObjectType $objectType
        } else {
            Write-Warning "Unexpected object type: $($type)"
        }
    }
    
    $empty = @{} # Used later to avoid null checks
    
    $maxGetByIdsSize = 999 # Maximum number of object IDs to retrieve in bulk (e.g. using LoadObjectsByObjectIds)
    
    # If app role assignments are going to be loaded, we need to pre-load all possible resource service principals.
    # We do app role assignments first because if we're going to fetch all these service principals anyway, it's
    # better to fetch them before we start fetching delegated permission grants, so that they're already in the object cache.
    if ($AppRoleAssignments) {
    
        $startTime = [DateTime]::UtcNow
        Write-Verbose "Retrieving app role assignments..."
    
        # We use this filter to get service principals that might be the resource in an app role assignment. This will
        # ignore service principals for managed identities, which can be the assigned principal for an app role assignment
        # but currently can't be the resource service principal. 
        # $resourceServicePrincipalFilter = "appRoleAssignedTo/$count ge 1" # Sadly, not supported yet 😔
        $resourceServicePrincipalFilter = "servicePrincipalType ne 'ManagedIdentity'"
        $fetchServicePrincipalsPageSize = 999
    
        # This is just to retrieve the (approximate) count of potential resource service principals.
        Get-MgServicePrincipal -ConsistencyLevel "eventual" -CountVariable "countResourceServicePrincipals" `
                            -Select "id" -Filter $resourceServicePrincipalFilter -PageSize 1 | Out-Null
                            
        # TODO: Select only required properties
        Write-Verbose "Retrieving all $($countResourceServicePrincipals) potential resource service principals..."
        Get-MgServicePrincipal -ConsistencyLevel "eventual" -CountVariable "c" `
                            -Filter $resourceServicePrincipalFilter `
                            -PageSize $fetchServicePrincipalsPageSize -All | ForEach-Object { $i = 0 } {
    
            # Show the progress with estimated time remaining
            if ($ShowProgress -and $countResourceServicePrincipals) {
                Write-Progress -Activity "Loading all potential resource service principals..." `
                            -Status ("Retrieved {0}/{1} service principals" -f $i++, $countResourceServicePrincipals) `
                            -PercentComplete (($i / $countResourceServicePrincipals) * 100)
            }
    
            # Add the retrieved service principal to a cache
            CacheObject -Object $_ -ObjectType "ServicePrincipal"
        }
    
        # We need to make a copy of the list of possible resource service principals because later we'll need
        # to enumerate it, and (1) we want to make sure it only includes the possible resource service
        # principals, not client service principals that may have been retrieved when retrieving delegated
        # permission grants, and (2) as we enumerate through these, we'll possibly be fetching additional
        # service principals that we'll want to place in the cache, and we can't modify a collection that's
        # being enumerated.
        $resourceServicePrincipals = $script:ObjectByObjectClassId['ServicePrincipal'].Values | ForEach-Object { $_ }
        Write-Progress -Activity "Loading all potential resource service principals..." -Completed
    
        $clientIsNeeded = $ServicePrincipalProperties.Count -gt 0
        $pendingAssignments = {@()}.Invoke()
        $pendingIds = [Collections.Generic.HashSet[string]]::new()
    
        # Iterate over all potential resource ServicePrincipal objects and get app role assignments
        Write-Verbose "Fetching appRoleAssignedTo for each potential resource service principal..."
        $resourceServicePrincipals | ForEach-Object { $i = 0 } {
            if ($ShowProgress) {
                Write-Progress -Activity "Retrieving app role assignments..." `
                            -Status ("Checked {0}/{1} service principals" -f $i++, $countResourceServicePrincipals) `
                            -PercentComplete (($i / $countResourceServicePrincipals) * 100)
            }
            $sp = $_
            Get-MgServicePrincipalAppRoleAssignedTo -ServicePrincipalId $sp.Id -PageSize 999 -All `
            | Where-Object { $_.PrincipalType -eq "ServicePrincipal" }
    
        } | ForEach-Object -Begin { } -Process {
    
            # In this first pass over assignments, we collect assignments with unresolved objects until we have enough
            # unresolved objects to make a getByIds request. When we do, we make the getByIds request, load the results
            # into the cache, then "release" these assignments down the pipe, knowing their dependencies are resolved.
    
            $assignment = $_
    
            $resourceIsResolved = $script:ObjectByObjectId.ContainsKey($assignment.ResourceId)
            $clientIsResolved = (-not $clientIsNeeded) -or $script:ObjectByObjectId.ContainsKey($assignment.PrincipalId)
    
            if ($resourceIsResolved -and $clientIsResolved) {
                # Everything that's needed is available
                $assignment
            } else {
                # We don't have everything we need. Set aside the pending assignment, and queue up the object IDs to retrieve
                $pendingAssignments.Add($assignment)
                if (-not $resourceIsResolved) {
                    $pendingIds.Add($assignment.ResourceId) | Out-Null
                }
                if (-not $clientIsResolved) {
                    $pendingIds.Add($assignment.PrincipalId) | Out-Null
                }
    
                if ($pendingIds.Count -gt ($maxGetByIdsSize - 2)) {
                    # Now that we have a batch of object IDs to retrieve,
                    # fetch them and then emit the pending assignments.
                    LoadObjectsByObjectIds -ObjectIds $pendingIds
                    $pendingIds.Clear()
                    $pendingAssignments | ForEach-Object { $_ }
                    $pendingAssignments.Clear()
                }
            }
        } -End {
            if ($pendingIds.Count) {
                LoadObjectsByObjectIds -ObjectIds $pendingIds
                $pendingIds.Clear()
                $pendingAssignments | % { $_ }
                $pendingAssignments.Clear()
            }
    
        } | ForEach-Object {
    
            # At this point, we have the assignment and both the client and resource service principal
            $assignment = $_
    
            $resource = GetObjectByObjectId -ObjectId $assignment.ResourceId
            $appRole = $resource.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
    
            $grantDetails = [ordered]@{
                "PermissionType" = "Application"
                "ClientObjectId" = $assignment.PrincipalId
                "ResourceObjectId" = $assignment.ResourceId
                "PermissionId" = $assignment.AppRoleId
                "Permission" = $appRole.Value
            }
    
            # Add properties for client and resource service principals
            if ($ServicePrincipalProperties.Count -gt 0) {
    
                $client = GetObjectByObjectId -ObjectId $assignment.PrincipalId
    
                $insertAtClient = 2
                $insertAtResource = 3
                foreach ($propertyName in $ServicePrincipalProperties) {
                    $grantDetails.Insert($insertAtClient++, "Client$($propertyName)", $client.$propertyName)
                    $insertAtResource++
                    $grantDetails.Insert($insertAtResource, "Resource$($propertyName)", $resource.$propertyName)
                    $insertAtResource ++
                }
            }
    
            New-Object PSObject -Property $grantDetails
        }
    
        $endTime = [DateTime]::UtcNow
        Write-Verbose "Done retrieving app role assignments. Duration: $(($endTime - $startTime).TotalSeconds) seconds"
    }
    
    if ($DelegatedPermissionGrants) {
    
        $startTime = [DateTime]::UtcNow
    
        $pendingGrants = {@()}.Invoke()
        $pendingIds = [Collections.Generic.HashSet[string]]::new()
    
        # Get one page of User objects and add to the cache
        Write-Verbose ("Retrieving up to {0} user objects..." -f $PrecacheSize)
        Get-MgUser -Top $PrecacheSize | Where-Object {
            CacheObject -Object $_ -ObjectType "User"
        }
    
        # Get all existing delegated permission grnats, get the client, resource and scope details
        Write-Verbose "Retrieving delegated permission grants..."
    
        # As of module version 2.15.0, Get-MgOauth2PermissionGrant doesn't have the -ConsistencyLevel switch,
        # but it does support the -Header parameter, so we can manually add the required header.  
        Get-MgOauth2PermissionGrant -Header $ConsistencyLevelHeader -CountVariable "c" -PageSize 999 -All  `
        | ForEach-Object -Begin { } -Process {
            
            $grant = $_
    
            # Collect pending objects and emit grants when ready
            $resourceIsResolved = $script:ObjectByObjectId.ContainsKey($grant.ResourceId)
            $clientIsResolved = $script:ObjectByObjectId.ContainsKey($grant.ClientId)
            $userIsResolved = (-not $grant.PrincipalId) -or ($grant.PrincipalId -and $script:ObjectByObjectId.ContainsKey($grant.PrincipalId))
    
            if ($resourceIsResolved -and $clientIsResolved -and $userIsResolved) {
                # Everything that's needed is available
                $grant
            } else {
                # We don't have everything we need. Set aside the pending grant, and queue up the object IDs to retrieve
                $pendingGrants.Add($grant)
                if (-not $resourceIsResolved) {
                    $pendingIds.Add($grant.ResourceId) | Out-Null
                }
                if (-not $clientIsResolved) {
                    $pendingIds.Add($grant.ClientId) | Out-Null
                }
                if (-not $userIsResolved) {
                    $pendingIds.Add($grant.PrincipalId) | Out-Null
                }
    
                if ($pendingIds.Count -gt ($maxGetByIdsSize - 3)) {
                    # Now that we have a batch of object IDs to retrieve,
                    # fetch them and then emit the pending grants.
                    LoadObjectsByObjectIds -ObjectIds $pendingIds
                    $pendingIds.Clear()
                    $pendingGrants | % { $_ }
                    $pendingGrants.Clear()
                }
            }
        } -End {
            if ($pendingIds.Count) {
                LoadObjectsByObjectIds -ObjectIds $pendingIds
                $pendingIds.Clear()
                $pendingGrants | % { $_ }
                $pendingGrants.Clear()
            }
        } | ForEach-Object {
            $grant = $_
            if ($grant.Scope) {
                $grant.Scope.Split(" ") | Where-Object { $_ } | ForEach-Object {
    
                    $scope = $_
    
                    $grantDetails =  [ordered]@{
                        "PermissionType" = "Delegated"
                        "ClientObjectId" = $grant.ClientId
                        "ResourceObjectId" = $grant.ResourceId
                        "Permission" = $scope
                        "ConsentType" = $grant.ConsentType
                        "PrincipalObjectId" = $grant.PrincipalId
                    }
    
                    # Add properties for client and resource service principals
                    if ($ServicePrincipalProperties.Count -gt 0) {
    
                        $client = GetObjectByObjectId -ObjectId $grant.ClientId
                        $resource = GetObjectByObjectId -ObjectId $grant.ResourceId
    
                        $insertAtClient = 2
                        $insertAtResource = 3
                        foreach ($propertyName in $ServicePrincipalProperties) {
                            $grantDetails.Insert($insertAtClient++, "Client$propertyName", $client.$propertyName)
                            $insertAtResource++
                            $grantDetails.Insert($insertAtResource, "Resource$propertyName", $resource.$propertyName)
                            $insertAtResource ++
                        }
                    }
    
                    # Add properties for principal (will all be null if there's no principal)
                    if ($UserProperties.Count -gt 0) {
    
                        $principal = $empty
                        if ($grant.PrincipalId) {
                            $principal = GetObjectByObjectId -ObjectId $grant.PrincipalId
                        }
    
                        foreach ($propertyName in $UserProperties) {
                            $grantDetails["Principal$propertyName"] = $principal.$propertyName
                        }
                    }
    
                    Return New-Object PSObject -Property $grantDetails
                }
            }
        }
    }
    }