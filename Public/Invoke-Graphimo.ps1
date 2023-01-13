function Invoke-Graphimo {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [alias('PrimaryUri')][uri] $BaseUri = 'https://graph.microsoft.com/v1.0',
        [uri] $Uri,
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [validateset('GET', 'DELETE', 'POST', 'PATCH', 'PUT')][string] $Method = 'GET',
        [string] $ContentType = "application/json; charset=UTF-8",
        [System.Collections.IDictionary] $Body,
        [System.Collections.IDictionary] $QueryParameter,
        [switch] $FullUri,
        [int] $First
    )
    if ($Headers.MsalToken) {
        if ($Headers.Splat) {
            $Splat = $Headers.Splat
            $Headers = Connect-MsalToken -Authorization $Headers
        }
    } else {
        # This forces a reconnect of session in case it's about to time out. If it's not timeouting a cache value is used
        if ($Headers.Splat) {
            $Splat = $Headers.Splat
            $Headers = Connect-Graphimo @Splat
        }
    }

    if ($Headers.Error) {
        Write-Warning "Invoke-Graphimo - Authorization error. Skipping."
        return
    }
    if ($Headers.MsalToken) {
        $RestSplat = @{
            Headers     = @{
                Authorization = $Headers.MsalToken.TokenType + ' ' + $Headers.MsalToken.AccessToken
            }
            Method      = $Method
            ContentType = $ContentType
        }
    } else {
        $RestSplat = @{
            Headers     = $Headers
            Method      = $Method
            ContentType = $ContentType
        }
    }
    if ($Body) {
        $RestSplat['Body'] = $Body | ConvertTo-Json -Depth 5
    }
    if ($FullUri) {
        $RestSplat.Uri = $Uri
    } else {
        $RestSplat.Uri = Join-UriQuery -BaseUri $BaseUri -RelativeOrAbsoluteUri $Uri -QueryParameter $QueryParameter
    }
    if ($RestSplat['Body']) {
        $WhatIfInformation = "Invoking [$Method] " + [System.Environment]::NewLine + $RestSplat['Body'] + [System.Environment]::NewLine
    } else {
        $WhatIfInformation = "Invoking [$Method] "
    }
    try {
        if ($Method -eq 'GET') {
            Write-Verbose "Invoke-Graphimo - $($WhatIfInformation)over URI $($RestSplat.Uri)"
            $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
            if ($OutputQuery.value) {
                $FoundUsers = $OutputQuery.value
            }
            if ($First) {
                if ($FoundUsers.Count -eq $First) {
                    return $FoundUsers
                } elseif ($FoundUsers.Count -gt $First) {
                    $FoundUsers = $FoundUsers | Select-Object -First $First
                    return $FoundUsers
                } else {
                    $First = $First - $FoundUsers.Count
                    $FoundUsers
                }
            } else {
                $FoundUsers
            }
            if ($OutputQuery.'@odata.nextLink') {
                $RestSplat.Uri = $OutputQuery.'@odata.nextLink'
                $MoreData = Invoke-Graphimo @RestSplat -FullUri -First $First
                if ($MoreData) {
                    $MoreData
                }
            }
        } else {
            Write-Verbose "Invoke-Graphimo - $($WhatIfInformation)over URI $($RestSplat.Uri)"
            if ($PSCmdlet.ShouldProcess($($RestSplat.Uri), $WhatIfInformation)) {
                $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
                if ($Method -in 'POST') {
                    $OutputQuery
                } else {
                    return $true
                }
            }
        }
    } catch {
        $RestError = $_.ErrorDetails.Message
        if ($RestError) {
            try {
                $ErrorMessage = ConvertFrom-Json -InputObject $RestError
                # Write-Warning -Message "Invoke-Graphimo - [$($ErrorMessage.error.code)] $($ErrorMessage.error.message), exception: $($_.Exception.Message)"
                Write-Warning -Message "Invoke-Graphimo - Error: $($_.Exception.Message) $($ErrorMessage.error.message)"
            } catch {
                Write-Warning -Message "Invoke-Graphimo - Error: $($_.Exception.Message)"
            }
        } else {
            Write-Warning -Message "Invoke-Graphimo - Error: $($_.Exception.Message)"
        }
        if ($Method -notin 'GET', 'POST') {
            return $false
        }
    }
}