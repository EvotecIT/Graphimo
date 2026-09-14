function Import-GraphGuest {
    [cmdletBinding()]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $Name,
        [Parameter(Mandatory)][string] $EmailAddress,
        [switch] $SendInvitationMessage,
        [string] $InviteRedirectUrl = "https://portal.office.com",
        [switch] $ResetRedemption,
        [string] $InvitedUserID,
        [ValidateSet('Member', 'Guest')][string] $UserType,
        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    $URI = '/invitations'
    $Body = New-GraphGuestInvitationBody -Name $Name -EmailAddress $EmailAddress -SendInvitationMessage $SendInvitationMessage.IsPresent -InviteRedirectUrl $InviteRedirectUrl -ResetRedemption $ResetRedemption.IsPresent -InvitedUserID $InvitedUserID -UserType $UserType
    Invoke-Graphimo -Uri $URI -Method POST -Headers $Headers -Body $Body -MgGraph:$MgGraph.IsPresent
}
