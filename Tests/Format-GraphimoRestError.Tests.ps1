BeforeAll {
    . "$PSScriptRoot\..\Private\Format-GraphimoRestError.ps1"

    function New-GraphimoTestErrorRecord {
        param(
            [Parameter(Mandatory)][string] $ExceptionMessage,
            [Parameter()][AllowEmptyString()][string] $ResponseBody
        )

        $Exception = [System.InvalidOperationException]::new($ExceptionMessage)
        $Record = [System.Management.Automation.ErrorRecord]::new(
            $Exception,
            'GraphRequestFailed',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        if ($PSBoundParameters.ContainsKey('ResponseBody')) {
            $Record.ErrorDetails = [System.Management.Automation.ErrorDetails]::new($ResponseBody)
        }
        $Record
    }

    $Script:Request = @{
        Method = 'POST'
        Uri    = 'https://graph.microsoft.com/v1.0/invitations'
    }
}

Describe 'Format-GraphimoRestError' {
    It 'preserves a Microsoft Graph JSON error message and request context' {
        $Body = '{"error":{"code":"Request_BadRequest","message":"Your organization does not allow collaboration with the domain of the user."}}'
        $ErrorRecord = New-GraphimoTestErrorRecord -ExceptionMessage 'Graph request failed' -ResponseBody $Body

        $Result = Format-GraphimoRestError -ErrorRecord $ErrorRecord -RestSplat $Script:Request

        $Result | Should -Match 'Request: \[POST\] https://graph\.microsoft\.com/v1\.0/invitations\.'
        $Result | Should -BeLike '*Graph error: Your organization does not allow collaboration with the domain of the user.*'
    }

    It 'reports a plain-text response without replacing it with a JSON parser failure' {
        $ErrorRecord = New-GraphimoTestErrorRecord -ExceptionMessage 'Graph request failed' -ResponseBody 'Policy blocked this external domain.'

        $Result = Format-GraphimoRestError -ErrorRecord $ErrorRecord -RestSplat $Script:Request

        $Result | Should -BeLike '*Non-JSON response preview: Policy blocked this external domain.*'
        $Result | Should -Not -BeLike '*Conversion from JSON failed*'
    }

    It 'reports malformed JSON as a bounded non-JSON response preview' {
        $Body = '{"error":' + ('x' * 600)
        $ErrorRecord = New-GraphimoTestErrorRecord -ExceptionMessage 'Graph request failed' -ResponseBody $Body

        $Result = Format-GraphimoRestError -ErrorRecord $ErrorRecord -RestSplat $Script:Request

        $Result | Should -BeLike '*Non-JSON response preview: {"error":*'
        $Result.Length | Should -BeLessThan 700
    }

    It 'falls back to the original exception when the response body is absent' {
        $ErrorRecord = New-GraphimoTestErrorRecord -ExceptionMessage 'The Graph request failed before a response was returned.'

        $Result = Format-GraphimoRestError -ErrorRecord $ErrorRecord -RestSplat $Script:Request

        $Result | Should -BeLike '*The Graph request failed before a response was returned.*'
    }
}
