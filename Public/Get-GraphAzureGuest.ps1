function Get-GraphAzureGuest {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [switch] $AsHashTable
    )
    $GuestsDictionary = [ordered]@{}
    $URI = "https://graph.microsoft.com/v1.0/users?`$filter=userType eq 'Guest'"
    if ($AsHashTable) {
        $Guests = Invoke-O365Graph -Uri $URI -Method GET -Headers $Authorization -FullUri
        foreach ($Guest in $Guests) {
            if ($AsHashTable) {
                $GuestsDictionary[$Guest.mail] = $Guest
            } else {
                $Guest
            }
        }
        $GuestsDictionary
    } else {
        Invoke-O365Graph -Uri $URI -Method GET -Headers $Authorization -FullUri
    }
}