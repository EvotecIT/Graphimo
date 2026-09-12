function Get-GraphimoRetryAfterSeconds {
    [CmdletBinding()]
    param(
        $Headers
    )

    $RetryAfterValue = $null
    if ($Headers -is [System.Collections.IDictionary]) {
        foreach ($Key in $Headers.Keys) {
            if ([string] $Key -ieq 'retry-after') {
                $RetryAfterValue = $Headers[$Key]
                break
            }
        }
    } elseif ($null -ne $Headers) {
        foreach ($Property in $Headers.PSObject.Properties) {
            if ($Property.Name -ieq 'retry-after') {
                $RetryAfterValue = $Property.Value
                break
            }
        }
    }

    if ($RetryAfterValue -is [System.Array]) {
        $RetryAfterValue = $RetryAfterValue[0]
    }
    if ($null -eq $RetryAfterValue) {
        return
    }

    $Seconds = 0
    if ([int]::TryParse([string] $RetryAfterValue, [ref] $Seconds)) {
        [math]::Max(0, $Seconds)
        return
    }

    $RetryAt = [datetimeoffset]::MinValue
    if ([datetimeoffset]::TryParse([string] $RetryAfterValue, [ref] $RetryAt)) {
        [math]::Max(0, [math]::Ceiling(($RetryAt - [datetimeoffset]::UtcNow).TotalSeconds))
    }
}
