function Get-GraphUserCalendars {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName
    )
    Invoke-O365Graph -Uri "/users/$UserPrincipalName/calendars" -Method GET -Authorization $Headers
}