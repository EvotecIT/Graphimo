function Remove-GraphUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [alias('UserID')][string] $ID,
        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    if ($ID) {
        $URI = "/users/$ID"
    } else {
        $URI = "/users/$UserPrincipalName"
    }
    Invoke-Graphimo -Uri $URI -Method DELETE -Headers $Headers -MgGraph:$MgGraph.IsPresent
}