function Add-GraphGroupMember {
    [cmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Headers')]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [parameter(Mandatory)][alias('GroupID')][string] $ID,
        [parameter(Mandatory)][string] $MemberID,
        [parameter()][switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    $URI = "/groups/$ID/members/`$ref"

    $Body = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$MemberID"
    }

    Invoke-Graphimo -Uri $URI -Method POST -Headers $Headers -Body $Body -MgGraph:$MgGraph.IsPresent
}