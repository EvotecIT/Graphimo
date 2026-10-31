function Connect-MsalToken {
    # MSAL owns token caching and expiry; a second client-ID-only cache can cross tenants or scopes.
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $MsalTokenSplat,
        [System.Collections.IDictionary] $Authorization,
        [int] $ExpiresTimeout = 30,
        [switch] $ForceRefesh
    )
    if ($Authorization.Splat) {
        $Splat = $Authorization.Splat
        try {
            $MsalToken = Get-MsalToken @Splat -ErrorAction Stop
        } catch {
            Write-Warning -Message "Connect-MsalToken - Couldn't execute Get-MsalToken. Error: $($_.Exception.Message)"
            return
        }
        [ordered] @{
            'MsalToken' = $MsalToken
            'Splat'     = $Authorization.Splat
        }
    } else {
        Write-Warning -Message "Connect-MsalToken - Using old authorization format without Splatting. No refresh of tokens will be available."
    }
}
