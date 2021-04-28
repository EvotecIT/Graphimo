function Invoke-O365Graph {
    [cmdletBinding()]
    param(
        [uri] $PrimaryUri = 'https://graph.microsoft.com/v1.0',
        [uri] $Uri,
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [validateset('GET', 'DELETE', 'POST', 'PATCH')][string] $Method = 'GET',
        [string] $ContentType = "application/json; charset=UTF-8",
        [System.Collections.IDictionary] $Body,
        [switch] $FullUri
    )

    # This forces a reconnect of session in case it's about to time out. If it's not timeouting a cache value is used
    if ($Headers.Splat) {
        $Splat = $Headers.Splat
        $Headers = Connect-O365Graph @Splat
    }

    if ($Authorization.Error) {
        Write-Warning "Invoke-O365Graph - Authorization error. Skipping."
        return
    }
    $RestSplat = @{
        Headers     = $Headers
        Method      = $Method
        ContentType = $ContentType
        #Body        = $Body | ConvertTo-Json -Depth 5
    }
    if ($Body) {
        $RestSplat['Body'] = $Body | ConvertTo-Json -Depth 5
    }
    if ($FullUri) {
        $RestSplat.Uri = $Uri
    } else {
        $RestSplat.Uri = -join ($PrimaryUri, $Uri)
    }
    try {
        Write-Verbose "Invoke-O365Graph - Querying $($RestSplat.Uri)"
        $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
        if ($Method -in 'GET') {
            if ($OutputQuery.value) {
                $OutputQuery.value
            }
            if ($OutputQuery.'@odata.nextLink') {
                $RestSplat.Uri = $OutputQuery.'@odata.nextLink'
                $MoreData = Invoke-O365Graph @RestSplat -FullUri
                if ($MoreData) {
                    $MoreData
                }
            }
        } elseif ($Method -in 'POST') {
            $OutputQuery
        } else {
            return $true
        }
    } catch {
        $RestError = $_.ErrorDetails.Message
        if ($RestError) {
            try {
                $ErrorMessage = ConvertFrom-Json -InputObject $RestError
                $ErrorMy = -join ('JSON Error:' , $ErrorMessage.error.code, ' ', $ErrorMessage.error.message, ' Additional Error: ', $_.Exception.Message)
                Write-Warning $ErrorMy
            } catch {
                Write-Warning $_.Exception.Message
            }
        } else {
            Write-Warning $_.Exception.Message
        }
        if ($Method -notin 'GET', 'POST') {
            return $false
        }
    }
}