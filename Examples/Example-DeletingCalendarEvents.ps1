$ApplicationID = '3f53f084'
$DirectoryID = 'e486b948'
$ApplicationSecret = '3=bAa?' # expires  12/2/2020
$Authorization = Connect-O365Graph -ApplicationID $ApplicationID -ApplicationKey $ApplicationSecret -TenantDomain $DirectoryID -Resource 'https://graph.microsoft.com'
$Users = Get-GraphUsers -Authorization $Authorization #| Sort-Object -Descending mail #{Get-Random}
$UserPrincipalName = ''
$Users.userPrincipalName | ForEach-Object -Parallel {
    $UserPrincipalName = $_
    $AuthorizationCalendar = Connect-O365Graph -ApplicationID $Using:ApplicationID -ApplicationKey $Using:ApplicationSecret -TenantDomain $Using:DirectoryID -Resource 'https://graph.microsoft.com'
    Write-Color -Text '[>] ', 'Processing user ', $UserPrincipalName -Color Yellow, White, Yellow, White, Yellow, White, Yellow, White -ShowTime
    $Calendars = Get-GraphUserCalendars -Headers $AuthorizationCalendar -UserPrincipalName $UserPrincipalName
    Write-Color -Text '[>] ', 'Processing user ', $UserPrincipalName, ' calendars count ', $Calendars.Count -Color Yellow, White, Yellow, White, Yellow, White, Yellow, White -ShowTime

    $ApplicationID = '3f53f0'
    $DirectoryID = 'e486b94'
    $ApplicationSecret = '3=bAa?@' # expires  12/2/2020

    $Calendars | ForEach-Object -Parallel {
        $Calendar = $_
        $Auth = Connect-O365Graph -ApplicationID $using:ApplicationID -ApplicationKey $using:ApplicationSecret -TenantDomain $using:DirectoryID -Resource 'https://graph.microsoft.com'
        if ($Calendar.Name -like '*the*.com') {
            Write-Color '[>] ', 'Processing user ', $using:UserPrincipalName, ' calendar ', $Calendar.Name, ' with calendar id ', $Calendar.id -Color Yellow, White, Green, White, Yellow, White, Yellow -ShowTime
            $DeleteStatus = Remove-GraphMailboxCalendar -Headers $Auth -CalendarID $Calendar.id -UserPrincipalName $using:UserPrincipalName
            if (-not $DeleteStatus) {
                Remove-GraphMailboxCalendarEvent -Headers $Auth -UserPrincipalName $using:UserPrincipalName -CalendarID $Calendar.id -All -Verbose -Batches 360
                Write-Color '[>] ', 'Deleting user calendar ', $using:UserPrincipalName, ' calendar ', $Calendar.Name, ' with calendar id ', $Calendar.id -Color Yellow, White, Green, White, Yellow, White, Yellow -ShowTime
                $DeleteStatus = Remove-GraphMailboxCalendar -Headers $Auth -CalendarID $Calendar.id -UserPrincipalName $using:UserPrincipalName
            }
        }
    } -ThrottleLimit 4
} -ThrottleLimit 4
