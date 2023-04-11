function Invoke-InternalGraphimo {
    [CmdletBinding()]
    param(
        [Array] $OutputQuery,
        [int] $First,
        [int] $CurrentCount
    )
    if ($OutputQuery.value) {
        $FoundUsers = $OutputQuery.value
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