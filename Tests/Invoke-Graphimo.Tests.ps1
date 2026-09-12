BeforeAll {
    function Join-UriQuery {
        param($BaseUri, $RelativeOrAbsoluteUri, $QueryParameter)
        [uri] 'https://graph.microsoft.com/v1.0/invitations'
    }
    function Remove-EmptyValue {
        param([hashtable] $Hashtable)
    }
    function Format-GraphimoRestError {
        param($ErrorRecord, $RestSplat)
        'formatted Graph error'
    }

    . (Join-Path $PSScriptRoot '..\Public\Invoke-Graphimo.ps1')
}

Describe 'Invoke-Graphimo error compatibility' {
    BeforeEach {
        Mock Invoke-RestMethod { throw 'transport failed after send' }
    }

    It 'preserves the default warning-and-return behavior' {
        $output = @(Invoke-Graphimo -Uri '/invitations' -Method POST -Headers @{ Authorization = 'Bearer test' } -Confirm:$false 3>&1)

        @($output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }).Message | Should -Contain 'formatted Graph error'
    }

    It 'rethrows transport failures when explicitly requested' {
        { Invoke-Graphimo -Uri '/invitations' -Method POST -Headers @{ Authorization = 'Bearer test' } -Confirm:$false -ThrowOnError } | Should -Throw '*transport failed after send*'
    }
}
