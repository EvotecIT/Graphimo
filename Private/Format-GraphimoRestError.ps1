function Format-GraphimoRestError {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][System.Management.Automation.ErrorRecord] $ErrorRecord,
        [parameter(Mandatory)][System.Collections.IDictionary] $RestSplat
    )

    $ExceptionMessage = $ErrorRecord.Exception.Message -replace "`r", ' ' -replace "`n", ' '
    $RestError = $ErrorRecord.ErrorDetails.Message
    $RequestSummary = "[$($RestSplat.Method)] $($RestSplat.Uri)"
    $StatusSummary = $null

    $Response = $ErrorRecord.Exception.Response
    if ($Response) {
        $StatusCode = $Response.StatusCode
        $ReasonPhrase = $Response.ReasonPhrase
        if (-not $ReasonPhrase) {
            $ReasonPhrase = $Response.StatusDescription
        }
        if ($StatusCode) {
            $StatusSummary = " Status: $([int] $StatusCode) $ReasonPhrase."
        }
    }

    if (-not $RestError) {
        return "Invoke-Graphimo - Error: $ExceptionMessage Request: $RequestSummary.$StatusSummary"
    }

    try {
        $ParsedError = ConvertFrom-Json -InputObject $RestError -ErrorAction Stop
        $GraphMessage = $ParsedError.error.message
        if (-not $GraphMessage) {
            $GraphMessage = $ParsedError.error_description
        }
        if (-not $GraphMessage) {
            $GraphMessage = $ParsedError.message
        }
        if ($GraphMessage) {
            $GraphMessage = $GraphMessage -replace "`r", ' ' -replace "`n", ' '
            return "Invoke-Graphimo - Error: $ExceptionMessage Request: $RequestSummary.$StatusSummary Graph error: $GraphMessage"
        }
    } catch {
        $ResponsePreview = $RestError -replace "`r", ' ' -replace "`n", ' '
        if ($ResponsePreview.Length -gt 500) {
            $ResponsePreview = $ResponsePreview.Substring(0, 500) + '...'
        }
        return "Invoke-Graphimo - Error: $ExceptionMessage Request: $RequestSummary.$StatusSummary Non-JSON response preview: $ResponsePreview"
    }

    $ResponsePreview = $RestError -replace "`r", ' ' -replace "`n", ' '
    if ($ResponsePreview.Length -gt 500) {
        $ResponsePreview = $ResponsePreview.Substring(0, 500) + '...'
    }
    "Invoke-Graphimo - Error: $ExceptionMessage Request: $RequestSummary.$StatusSummary Response preview: $ResponsePreview"
}
