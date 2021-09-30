function Remove-GraphManager {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [alias('UserID')][string] $ID,
        [string] $UserPrincipalName
    )
    if ($ID) {
        $URI = "/users/$ID/manager/`$ref"
    } else {
        $URI = "/users/$UserPrincipalName/manager/`$ref"
    }
    Invoke-Graph -Uri $URI -Method DELETE -Headers $Headers
}