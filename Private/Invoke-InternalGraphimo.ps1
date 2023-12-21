function Invoke-InternalGraphimo {
    [CmdletBinding()]
    param(
        [Array] $OutputQuery,
        [int] $First,
        [int] $CurrentCount,
        [string] $CountVariable
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
            return $FoundUsers
        } elseif ($FoundUsers.Count -gt $First) {
            $FoundUsers = $FoundUsers | Select-Object -First $First
            return $FoundUsers
        } else {
            $First = $First - $FoundUsers.Count
            $FoundUsers
        }
    } else {
        $FoundUsers
    }
}