BeforeAll {
    . (Join-Path $PSScriptRoot '../Public/Connect-Graphimo.ps1')
    . (Join-Path $PSScriptRoot '../Private/Connect-MsalToken.ps1')

    function Get-MsalToken {
        param($ClientId, $TenantId, $Scopes, $ClientSecret)
    }
}

Describe 'Graphimo authorization cache isolation' {
    BeforeEach {
        $script:AuthorizationCache = @{}
        Mock Invoke-RestMethod {
            [pscustomobject] @{
                token_type   = 'Bearer'
                access_token = "$Uri|$($Body.scope)|$($Body.client_id)|$($Body.client_secret)"
                expires_in   = 3600
            }
        }
        Mock Get-MsalToken {
            [pscustomobject] @{
                AccessToken = "$TenantId|$($Scopes -join ',')|$ClientSecret"
                ExpiresOn   = [datetimeoffset]::UtcNow.AddHours(1)
            }
        }
    }

    It 'reuses direct authorization only for the same tenant client resource and credential' {
        $parameters = @{
            ApplicationID  = 'same-app'
            ApplicationKey = 'synthetic-secret'
            TenantDomain   = 'tenant-a'
        }
        $first = Connect-Graphimo @parameters
        $second = Connect-Graphimo @parameters

        $second.Authorization | Should -Be $first.Authorization
        Should -Invoke Invoke-RestMethod -Times 1 -Exactly
    }

    It 'obtains new direct authorization when <Field> changes' -ForEach @(
        @{ Field = 'TenantDomain'; Value = 'tenant-b' }
        @{ Field = 'Resource'; Value = 'https://manage.office.com' }
        @{ Field = 'ApplicationKey'; Value = 'replacement-synthetic-secret' }
    ) {
        $parameters = @{
            ApplicationID  = 'same-app'
            ApplicationKey = 'synthetic-secret'
            TenantDomain   = 'tenant-a'
        }
        $first = Connect-Graphimo @parameters
        $parameters[$Field] = $Value
        $second = Connect-Graphimo @parameters

        $second.Authorization | Should -Not -Be $first.Authorization
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly
    }

    It 'uses the PSCredential username as the client identity and supports forced refresh' {
        $secret = ConvertTo-SecureString 'synthetic-secret' -AsPlainText -Force
        $credential = [pscredential]::new('credential-app', $secret)
        $first = Connect-Graphimo -Credential $credential -TenantDomain 'tenant-a'
        $second = Connect-Graphimo -Credential $credential -TenantDomain 'tenant-a'
        $third = Connect-Graphimo -Credential $credential -TenantDomain 'tenant-a' -ForceRefesh

        $second.Authorization | Should -Be $first.Authorization
        $third.Splat.ApplicationID | Should -Be 'credential-app'
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly
    }

    It 'does not reuse the old token when a returned reconnect envelope is updated with a replacement secret' {
        $first = Connect-Graphimo -ApplicationID 'same-app' -ApplicationKey 'synthetic-secret' -TenantDomain 'tenant-a'
        $first.Splat.ApplicationKey = 'replacement-synthetic-secret'
        $reconnect = $first.Splat
        $second = Connect-Graphimo @reconnect

        $second.Authorization | Should -Not -Be $first.Authorization
        Should -Invoke Invoke-RestMethod -Times 2 -Exactly
    }

    It 'delegates MSAL caching and expiry to the provider across tenant scope and credential changes' {
        $parameters = @{ ClientId = 'same-app'; TenantId = 'tenant-a'; Scopes = @('User.Read'); ClientSecret = 'first' }
        $first = Connect-Graphimo -MsalToken $parameters
        $parameters = @{ ClientId = 'same-app'; TenantId = 'tenant-b'; Scopes = @('Group.Read.All'); ClientSecret = 'second' }
        $second = Connect-Graphimo -MsalToken $parameters

        $second.MsalToken.AccessToken | Should -Not -Be $first.MsalToken.AccessToken
        $second.Splat.TenantId | Should -Be 'tenant-b'
        Should -Invoke Get-MsalToken -Times 2 -Exactly
    }

    It 'does not mix the direct authorization envelope with an MSAL token for the same client' {
        $null = Connect-Graphimo -ApplicationID 'same-app' -ApplicationKey 'synthetic-secret' -TenantDomain 'tenant-a'
        $authorization = Connect-Graphimo -MsalToken @{ ClientId = 'same-app'; TenantId = 'tenant-a'; Scopes = @('User.Read') }

        $authorization.MsalToken.AccessToken | Should -Not -BeNullOrEmpty
        Should -Invoke Get-MsalToken -Times 1 -Exactly
    }
}
