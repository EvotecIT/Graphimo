﻿function Invoke-Graphimo {
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
        [string] $CountVariable,
        [int] $First,
        [string] $ConsistencyLevel
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
        $WhatIfInformation = "Invoking [$Method] / [ConsistencyLevel: $($ConsistencyLevel)]"
    }
    if ($ConsistencyLevel) {
        $RestSplat.Headers['ConsistencyLevel'] = $ConsistencyLevel
    }
    try {
        if ($Method -eq 'GET') {
            Write-Verbose "Invoke-Graphimo - $($WhatIfInformation)over URI $($RestSplat.Uri)"
            $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
            $Count = 1
            [Array] $FoundUsers = Invoke-InternalGraphimo -OutputQuery $OutputQuery -First $First -CountVariable $CountVariable
            $CurrentCount = $FoundUsers.Count
            if ($First -gt 0 -and $CurrentCount -ge $First) {
                return $FoundUsers
            } else {
                $FoundUsers
            }
            if ($OutputQuery.'@odata.nextLink') {
                Do {
                    $RestSplat.Uri = $OutputQuery.'@odata.nextLink'
                    Write-Verbose "Invoke-Graphimo - $($WhatIfInformation)NextLink (Page $Count/Current Count: $($CurrentCount))) over URI $($RestSplat.Uri)"
                    $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
                    [Array] $FoundUsers = Invoke-InternalGraphimo -OutputQuery $OutputQuery -First $First -CurrentCount $CurrentCount -CountVariable $CountVariable
                    $FoundUsers
                    $Count++
                    $CurrentCount = $CurrentCount + $FoundUsers.Count
                } Until (($First -gt 0 -and $CurrentCount -ge $First) -or $null -eq $OutputQuery.'@odata.nextLink')
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