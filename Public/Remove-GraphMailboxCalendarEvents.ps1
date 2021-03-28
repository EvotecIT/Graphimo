function Remove-GraphMailboxCalendarEvent {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $UserPrincipalName,
        [string] $CalendarID,
        [string] $EventID,
        [int] $Batches = 30,
        [switch] $All
    )
    if ($All) {
        [int] $StartDay = -9200
        [int] $FinalDay = 60000
        do {
            $EndDay = $StartDay + $Batches
            $Date1 = (Get-Date).AddDays($StartDay)
            $Date2 = (Get-Date).AddDays($EndDay)
            #Write-Verbose "Remove-GraphMailboxCalendarEvent - Processing user $UserPrincipalName for $CalendarID from $Date1 to $Date2"
            #Write-Color "Remove-GraphMailboxCalendarEvent - Processing user $UserPrincipalName for $CalendarID from $Date1 to $Date2" -Color DarkMagenta
            $CalendarEvents = Get-GraphCalendarEvents -UserPrincipalName $UserPrincipalName -Headers $Headers -DateStart $Date1 -DateEnd $Date2 -CalendarID $CalendarID
            #Write-Color "Count of Events ", $CalendarEvents.Count, ' for dates ', $Date1, ' and ', $Date2 -Color yellow, white, yellow, white, yellow, white, yellow
            #Write-Color "Remove-GraphMailboxCalendarEvent - Processing user $UserPrincipalName / found $($CalendarEvents.Count) events from $Date1 to $Date2" -Color Blue
            Write-Verbose "Remove-GraphMailboxCalendarEvent - Processing user $UserPrincipalName / found $($CalendarEvents.Count) events from $Date1 to $Date2"
            foreach ($Event in $CalendarEvents) {
                # Write-Color "Deleting $UserPrincipalName $URIEvent $CalendarID $EventID" -Color Yellow, White, Blue
                $Output = Remove-GraphMailboxCalendarEvent -Headers $Headers -UserPrincipalName $UserPrincipalName -CalendarID $CalendarID -EventID $Event.ID
            }
            $StartDay = $StartDay + $Batches
        } while ($EndDay -lt $FinalDay)
    } else {
        if ($EventID) {
            $URIEvent = "/users/$UserPrincipalName/calendars/$($CalendarID)/events/$($EventID)"
            #Write-Verbose "Remove-GraphMailboxCalendarEvent - Processing user $UserPrincipalName / deleting event $($EventID)"
            #Write-Color "Deleting $URIEvent" -Color Yellow, White, Blue
            Invoke-O365Graph -Uri $URIEvent -Method DELETE -Headers $Headers
        }
    }
}