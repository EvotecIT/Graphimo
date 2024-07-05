function Get-GraphGroupMember {
    [cmdletBinding()]
    param(
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [parameter(Mandatory)][string] $Id,
        [string] $Search,
        [string[]] $Property,
        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

    if ($ID) {
        # Query a single group
        $RelativeURI = "/groups/$ID/members"
        $QueryParameter = @{
            '$Select' = $Property -join ','
            '$Search' = $Search
        }
    }
    Remove-EmptyValue -Hashtable $QueryParameter
    $invokeGraphimoSplat = @{
        Uri            = $RelativeURI
        Method         = 'GET'
        Headers        = $Headers
        QueryParameter = $QueryParameter
        MgGraph        = $MgGraph.IsPresent
    }
    if ($QueryParameter.'$Search') {
        # This is required for search to work
        # https://developer.microsoft.com/en-us/identity/blogs/build-advanced-queries-with-count-filter-search-and-orderby/
        $invokeGraphimoSplat['ConsistencyLevel'] = 'eventual'
    }

    Invoke-Graphimo @invokeGraphimoSplat
}