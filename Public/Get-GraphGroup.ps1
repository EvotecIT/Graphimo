function Get-GraphGroup {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $Id,
        [string[]] $Property,
        [string] $Filter,
        [string] $OrderBy
    )
    if ($ID) {
        # Query a single group
        $RelativeURI = "/groups/$ID"
        $QueryParameter = @{
            '$Select' = $Property -join ','
        }
    } else {
        # Query multiple groups
        $RelativeURI = '/groups'
        $QueryParameter = @{
            '$Select'  = $Property -join ','
            '$filter'  = $Filter
            '$orderby' = $OrderBy
        }
    }
    Remove-EmptyValue -Hashtable $QueryParameter
    $URI = Join-UriQuery -BaseUri 'https://graph.microsoft.com/v1.0' -RelativeOrAbsoluteUri $RelativeURI -QueryParameter $QueryParameter
    Invoke-Graph -Uri $URI -Method GET -Headers $Headers -PrimaryUri $PrimaryUri -FullUri
}