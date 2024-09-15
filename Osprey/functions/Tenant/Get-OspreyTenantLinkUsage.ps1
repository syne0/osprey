<#
.DESCRIPTION
    Gets a report of all link usage for the investigation period. Exports additional report highlighting anonymous sharing.
    Flags access to sensitive files.
.OUTPUTS
    AllLinkUsage.csv
    AnonLinkUsage.csv
    _investigate_SharingLinkUsage.csv
#>
Function Get-OspreyTenantLinkUsage {
    
    #if osp not initialized, chastise the user
    if ([string]::IsNullOrEmpty($Osprey.FilePath)) {
        Out-LogFile "You need to initialize Osprey before you can do this. Go run Start-Osprey and then try again."
    }
    else {
        Test-EXOConnection

        Out-LogFile "Searching Unified Audit Log for sharing link usage events."
        $LinkUsage = Get-AllUnifiedAuditLogEntry -UnifiedSearch ("Search-UnifiedAuditLog -operation SharingLinkUsed")

        #if we found nothing
        if ($null -eq $LinkUsage) {
            Out-LogFile "No link usage found."
        }
        else {
            Out-LogFile ("Found " + $LinkUsage.identity.Count + " link usage records") 

            #we found something
            #set blank array for anon log and false for the flag to do anon
            $AnonLog = @()
            $DoAnonLog = $false
            
            #foreach link usage found
            $LinkUsageReport = foreach ($link in $LinkUsage) {
                #insert LoZ joke here
                $link1 = $link.auditdata | ConvertFrom-Json
                [PSCustomObject]@{
                    CreationTime     = $link1.CreationTime
                    RecordId         = $link1.Id
                    Operation        = $link1.Operation
                    Workload         = $link1.Workload
                    UserID           = $link1.UserID
                    ClientIP         = $link1.ClientIP
                    UserAgent        = $link1.UserAgent #TODO: I believe this can be blank sometimes so do proper error handling thanks
                    SharingLinkScope = $link1.SharingLinkScope
                    SiteURL          = $link1.SiteURL
                    FullURL          = $link1.ObjectID
                    SourceFileName   = $link1.SourceFileName
                }
                #if an anyone link is found i'll flip the flag to do it later
                if ($link1.SharingLinkScope -like "Anyone") {
                    $DoAnonLog = $true
                }
            }
            $LinkUsageReport | Out-MultipleFileType -FilePreFix "AllLinkUsage" -csv -json

            if ($DoAnonLog) {
                Out-LogFile "Anonymous link usage found. Pulling out results into additional file."
                foreach ($link in $LinkUsageReport) {
                    if ($link.SharingLinkScope -like "anyone") {
                        $AnonLog += $link
                    }
                }
                $AnonLog | Out-MultipleFileType -FilePrefix "AnonLinkUsage" -csv -json
            }

            #flagging sus link usage
            $InvestigateLog = @() #set empty array
            Foreach ($link in $LinkUsageReport) {
                $Investigate = $false #set flag back to false
                
                #see if the filename matches specific keywords
                if ($link.SourceFileName -like "*credit*" -or $link.SourceFileName -like "*visa*" -or $link.SourceFileName -like "*debit*" -or $link.SourceFileName -like "*passport*" -or $link.SourceFileName -like "*license*" -or $link.SourceFileName -like "*SSN*" -or $link.SourceFileName -like "*SIN*" -or $link.SourceFileName -like "*password*" -or $link.SourceFileName -like "*login*" -or $link.SourceFileName -like "*invoice*" -or $link.SourceFileName -like "*collection*" -or $link.SourceFileName -like "*receivable*"  ) { $investigate = $true }
                
                #if it does, add it into the log array
                if ($Investigate) {
                    $InvestigateLog += $link
                }

            }
            if ($InvestigateLog.RecordId.count -ge 1) { 
                #say we found something and output the file
                Out-LogFile ("Access to potentially sensitive files via sharing links found! Please review access to determine if legitimate.") -notice
                $InvestigateLog | Out-MultipleFileType -fileprefix "_Investigate_SharingLinkUsage" -csv -notice
            }

        }
    }
}
          <#⠀⠀⠀⠀
    ⠀⠀⠀⠀⣼⣿⣿⣧⠀⠀⠀⠀
    ⠀⠀⠀⠾⠿⠿⠿⠿⠷⠀⠀⠀
    ⠀⠀⣼⣆⠀⠀⠀⠀⣰⣧⠀⠀
    ⠀⣼⣿⣿⣆⠀⠀⣰⣿⣿⣧⠀
    ⠾⠟⠿⠿⠿⠧⠼⠿⠿⠿#>