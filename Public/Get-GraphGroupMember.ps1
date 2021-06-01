function Get-GraphGroupMember {
    [cmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [parameter(Mandatory)][string] $Id,
        [string] $Search,
        [string[]] $Property
    )
    if ($ID) {
        # Query a single group
        $RelativeURI = "/groups/$ID/members"
        $QueryParameter = @{
            '$Select' = $Property -join ','
            '$Search' = $Search

        }
        if ($QueryParameter.'$Search') {
            # This is required for search to work
            # https://developer.microsoft.com/en-us/identity/blogs/build-advanced-queries-with-count-filter-search-and-orderby/
            $Headers['ConsistencyLevel'] = 'eventual'
        }
    }
    Remove-EmptyValue -Hashtable $QueryParameter
    Invoke-Graph -Uri $RelativeURI -Method GET -Headers $Headers -QueryParameter $QueryParameter
}