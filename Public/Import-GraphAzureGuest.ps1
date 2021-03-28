function Import-GraphAzureGuest {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $Name,
        [Parameter(Mandatory)][string] $EmailAddress,
        [switch] $SendInvitationMessage,
        [string] $InviteRedirectUrl = "https://portal.office.com"
    )
    $URI = '/invitations'
    $body = [ordered]@{
        'invitedUserDisplayName'  = $Name
        'invitedUserEmailAddress' = $EmailAddress
        'inviteRedirectUrl'       = $InviteRedirectUrl
        'sendInvitationMessage'   = $SendInvitationMessage.IsPresent
    }
    Invoke-O365Graph -Uri $URI -Method POST -Headers $Authorization -Body $Body
}