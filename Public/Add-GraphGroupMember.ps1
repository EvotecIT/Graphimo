function Add-GraphGroupMember {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [parameter(Mandatory)][alias('GroupID')][string] $ID,
        [parameter(Mandatory)][string] $MemberID
    )

    $URI = "/groups/$ID/members/`$ref"

    $Body = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$MemberID"
    }

    Invoke-Graph -Uri $URI -Method POST -Headers $Headers -Body $Body
}