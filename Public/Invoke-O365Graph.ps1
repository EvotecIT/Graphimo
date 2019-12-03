function Invoke-O365Graph {
    [cmdletBinding()]
    param(
        [uri] $PrimaryUri = 'https://graph.microsoft.com/v1.0',
        [uri] $Uri,
        [alias('Authorization')][System.Collections.IDictionary] $Headers,
        [validateset('GET', 'DELETE')][string] $Method = 'GET',
        [string] $ContentType = "application/json",
        [switch] $FullUri
    )

    $RestSplat = @{
        Headers     = $Authorization
        Method      = $Method
        ContentType = $ContentType
    }
    if ($FullUri) {
        $RestSplat.Uri = $Uri
    } else {
        $RestSplat.Uri = -join ($PrimaryUri, $Uri)
    }
    try {
        $OutputQuery = Invoke-RestMethod @RestSplat
        $OutputQuery.value
        if ($OutputQuery.'@odata.nextLink') {
            $RestSplat.Uri = $OutputQuery.'@odata.nextLink'
            $OutputQuery = Invoke-O365Graph @RestSplat -FullUri
            $OutputQuery
        }
    } catch {
        Write-Error $_
        $RestError = $_.ErrorDetails.Message
        if ($RestError) {
            try {

                $ErrorMessage = ConvertFrom-Json -InputObject $RestError
                $ErrorMy = -join ($ErrorMessage.error.code, ' ', $ErrorMessage.error.message)
                Write-Warning $ErrorMy
            } catch {
                Write-Warning $_.Exception.Message
            }
        } else {
            Write-Warning $_.Exception.Message
        }
    }
}