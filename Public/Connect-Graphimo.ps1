function Connect-Graphimo {
    <#
    .SYNOPSIS
    Acquires or reuses authorization for a specific Microsoft Graph identity.
    .DESCRIPTION
    Caches direct client-credential tokens by tenant, application and resource, and
    reuses them only while the configured secret still matches. MSAL handles its own
    token cache. Existing Microsoft Graph SDK connections remain SDK-managed.
    .PARAMETER ApplicationID
    Application client ID for direct client-credential authentication.
    .PARAMETER ApplicationKey
    Client secret. Prefer a protected credential source when storing configuration.
    .PARAMETER ApplicationKeyEncrypted
    Client secret protected with ConvertFrom-SecureString for the current environment.
    .PARAMETER Credential
    Client ID as the username and client secret as the password.
    .PARAMETER TenantDomain
    Tenant ID or verified tenant domain used for token acquisition.
    .PARAMETER Resource
    Resource or scope for the requested token.
    .PARAMETER ExpiresTimeout
    Number of seconds before expiration at which a direct token must be renewed.
    .PARAMETER ForceRefesh
    Bypasses Graphimo's direct token cache. The spelling is retained for compatibility.
    MSAL provider options, including ForceRefresh, can be supplied in MsalToken.
    .PARAMETER MsalToken
    Parameters passed to Get-MsalToken. MSAL controls identity selection, caching and expiry.
    .PARAMETER MsGraphConfiguration
    Parameters passed to Connect-MgGraph.
    .PARAMETER MgGraph
    Uses a Microsoft Graph SDK connection that has already been established.
    .EXAMPLE
    $authorization = Connect-Graphimo -Credential $applicationCredential -TenantDomain 'contoso.onmicrosoft.com'
    Acquires application authorization from a protected credential supplied by the caller.
    .OUTPUTS
    System.Collections.IDictionary. Authorization and reconnect parameters for direct or MSAL authentication.
    SDK connection modes configure the current connection without returning this envelope.
    #>
    [cmdletBinding(DefaultParameterSetName = 'ClearText')]
    param(
        [parameter(Mandatory, ParameterSetName = 'Encrypted')]
        [parameter(Mandatory, ParameterSetName = 'ClearText')][string][alias('ClientID')] $ApplicationID,
        [parameter(Mandatory, ParameterSetName = 'ClearText')][string][alias('ClientSecret')] $ApplicationKey,
        [parameter(Mandatory, ParameterSetName = 'Encrypted')][string][alias('ClientSecretEncrypted')] $ApplicationKeyEncrypted,
        [parameter(Mandatory, ParameterSetName = 'Credential')][PSCredential] $Credential,

        [parameter(Mandatory, ParameterSetName = 'Encrypted')]
        [parameter(Mandatory, ParameterSetName = 'ClearText')]
        [parameter(Mandatory, ParameterSetName = 'Credential')]
        [string] $TenantDomain,

        [parameter(ParameterSetName = 'Encrypted')]
        [parameter(ParameterSetName = 'ClearText')]
        [parameter(ParameterSetName = 'Credential')]
        [ValidateSet("https://manage.office.com", "https://graph.microsoft.com", "https://graph.microsoft.com/beta", 'https://graph.microsoft.com/.default')] $Resource = 'https://graph.microsoft.com/.default',
        [int] $ExpiresTimeout = 30,
        [switch] $ForceRefesh,

        [parameter(Mandatory, ParameterSetName = 'MsalToken')][System.Collections.IDictionary] $MsalToken,
        [parameter(Mandatory, ParameterSetName = 'MsGraphConfiguration')]
        [System.Collections.IDictionary] $MsGraphConfiguration,

        [parameter(Mandatory, ParameterSetName = 'MsGraphConfigurationSwitch')]
        [switch] $MgGraph
    )
    # Comparison V1/V2 https://nicolgit.github.io/AzureAD-Endopoint-V1-vs-V2-comparison/

    if (-not $Script:AuthorizationCache) {
        $Script:AuthorizationCache = [ordered] @{}
    }

    if ($null -ne $MsGraphConfiguration -or $MgGraph.IsPresent) {
        if ($MgGraph.IsPresent) {
            # We use Microsoft.Graph module instead of Invoke-RestMethod
            # We assume the connection was done before this function was called
            $Script:MgGraphAuthenticated = $true
            return
        } else {
            if (-not $MsGraphConfiguration.ErrorAction) {
                $MsGraphConfiguration.ErrorAction = 'Stop'
            }
            try {
                Connect-MgGraph @MsGraphConfiguration
                $Script:MgGraphAuthenticated = $true
                return
            } catch {
                if ($ErrorActionPreference -eq 'Stop') {
                    throw
                }
                $Script:MgGraphAuthenticated = $null
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning -Message "Connect-Graphimo - Error: $ErrorMessage"
                return $false
            }
        }
    }

    if ($Credential) {
        $RestSplat = @{
            ErrorAction = 'Stop'
            Method      = 'POST'
            Body        = @{
                grant_type    = "client_credentials"
                client_id     = $Credential.UserName
                client_secret = $Credential.GetNetworkCredential().Password
            }
        }
    } elseif ($ApplicationKey -or $ApplicationKeyEncrypted) {
        if ($ApplicationKeyEncrypted) {
            try {
                $ApplicationKeyTemp = $ApplicationKeyEncrypted | ConvertTo-SecureString -ErrorAction Stop
            } catch {
                $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
                Write-Warning -Message "Connect-Graphimo - Error: $ErrorMessage"
                return
            }
            $ApplicationKey = [System.Net.NetworkCredential]::new([string]::Empty, $ApplicationKeyTemp).Password
        }
        $RestSplat = @{
            ErrorAction = 'Stop'
            Method      = 'POST'
            Body        = @{
                grant_type    = "client_credentials"
                client_id     = $ApplicationID
                client_secret = $ApplicationKey
            }
        }
    } elseif ($MsalToken) {
        $Authorization = @{
            Splat = $MsalToken
        }
        return Connect-MsalToken -Authorization $Authorization -ExpiresTimeout $ExpiresTimeout -ForceRefesh:$ForceRefesh
    }

    # JSON preserves tuple boundaries without putting a credential into the dictionary key.
    $CacheKey = ConvertTo-Json -InputObject @(
        $TenantDomain.Trim().ToLowerInvariant()
        $RestSplat.Body.client_id.ToLowerInvariant()
        $Resource
    ) -Compress
    $CachedAuthorization = $Script:AuthorizationCache[$CacheKey]
    if ($CachedAuthorization -and -not $ForceRefesh) {
        if ($CachedAuthorization.Authorization.ExpiresOn -gt [datetime]::UtcNow -and
            $CachedAuthorization.Credential -ceq $RestSplat.Body.client_secret) {
            Write-Verbose "Connect-Graphimo - Using cache for $ApplicationID"
            return $CachedAuthorization.Authorization
        }
    }

    if ($Resource -in 'https://graph.microsoft.com/.default', "https://graph.microsoft.com/beta") {
        # V2 Endpoint
        $RestSplat['Body']['scope'] = $Resource
        $RestSplat['Uri'] = "https://login.microsoftonline.com/$($TenantDomain)/oauth2/v2.0/token"
    } else {
        # V1 Endpoint
        $RestSplat['Body']['resource'] = $Resource
        $RestSplat['Uri'] = "https://login.microsoftonline.com/$($TenantDomain)/oauth2/token"
    }
    Write-Verbose "Connect-Graphimo - EndPoint $($RestSplat['Uri'])"
    try {
        $Authorization = Invoke-RestMethod @RestSplat -Verbose:$false
        $Key = [ordered] @{
            'Authorization' = "$($Authorization.token_type) $($Authorization.access_token)"
            'Extended'      = $Authorization
            'Error'         = ''
            'ExpiresOn'     = ([datetime]::UtcNow).AddSeconds($Authorization.expires_in - $ExpiresTimeout)
            'Splat'         = [ordered] @{
                ApplicationID  = $RestSplat['Body']['client_id']
                ApplicationKey = $RestSplat['Body']['client_secret']
                TenantDomain   = $TenantDomain
                Resource       = $Resource
            }
        }
        # Keep the acquisition credential separate from the mutable reconnect envelope returned to callers.
        $Script:AuthorizationCache[$CacheKey] = @{
            Credential    = $RestSplat.Body.client_secret
            Authorization = $Key
        }
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning -Message "Connect-Graphimo - Error: $ErrorMessage"
        $Key = [ordered] @{
            'Authorization' = $Null
            'Extended'      = $Null
            'Error'         = $ErrorMessage
            'ExpiresOn'     = $null
            'Splat'         = [ordered] @{
                ApplicationID  = $RestSplat['Body']['client_id']
                ApplicationKey = $RestSplat['Body']['client_secret']
                TenantDomain   = $TenantDomain
                Resource       = $Resource
            }
        }
    }
    $Key
}
