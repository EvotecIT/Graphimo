function Get-GraphUsers {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers
    )
    Invoke-O365Graph -Uri "/users/" -Method GET -Authorization $Headers
}