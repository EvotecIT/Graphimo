function Remove-GraphUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [alias('UserID')][string] $ID
    )
    if ($ID) {
        $URI = "/users/$ID"
    } else {
        $URI = "/users/$UserPrincipalName"
    }
    Invoke-Graph -Uri $URI -Method DELETE -Headers $Headers
}