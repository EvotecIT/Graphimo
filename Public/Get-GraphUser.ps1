function Get-GraphUser {
    [alias('Get-GraphUsers')]
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string[]] $Property,
        [validateSet('Guest')][string] $UserType,
        [uri] $PrimaryUri = 'https://graph.microsoft.com/v1.0',
        [switch] $AsHashTable
    )
    $UsersDictionary = [ordered]@{}
    $URI = '/users'
    if ($Property -and $UserType) {
        $URI = "$($URI)?" + "`$select=" + $($Property -join ",") + "&`$filter=userType eq 'Guest'"
    } elseif ($Property) {
        $URI = "$($URI)?" + "`$select=" + $($Property -join ",")
    } elseif ($UserType) {
        $URI = "$($URI)?" + "`$filter=userType eq 'Guest'"
    }
    if ($AsHashTable) {
        $Users = Invoke-O365Graph -Uri $URI -Method GET -Headers $Headers -PrimaryUri $PrimaryUri
        foreach ($User in $Users) {
            $UsersDictionary[$User.mail] = $User
        }
        $UsersDictionary
    } else {
        Invoke-O365Graph -Uri $URI -Method GET -Headers $Headers -PrimaryUri $PrimaryUri
    }
}