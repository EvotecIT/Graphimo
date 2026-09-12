function Invoke-Graphimo {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [alias('PrimaryUri')][uri] $BaseUri = 'https://graph.microsoft.com/v1.0',
        [uri] $Uri,
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [validateset('GET', 'DELETE', 'POST', 'PATCH', 'PUT')][string] $Method = 'GET',
        [string] $ContentType = "application/json; charset=UTF-8",
        [System.Collections.IDictionary] $Body,
        [System.Collections.IDictionary] $QueryParameter,
        [switch] $FullUri,
        [string] $CountVariable,
        [int] $First,
        [string] $ConsistencyLevel,
        [switch] $MgGraph,
        [switch] $ThrowOnError
    )
    if ($MgGraph -or $Script:MgGraphAuthenticated -eq $true) {
        # we use the Microsoft.Graph module instead of Invoke-RestMethod
    } elseif ($Headers.MsalToken) {
        if ($Headers.Splat) {
            $Splat = $Headers.Splat
            try {
                $Headers = Connect-MsalToken -Authorization $Headers
            } catch {
                if ($ThrowOnError) {
                    $Exception = [System.UnauthorizedAccessException]::new('Invoke-Graphimo - Authorization refresh failed before dispatch.', $_.Exception)
                    $Exception.Data['GraphimoFailurePhase'] = 'AuthorizationPreDispatch'
                    throw $Exception
                }
                throw
            }
        }
    } else {
        if (-not $Headers) {
            $Message = 'No headers provided. Skipping.'
            if ($ThrowOnError) {
                $Exception = [System.UnauthorizedAccessException]::new($Message)
                $Exception.Data['GraphimoFailurePhase'] = 'AuthorizationPreDispatch'
                throw $Exception
            }
            Write-Warning $Message
            return
        }
        # This forces a reconnect of session in case it's about to time out. If it's not timeouting a cache value is used
        if ($Headers.Splat) {
            $Splat = $Headers.Splat
            try {
                $Headers = Connect-Graphimo @Splat
            } catch {
                if ($ThrowOnError) {
                    $Exception = [System.UnauthorizedAccessException]::new('Invoke-Graphimo - Authorization refresh failed before dispatch.', $_.Exception)
                    $Exception.Data['GraphimoFailurePhase'] = 'AuthorizationPreDispatch'
                    throw $Exception
                }
                throw
            }
        }
    }

    $UsesMgGraph = $MgGraph -or $Script:MgGraphAuthenticated -eq $true
    if (-not $UsesMgGraph -and (-not $Headers -or $Headers.Error)) {
        $Message = 'Invoke-Graphimo - Authorization error. Skipping.'
        if ($ThrowOnError) {
            $Exception = [System.UnauthorizedAccessException]::new($Message)
            $Exception.Data['GraphimoFailurePhase'] = 'AuthorizationPreDispatch'
            throw $Exception
        }
        Write-Warning $Message
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
        $WhatIfInformation = "Invoking [$Method] / [ConsistencyLevel: $($ConsistencyLevel)] "
    }
    if ($ConsistencyLevel) {
        if (-not $RestSplat.Headers) {
            $RestSplat.Headers = [ordered]@{}
        }
        $RestSplat.Headers['ConsistencyLevel'] = $ConsistencyLevel
    }
    Remove-EmptyValue -Hashtable $RestSplat
    try {
        if ($Method -eq 'GET') {
            Write-Verbose "Invoke-Graphimo - $($WhatIfInformation)over URI $($RestSplat.Uri)"
            if ($MgGraph -or $Script:MgGraphAuthenticated -eq $true) {
                $OutputQuery = Invoke-MgGraphRequest @RestSplat -Verbose:$false
            } else {
                $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
            }
            $Count = 1
            [Array] $FoundUsers = Invoke-InternalGraphimo -OutputQuery $OutputQuery -First $First -CountVariable $CountVariable -MgGraph:$MgGraph.IsPresent
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
                    if ($MgGraph -or $Script:MgGraphAuthenticated -eq $true) {
                        $OutputQuery = Invoke-MgGraphRequest @RestSplat -Verbose:$false
                    } else {
                        $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
                    }
                    [Array] $FoundUsers = Invoke-InternalGraphimo -OutputQuery $OutputQuery -First $First -CurrentCount $CurrentCount -CountVariable $CountVariable -MgGraph:$MgGraph.IsPresent
                    $FoundUsers
                    $Count++
                    $CurrentCount = $CurrentCount + $FoundUsers.Count
                } Until (($First -gt 0 -and $CurrentCount -ge $First) -or $null -eq $OutputQuery.'@odata.nextLink')
            }
        } else {
            Write-Verbose "Invoke-Graphimo - $($WhatIfInformation)over URI $($RestSplat.Uri)"
            if ($PSCmdlet.ShouldProcess($($RestSplat.Uri), $WhatIfInformation)) {
                if ($MgGraph -or $Script:MgGraphAuthenticated -eq $true) {
                    $OutputQuery = Invoke-MgGraphRequest @RestSplat -Verbose:$false
                } else {
                    $OutputQuery = Invoke-RestMethod @RestSplat -Verbose:$false
                }
                if ($Method -in 'POST') {
                    $OutputQuery
                } else {
                    return $true
                }
            }
        }
    } catch {
        if ($ThrowOnError) {
            throw
        }
        Write-Warning -Message (Format-GraphimoRestError -ErrorRecord $_ -RestSplat $RestSplat)
        if ($Method -notin 'GET', 'POST') {
            return $false
        }
    }
}
