function Connect-Graph {
    [cmdletBinding(DefaultParameterSetName = 'ClearText')]
    param(
        [parameter(Mandatory, ParameterSetName = 'ClearText')][string][alias('ClientID')] $ApplicationID,
        [parameter(Mandatory, ParameterSetName = 'ClearText')][string][alias('ClientSecret')] $ApplicationKey,
        [parameter(Mandatory, ParameterSetName = 'Credential')][PSCredential] $Credential,

        [parameter(Mandatory, ParameterSetName = 'ClearText')]
        [parameter(Mandatory, ParameterSetName = 'Credential')]
        [string] $TenantDomain,

        [parameter(ParameterSetName = 'ClearText')]
        [parameter(ParameterSetName = 'Credential')]
        [ValidateSet("https://manage.office.com", "https://graph.microsoft.com", "https://graph.microsoft.com/beta", 'https://graph.microsoft.com/.default')] $Resource = 'https://graph.microsoft.com/.default',
        [int] $ExpiresTimeout = 30,
        [switch] $ForceRefesh
    )
    # Comparison V1/V2 https://nicolgit.github.io/AzureAD-Endopoint-V1-vs-V2-comparison/

    if (-not $Script:AuthorizationCache) {
        $Script:AuthorizationCache = [ordered] @{}
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
    } else {
        $RestSplat = @{
            ErrorAction = 'Stop'
            Method      = 'POST'
            Body        = @{
                grant_type    = "client_credentials"
                client_id     = $ApplicationID
                client_secret = $ApplicationKey
            }
        }
    }

    if ($Script:AuthorizationCache[$ApplicationID] -and -not $ForceRefesh) {
        if ($Script:AuthorizationCache[$ApplicationID].ExpiresOn -gt [datetime]::UtcNow) {
            Write-Verbose "Connect-O365Graph - Using cache for $ApplicationID"
            return $Script:AuthorizationCache[$ApplicationID]
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
    Write-Verbose "Connect-Graph - EndPoint $($RestSplat['Uri'])"
    try {
        $Authorization = Invoke-RestMethod @RestSplat
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
        $Script:AuthorizationCache[$ApplicationID] = $Key
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning -Message "Connect-Graph - Error: $ErrorMessage"
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