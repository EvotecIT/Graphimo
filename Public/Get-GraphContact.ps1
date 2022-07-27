function Get-GraphContact {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $Id,
        [string[]] $Property,
        [string] $Filter,
        [string] $OrderBy
    )
    if ($ID) {
        # Query a single group
        $RelativeURI = "/contacts/$ID"
        $QueryParameter = @{
            '$Select' = $Property -join ','
        }
    } else {
        # Query multiple groups
        $RelativeURI = '/contacts'
        $QueryParameter = @{
            '$Select'  = $Property -join ','
            '$filter'  = $Filter
            '$orderby' = $OrderBy
        }
    }
    Remove-EmptyValue -Hashtable $QueryParameter
    Invoke-Graphimo -Uri $RelativeURI -Method GET -Headers $Headers -QueryParameter $QueryParameter
}