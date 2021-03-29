function Get-GraphUser {
    [alias('Get-GraphUsers')]
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string[]] $Property,
        [validateSet('Guest')][string] $UserType
    )

    $URI = '/users'
    if ($Property -and $UserType) {
        $URI = "$($URI)?" + "`$select=" + $($Property -join ",") + "&`$filter=userType eq 'Guest'"
    } elseif ($Property) {
        $URI = "$($URI)?" + "`$select=" + $($Property -join ",")
    } elseif ($UserType) {
        $URI = "$($URI)?" + "`$filter=userType eq 'Guest'"
    }

    Invoke-O365Graph -Uri $URI -Method GET -Headers $Headers
}