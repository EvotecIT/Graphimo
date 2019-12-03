﻿function Connect-O365Graph {
    [cmdletBinding()]
    param(
        [string][alias('ClientID')] $ApplicationID,
        [string][alias('ClientSecret')] $ApplicationKey,
        [string] $TenantDomain,
        [ValidateSet("https://manage.office.com", "https://graph.microsoft.com")] $Resource = "https://manage.office.com"
    )
    $Body = @{
        grant_type    = "client_credentials"
        resource      = $Resource
        client_id     = $ApplicationID
        client_secret = $ApplicationKey
    }
    try {
        $Authorization = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$($TenantDomain)/oauth2/token" -Body $body -ErrorAction Stop
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning -Message "Connect-O365Graph - Error: $ErrorMessage"
    }
    if ($Authorization) {
        @{'Authorization' = "$($Authorization.token_type) $($Authorization.access_token)" }
    } else {
        $null
    }
}