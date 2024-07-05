function Remove-GraphManager {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [alias('UserID')][string] $ID,
        [string] $UserPrincipalName,
        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    if ($ID) {
        $URI = "/users/$ID/manager/`$ref"
    } else {
        $URI = "/users/$UserPrincipalName/manager/`$ref"
    }
    Invoke-Graphimo -Uri $URI -Method DELETE -Headers $Headers -MgGraph:$MgGraph.IsPresent
}