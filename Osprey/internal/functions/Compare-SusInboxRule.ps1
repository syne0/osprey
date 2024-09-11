<#
.SYNOPSIS
    Determines if an inbox rule is potentially suspicious
.DESCRIPTION
    Determines if an inbox rule is potentially suspicious
.PARAMETER InboxRule
    The inbox rule data
#> 
Function Compare-SusInboxRule {
    param
    (
        [Parameter(Mandatory = $true)]
        [array]$InboxRule
    )

    $investigate = $false
    if ((($InboxRule.DeleteMessage -eq $true) -and ($InboxRule.MarkAsRead -eq $true)) -or ($InboxRule.DeleteMessage -eq $true)) { $Investigate = $true }
    if (!([string]::IsNullOrEmpty($InboxRule.ForwardAsAttachmentTo))) { $Investigate = $true }
    if (!([string]::IsNullOrEmpty($InboxRule.ForwardTo))) { $Investigate = $true }
    if (!([string]::IsNullOrEmpty($InboxRule.RedirectTo))) { $Investigate = $true}
    if ($InboxRule.MoveToFolder -in "Archive", "Conversation History", "RSS Subscription") { $Investigate = $true }
    if ($InboxRule.RuleName -like '*.*' -or $InboxRule.RuleName -like '*,*' -or $InboxRule.RuleName -like '*"*'){ $Investigate = $true }

    return $Investigate
}