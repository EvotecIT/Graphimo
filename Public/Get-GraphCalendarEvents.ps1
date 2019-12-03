function Get-GraphCalendarEvents {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [string] $CalendarID,
        [datetime] $DateStart,
        [datetime] $DateEnd
    )
    $Date1 = (Get-Date $DateStart -UFormat '+%Y-%m-%dT%H:%M:%S.000Z')
    $Date2 = (Get-Date $DateEnd -UFormat '+%Y-%m-%dT%H:%M:%S.000Z')
    $URI = "/users/$UserPrincipalName/calendars/$($CalendarID)/calendarView?startDateTime=$Date1&endDateTime=$Date2"
    $OneCalendar = Invoke-O365Graph -Uri $URI -Method GET -Headers $Headers
    $OneCalendar
}