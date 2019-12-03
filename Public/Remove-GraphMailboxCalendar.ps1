function Remove-GraphMailboxCalendar {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [string] $CalendarID
    )
    $URI = "/users/$UserPrincipalName/calendars/$($CalendarID)"
    Invoke-O365Graph -Uri $URI -Method DELETE -Headers $Headers
}