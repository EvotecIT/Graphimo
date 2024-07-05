function Remove-GraphGroupMember {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(ParameterSetName = 'All')]
        [parameter(ParameterSetName = 'PerID')]
        [parameter(ParameterSetName = 'BySearch')]
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [parameter(Mandatory, ParameterSetName = 'All')]
        [parameter(Mandatory, ParameterSetName = 'PerID')]
        [parameter(Mandatory, ParameterSetName = 'BySearch')]
        [alias('GroupID')][string] $ID,

        [parameter(Mandatory, ParameterSetName = 'PerID')][string] $MemberID,

        [parameter(Mandatory, ParameterSetName = 'BySearch')][string] $Search,

        [parameter(ParameterSetName = 'All')][switch] $All,
        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    if ($All) {
        # Lets remove all, but to do that we need to know who to remove
        $Users = Get-GraphGroupMember -Id $ID -Headers $Headers -Verbose -Property id, displayName -MgGraph:$MgGraph.IsPresent
        foreach ($User in $Users) {
            $URI = "/groups/$ID/members/$($User.id)/`$ref"
            Invoke-Graphimo -Uri $URI -Method DELETE -Headers $Headers
        }
    } elseif ($Search) {
        $Users = Get-GraphGroupMember -Id $ID -Headers $Headers -Verbose -Property id, displayName -Search $Search -MgGraph:$MgGraph.IsPresent
        foreach ($User in $Users) {
            $URI = "/groups/$ID/members/$($User.id)/`$ref"
            Invoke-Graphimo -Uri $URI -Method DELETE -Headers $Headers -MgGraph:$MgGraph.IsPresent
        }
    } else {
        # Lets delete just one record
        $URI = "/groups/$ID/members/$MemberID/`$ref"
        Invoke-Graphimo -Uri $URI -Method DELETE -Headers $Headers -MgGraph:$MgGraph.IsPresent
    }
}