function Remove-GraphMailboxCalendarEvent {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [string] $CalendarID,
        [string] $EventID,
        [switch] $All
    )
    if ($All) {
        [int] $FinalDay = 30000
        [int] $StartDay = -1800
        do {
            $EndDay = $StartDay + 1800
            $Date1 = (Get-Date).AddDays($StartDay)
            $Date2 = (Get-Date).AddDays($EndDay)
            $CalendarEvents = Get-GraphCalendarEvents -UserPrincipalName $UserPrincipalName -Headers $Authorization -DateStart $Date1 -DateEnd $Date2 -CalendarID $CalendarID
            foreach ($Event in $CalendarEvents) {
                #Write-Color "Deleting $URIEvent", ' ', $Calendar.Name -Color Yellow, White, Blue
                Remove-GraphMailboxCalendarEvent -Headers $Headers -UserPrincipalName $UserPrincipalName -CalendarID $CalendarID -EventID $Event.ID
            }
            $StartDay = $StartDay + 1800
        } while ($EndDay -lt $FinalDay)
    } else {
        if ($EventID) {
            $URIEvent = "/users/$UserPrincipalName/calendars/$($CalendarID)/events/$($EventID)"
            #Write-Color "Deleting $URIEvent", ' ', $Calendar.Name -Color Yellow, White, Blue
            Invoke-O365Graph -Uri $URIEvent -Method DELETE -Authorization $Authorization
        }
    }
}