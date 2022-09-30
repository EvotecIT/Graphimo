function Connect-MsalToken {
    [cmdletBinding()]
    param(
        [System.Collections.IDictionary] $MsalTokenSplat,
        [System.Collections.IDictionary] $Authorization,
        [int] $ExpiresTimeout = 30,
        [switch] $ForceRefesh
    )
    if (-not $Script:AuthorizationCache) {
        $Script:AuthorizationCache = [ordered] @{}
    }
    if ($Authorization.Splat) {
        $ApplicationID = $Authorization.Splat.ClientId
        if ($Script:AuthorizationCache[$ApplicationID] -and -not $ForceRefesh) {
            if ($Script:AuthorizationCache[$ApplicationID].MsalToken.ExpiresOn.UtcDateTime -gt ([datetime]::UtcNow).AddSeconds($ExpiresTimeout)) {
                Write-Verbose "Connect-MsalToken - Using cache for $ApplicationID"
                return $Script:AuthorizationCache[$ApplicationID]
            }
        }
        $Splat = $Authorization.Splat
        try {
            $MsalToken = Get-MsalToken @Splat -ErrorAction Stop
        } catch {
            Write-Warning -Message "Connect-MsalToken - Couldn't execute Get-MsalToken. Error: $($_.Exception.Message)"
            return
        }
        $Script:AuthorizationCache[$ApplicationID] = [ordered] @{
            'MsalToken' = $MsalToken
            'Splat'     = $Authorization.Splat
        }
        $Script:AuthorizationCache[$ApplicationID]
    } else {
        Write-Warning -Message "Connect-MsalToken - Using old authorization format without Splatting. No refresh of tokens will be available."
    }
}