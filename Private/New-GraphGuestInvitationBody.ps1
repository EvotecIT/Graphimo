function New-GraphGuestInvitationBody {
    [CmdletBinding()]
    param(
        [string] $Name,
        [Parameter(Mandatory)][string] $EmailAddress,
        [bool] $SendInvitationMessage,
        [string] $InviteRedirectUrl = 'https://portal.office.com',
        [bool] $ResetRedemption,
        [string] $InvitedUserID,
        [string] $UserType
    )

    $Body = [ordered] @{
        invitedUserDisplayName  = $Name
        invitedUserEmailAddress = $EmailAddress
        inviteRedirectUrl       = $InviteRedirectUrl
        sendInvitationMessage   = $SendInvitationMessage
        resetRedemption         = $ResetRedemption
    }
    if ($UserType) {
        $Body.invitedUserType = $UserType
    }
    if ($InvitedUserID) {
        $Body.invitedUser = @{
            id = $InvitedUserID
        }
    }
    $Body
}
