function Set-GraphManager {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [alias('UserID')][string] $ID,
        [string] $UserPrincipalName,
        [string] $Name,


        [string] $ManagerID,
        [string] $ManagerDisplayName

    )
    if ($ID) {
        $URI = "/users/$ID/manager/`$ref"
    } else {
        $URI = "/users/$UserPrincipalName/manager/`$ref"
    }
    $Body = [ordered]@{
        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$ManagerID"
    }
    Invoke-Graph -Uri $URI -Method PUT -Headers $Headers -Body $Body
}