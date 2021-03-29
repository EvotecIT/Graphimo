function Remove-GraphUser {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [string] $UserID
    )
    if ($UserID) {
        $URI = "/users/$UserID"
    } else {
        $URI = "/users/$UserPrincipalName"
    }
    Invoke-O365Graph -Uri $URI -Method DELETE -Headers $Headers
}