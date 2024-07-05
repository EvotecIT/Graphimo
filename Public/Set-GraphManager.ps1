function Set-GraphManager {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [alias('UserID')][string] $ID,
        [string] $UserPrincipalName,
        [string] $Name,
        [string] $ManagerID,
        [string] $ManagerDisplayName,
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
    $Body = [ordered]@{
        "@odata.id" = "https://graph.microsoft.com/v1.0/users/$ManagerID"
    }
    Invoke-Graphimo -Uri $URI -Method PUT -Headers $Headers -Body $Body -MgGraph:$MgGraph.IsPresent
}