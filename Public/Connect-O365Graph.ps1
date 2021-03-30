function Connect-O365Graph {
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
        [ValidateSet("https://manage.office.com", "https://graph.microsoft.com")] $Resource = "https://manage.office.com"
    )
    # https://dzone.com/articles/getting-access-token-for-microsoft-graph-using-oau-1

    if ($Credential) {
        $Body = @{
            grant_type    = "client_credentials"
            resource      = $Resource
            client_id     = $Credential.UserName
            client_secret = $Credential.GetNetworkCredential().Password
        }
    } else {
        $Body = @{
            grant_type    = "client_credentials"
            resource      = $Resource
            client_id     = $ApplicationID
            client_secret = $ApplicationKey
        }
    }
    try {
        $Authorization = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$($TenantDomain)/oauth2/token" -Body $body -ErrorAction Stop
        @{
            'Authorization' = "$($Authorization.token_type) $($Authorization.access_token)"
        }
    } catch {
        $ErrorMessage = $_.Exception.Message -replace "`n", " " -replace "`r", " "
        Write-Warning -Message "Connect-O365Graph - Error: $ErrorMessage"
        @{
            'Authorization' = ''
            'Error'         = $ErrorMessage
        }
    }
}