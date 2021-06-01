function Remove-GraphGroupMember {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory, ParameterSetName = 'All')]
        [parameter(Mandatory, ParameterSetName = 'PerID')]
        [parameter(Mandatory, ParameterSetName = 'BySearch')]
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [parameter(Mandatory, ParameterSetName = 'All')]
        [parameter(Mandatory, ParameterSetName = 'PerID')]
        [parameter(Mandatory, ParameterSetName = 'BySearch')]
        [alias('GroupID')][string] $ID,

        [parameter(Mandatory, ParameterSetName = 'PerID')][string] $MemberID,

        [parameter(Mandatory, ParameterSetName = 'BySearch')][string] $Search,

        [parameter(ParameterSetName = 'All')][switch] $All
    )
    if ($All) {
        # Lets remove all, but to do that we need to know who to remove
        $Users = Get-GraphGroupMember -Id $ID -Headers $Authorization -Verbose -Property id, displayName
        foreach ($User in $Users) {
            $URI = "/groups/$ID/members/$($User.id)/`$ref"
            $Status = Invoke-Graph -Uri $URI -Method DELETE -Headers $Headers
            $Status
        }
    } elseif ($Search) {
        $Users = Get-GraphGroupMember -Id $ID -Headers $Authorization -Verbose -Property id, displayName -Search $Search
        foreach ($User in $Users) {
            $URI = "/groups/$ID/members/$($User.id)/`$ref"
            $Status = Invoke-Graph -Uri $URI -Method DELETE -Headers $Headers
            $Status
        }
    } else {
        # Lets delete just one record
        $URI = "/groups/$ID/members/$MemberID/`$ref"
        Invoke-Graph -Uri $URI -Method DELETE -Headers $Headers
    }
}