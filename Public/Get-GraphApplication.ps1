function Get-GraphApplication {
    [cmdletBinding()]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $ID,
        [string] $DisplayName,
        [string[]] $Property,
        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    if ($ID) {
        # Query a single group
        $RelativeURI = "/applications/$ID"
        $QueryParameter = @{
            '$Select' = $Property -join ','
        }
    } elseif ($DisplayName) {
        $RelativeURI = '/applications'
        $QueryParameter = @{
            '$Select'  = $Property -join ','
            '$filter' = "displayName eq '$DisplayName'"
            '$orderby' = $OrderBy
        }
    } else {
        # Query multiple groups
        $RelativeURI = '/applications'
        $QueryParameter = @{
            '$Select'  = $Property -join ','
            '$filter'  = $Filter
            '$orderby' = $OrderBy
        }
    }
    Remove-EmptyValue -Hashtable $QueryParameter
    Invoke-Graphimo -Uri $RelativeURI -Method GET -Headers $Headers -QueryParameter $QueryParameter -MgGraph:$MgGraph.IsPresent
}