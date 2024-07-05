function Invoke-InternalGraphimo {
    [CmdletBinding()]
    param(
        [Array] $OutputQuery,
        [int] $First,
        [int] $CurrentCount,
        [string] $CountVariable,
        [switch] $MgGraph
    )
    if ($OutputQuery.value) {
        $FoundUsers = $OutputQuery.value
    }
    if ($CountVariable) {
        Set-Variable -Name $CountVariable -Value $OutputQuery.'@odata.count' -Scope Global
    }
    if ($First) {
        if ($CurrentCount) {
            $First = $First - $CurrentCount
        }
        if ($FoundUsers.Count -eq $First) {
        } elseif ($FoundUsers.Count -gt $First) {
            $FoundUsers = $FoundUsers | Select-Object -First $First
        } else {
            $First = $First - $FoundUsers.Count
        }
    }
    if ($MgGraph -or $Script:MgGraphAuthenticated -eq $true) {
        foreach ($Object in $FoundUsers) {
            [PSCustomObject] $Object
        }
    } else {
        $FoundUsers
    }
}