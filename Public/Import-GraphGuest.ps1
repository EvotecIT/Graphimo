function Import-GraphGuest {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $Name,
        [Parameter(Mandatory)][string] $EmailAddress,
        [switch] $SendInvitationMessage,
        [string] $InviteRedirectUrl = "https://portal.office.com",
        [switch] $ResetRedemption,
        [string] $InvitedUserID,
        [ValidateSet('Member', 'Guest')][string] $UserType
    )
    $URI = '/invitations'
    $body = [ordered]@{
        'invitedUserDisplayName'  = $Name
        'invitedUserEmailAddress' = $EmailAddress
        'inviteRedirectUrl'       = $InviteRedirectUrl
        'sendInvitationMessage'   = $SendInvitationMessage.IsPresent
        'resetRedemption'         = $ResetRedemption.IsPresent
    }
    if ($UserType) {
        $Body['invitedUserType'] = $UserType
    }
    if ($InvitedUserID) {
        $Body['invitedUser'] = @{
            'id' = $InvitedUserID
        }
    }
    Invoke-Graphimo -Uri $URI -Method POST -Headers $Headers -Body $Body
}