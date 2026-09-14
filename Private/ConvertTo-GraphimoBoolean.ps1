function ConvertTo-GraphimoBoolean {
    [CmdletBinding()]
    param(
        [AllowNull()][object] $Value,
        [bool] $DefaultValue = $false,
        [string] $PropertyName = 'Value'
    )

    if ($null -eq $Value) {
        return $DefaultValue
    }
    if ($Value -is [string]) {
        if ([string]::IsNullOrWhiteSpace($Value)) {
            return $DefaultValue
        }

        $ParsedValue = $false
        if ([bool]::TryParse($Value.Trim(), [ref] $ParsedValue)) {
            return $ParsedValue
        }
        throw [System.ArgumentException]::new("$PropertyName must be True or False.")
    }

    try {
        return [System.Convert]::ToBoolean($Value, [System.Globalization.CultureInfo]::InvariantCulture)
    } catch {
        throw [System.ArgumentException]::new("$PropertyName must be True or False.", $_.Exception)
    }
}
