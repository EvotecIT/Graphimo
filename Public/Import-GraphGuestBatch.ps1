function Import-GraphGuestBatch {
    <#
    .SYNOPSIS
    Invites Microsoft Entra guests through bounded Microsoft Graph JSON batches.

    .DESCRIPTION
    Sends up to 20 invitation requests per Graph JSON batch, inspects every subresponse, and retries
    transient failures using Retry-After or bounded exponential backoff. One result is emitted for
    every input invitation so callers can checkpoint progress and resume safely.

    .PARAMETER Invitation
    Invitation records. Each record must provide EmailAddress and can provide DisplayName, Context,
    SendInvitationMessage, InviteRedirectUrl, UserType, ResetRedemption, and InvitedUserID.

    .PARAMETER BatchSize
    Number of requests in each Graph JSON batch. Microsoft Graph permits at most 20.

    .PARAMETER MaxRetries
    Maximum transient retries after the initial request.

    .PARAMETER ResultBatchAction
    Optional callback invoked with the final ordered results for one Graph batch before those results
    are emitted. Durable consumers can checkpoint the whole batch with one disk flush.

    .PARAMETER PendingBatchAction
    Optional callback invoked with the exact Graph batch immediately before its first dispatch.
    Durable consumers can persist intent without marking later, undispatched batches uncertain.

    .EXAMPLE
    Import-GraphGuestBatch -Invitation $invitations -MgGraph -BatchSize 20 -MaxRetries 5
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [parameter()][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]] $Invitation,
        [bool] $SendInvitationMessage = $false,
        [string] $InviteRedirectUrl = 'https://portal.office.com',
        [ValidateSet('Member', 'Guest')][string] $UserType,
        [ValidateRange(1, 20)][int] $BatchSize = 20,
        [ValidateRange(0, 20)][int] $MaxRetries = 5,
        [ValidateRange(1, 300)][int] $InitialRetryDelaySeconds = 1,
        [ValidateRange(1, 900)][int] $MaxRetryDelaySeconds = 60,
        [scriptblock] $PendingBatchAction,
        [scriptblock] $ResultBatchAction,
        [switch] $MgGraph
    )

    $CallingCmdlet = $PSCmdlet
    for ($Offset = 0; $Offset -lt $Invitation.Count; $Offset += $BatchSize) {
        $BatchResults = @(& {
        $LastIndex = [math]::Min($Offset + $BatchSize - 1, $Invitation.Count - 1)
        $Pending = [System.Collections.Generic.List[object]]::new()

        for ($Index = $Offset; $Index -le $LastIndex; $Index++) {
            $Item = $Invitation[$Index]
            $EmailAddress = [string] $Item.EmailAddress
            if ([string]::IsNullOrWhiteSpace($EmailAddress)) {
                [pscustomobject] @{
                    InputIndex        = $Index
                    Context           = $Item.Context
                    EmailAddress      = $EmailAddress
                    Status            = 'Failed'
                    Success           = $false
                    StatusCode        = 0
                    AttemptCount      = 0
                    RetryCount        = 0
                    RetryDelaySeconds = 0
                    ThrottleDelaySeconds = 0
                    BatchRetryDelaySeconds = 0
                    BatchThrottleDelaySeconds = 0
                    OperationType     = [string] $Item.OperationType
                    InvitedUser       = $null
                    ErrorCode         = 'InvalidInvitation'
                    ErrorMessage      = 'EmailAddress is required.'
                }
                continue
            }

            try {
                $ItemSendInvitationMessage = ConvertTo-GraphimoBoolean -Value $Item.SendInvitationMessage -DefaultValue $SendInvitationMessage -PropertyName 'SendInvitationMessage'
                $ItemResetRedemption = ConvertTo-GraphimoBoolean -Value $Item.ResetRedemption -PropertyName 'ResetRedemption'
            } catch {
                [pscustomobject] @{
                    InputIndex        = $Index
                    Context           = $Item.Context
                    EmailAddress      = $EmailAddress
                    Status            = 'Failed'
                    Success           = $false
                    StatusCode        = 0
                    AttemptCount      = 0
                    RetryCount        = 0
                    RetryDelaySeconds = 0
                    ThrottleDelaySeconds = 0
                    BatchRetryDelaySeconds = 0
                    BatchThrottleDelaySeconds = 0
                    OperationType     = [string] $Item.OperationType
                    InvitedUser       = $null
                    ErrorCode         = 'InvalidInvitation'
                    ErrorMessage      = $_.Exception.Message
                }
                continue
            }
            $ItemInviteRedirectUrl = if ([string]::IsNullOrWhiteSpace([string] $Item.InviteRedirectUrl)) {
                $InviteRedirectUrl
            } else {
                [string] $Item.InviteRedirectUrl
            }
            $ItemUserType = if ([string]::IsNullOrWhiteSpace([string] $Item.UserType)) {
                $UserType
            } else {
                [string] $Item.UserType
            }
            $Body = New-GraphGuestInvitationBody -Name ([string] $Item.DisplayName) -EmailAddress $EmailAddress -SendInvitationMessage $ItemSendInvitationMessage -InviteRedirectUrl $ItemInviteRedirectUrl -ResetRedemption $ItemResetRedemption -InvitedUserID ([string] $Item.InvitedUserID) -UserType $ItemUserType
            $Pending.Add([pscustomobject] @{
                    InputIndex        = $Index
                    Context           = $Item.Context
                    EmailAddress      = $EmailAddress
                    OperationType     = [string] $Item.OperationType
                    Body              = $Body
                    AttemptCount      = 0
                    RetryDelaySeconds = 0
                    ThrottleDelaySeconds = 0
                    BatchRetryDelaySeconds = 0
                    BatchThrottleDelaySeconds = 0
                    NextRetryIsThrottle = $false
                    NextRetryDelaySeconds = 0
                })
        }

        if ($Pending.Count -eq 0) {
            return
        }
        if (-not $CallingCmdlet.ShouldProcess("$($Pending.Count) guest invitation(s)", 'Submit Microsoft Graph invitation batch')) {
            foreach ($State in $Pending) {
                [pscustomobject] @{
                    InputIndex        = $State.InputIndex
                    Context           = $State.Context
                    EmailAddress      = $State.EmailAddress
                    Status            = 'WhatIf'
                    Success           = $false
                    StatusCode        = 0
                    AttemptCount      = 0
                    RetryCount        = 0
                    RetryDelaySeconds = 0
                    ThrottleDelaySeconds = 0
                    BatchRetryDelaySeconds = 0
                    BatchThrottleDelaySeconds = 0
                    OperationType     = $State.OperationType
                    InvitedUser       = $null
                    ErrorCode         = $null
                    ErrorMessage      = $null
                }
            }
            return
        }

        if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
            Write-Warning -Message 'No headers or MgGraph switch provided. Skipping.'
            foreach ($State in $Pending) {
                [pscustomobject] @{
                    InputIndex        = $State.InputIndex
                    Context           = $State.Context
                    EmailAddress      = $State.EmailAddress
                    Status            = 'Failed'
                    Success           = $false
                    StatusCode        = 0
                    AttemptCount      = 0
                    RetryCount        = 0
                    RetryDelaySeconds = 0
                    ThrottleDelaySeconds = 0
                    BatchRetryDelaySeconds = 0
                    BatchThrottleDelaySeconds = 0
                    OperationType     = $State.OperationType
                    InvitedUser       = $null
                    ErrorCode         = 'AuthorizationFailed'
                    ErrorMessage      = 'No headers or MgGraph authentication context was provided.'
                }
            }
            return
        }

        if ($PendingBatchAction) {
            $null = & $PendingBatchAction ([object[]] @($Pending | Sort-Object InputIndex))
        }

        while ($Pending.Count -gt 0) {
            $Requests = [System.Collections.Generic.List[object]]::new()
            $StateByRequestId = [ordered] @{}
            foreach ($State in $Pending) {
                $State.AttemptCount++
                $RequestId = "$($State.InputIndex)-$($State.AttemptCount)"
                $StateByRequestId[$RequestId] = $State
                $Requests.Add([pscustomobject] @{
                        id      = $RequestId
                        method  = 'POST'
                        url     = '/invitations'
                        headers = @{
                            'Content-Type' = 'application/json'
                        }
                        body    = $State.Body
                    })
            }

            try {
                $BatchResponse = Invoke-Graphimo -Uri '/$batch' -Method POST -Headers $Headers -Body ([ordered] @{ requests = $Requests.ToArray() }) -MgGraph:$MgGraph.IsPresent -WhatIf:$false -Confirm:$false -ThrowOnError -ErrorAction Stop
            } catch {
                $IsPreDispatchAuthorizationFailure = $_.Exception.Data['GraphimoFailurePhase'] -eq 'AuthorizationPreDispatch'
                foreach ($State in $Pending) {
                    $CompletedAttemptCount = if ($IsPreDispatchAuthorizationFailure) {
                        [math]::Max(0, $State.AttemptCount - 1)
                    } else {
                        $State.AttemptCount
                    }
                    [pscustomobject] @{
                        InputIndex        = $State.InputIndex
                        Context           = $State.Context
                        EmailAddress      = $State.EmailAddress
                        Status            = if ($IsPreDispatchAuthorizationFailure) { 'Failed' } else { 'Uncertain' }
                        Success           = $false
                        StatusCode        = 0
                        AttemptCount      = $CompletedAttemptCount
                        RetryCount        = [math]::Max(0, $CompletedAttemptCount - 1)
                        RetryDelaySeconds = $State.RetryDelaySeconds
                        ThrottleDelaySeconds = $State.ThrottleDelaySeconds
                        BatchRetryDelaySeconds = $State.BatchRetryDelaySeconds
                        BatchThrottleDelaySeconds = $State.BatchThrottleDelaySeconds
                        OperationType     = $State.OperationType
                        InvitedUser       = $null
                        ErrorCode         = if ($IsPreDispatchAuthorizationFailure) { 'AuthorizationFailed' } else { 'BatchTransportUncertain' }
                        ErrorMessage      = if ($IsPreDispatchAuthorizationFailure) {
                            $_.Exception.Message
                        } else {
                            "Microsoft Graph invitation batch did not return a usable response. The invitation outcome is uncertain and must be reconciled before retrying. $($_.Exception.Message)"
                        }
                    }
                }
                break
            }
            $ResponseByRequestId = [ordered] @{}
            foreach ($Response in @($BatchResponse.responses)) {
                $ResponseByRequestId[[string] $Response.id] = $Response
            }

            $Retry = [System.Collections.Generic.List[object]]::new()
            $RetryDelay = 0
            foreach ($RequestId in $StateByRequestId.Keys) {
                $State = $StateByRequestId[$RequestId]
                $Response = $ResponseByRequestId[$RequestId]
                $StatusCode = 0
                $HasUsableStatus = $false
                if ($null -ne $Response) {
                    $StatusValue = if ($Response -is [System.Collections.IDictionary]) {
                        $Response['status']
                    } else {
                        $Response.status
                    }
                    $HasUsableStatus = $null -ne $StatusValue -and
                        [int]::TryParse([string] $StatusValue, [ref] $StatusCode) -and
                        $StatusCode -ge 100 -and $StatusCode -le 599
                }
                $InvitedUserId = if ($null -eq $Response) { $null } else { [string] $Response.body.invitedUser.id }
                if ($StatusCode -eq 201 -and -not [string]::IsNullOrWhiteSpace($InvitedUserId)) {
                    $InvitationResponse = if ($Response.body -is [System.Collections.IDictionary]) {
                        [pscustomobject] $Response.body
                    } else {
                        $Response.body
                    }
                    [pscustomobject] @{
                        InputIndex        = $State.InputIndex
                        Context           = $State.Context
                        EmailAddress      = $State.EmailAddress
                        Status            = 'Succeeded'
                        Success           = $true
                        StatusCode        = $StatusCode
                        AttemptCount      = $State.AttemptCount
                        RetryCount        = $State.AttemptCount - 1
                        RetryDelaySeconds = $State.RetryDelaySeconds
                        ThrottleDelaySeconds = $State.ThrottleDelaySeconds
                        BatchRetryDelaySeconds = $State.BatchRetryDelaySeconds
                        BatchThrottleDelaySeconds = $State.BatchThrottleDelaySeconds
                        OperationType     = $State.OperationType
                        InvitedUser       = $InvitationResponse
                        ErrorCode         = $null
                        ErrorMessage      = $null
                    }
                    continue
                }

                if ($StatusCode -ge 200 -and $StatusCode -lt 300) {
                    [pscustomobject] @{
                        InputIndex        = $State.InputIndex
                        Context           = $State.Context
                        EmailAddress      = $State.EmailAddress
                        Status            = 'Uncertain'
                        Success           = $false
                        StatusCode        = $StatusCode
                        AttemptCount      = $State.AttemptCount
                        RetryCount        = $State.AttemptCount - 1
                        RetryDelaySeconds = $State.RetryDelaySeconds
                        ThrottleDelaySeconds = $State.ThrottleDelaySeconds
                        BatchRetryDelaySeconds = $State.BatchRetryDelaySeconds
                        BatchThrottleDelaySeconds = $State.BatchThrottleDelaySeconds
                        OperationType     = $State.OperationType
                        InvitedUser       = $null
                        ErrorCode         = 'InvalidInvitationResponse'
                        ErrorMessage      = 'Microsoft Graph returned a successful status without an invited user id. The invitation outcome is uncertain and must be reconciled before retrying.'
                    }
                    continue
                }

                if ($null -eq $Response -or -not $HasUsableStatus) {
                    [pscustomobject] @{
                        InputIndex        = $State.InputIndex
                        Context           = $State.Context
                        EmailAddress      = $State.EmailAddress
                        Status            = 'Uncertain'
                        Success           = $false
                        StatusCode        = 0
                        AttemptCount      = $State.AttemptCount
                        RetryCount        = $State.AttemptCount - 1
                        RetryDelaySeconds = $State.RetryDelaySeconds
                        ThrottleDelaySeconds = $State.ThrottleDelaySeconds
                        OperationType     = $State.OperationType
                        InvitedUser       = $null
                        BatchRetryDelaySeconds = $State.BatchRetryDelaySeconds
                        BatchThrottleDelaySeconds = $State.BatchThrottleDelaySeconds
                        ErrorCode         = if ($null -eq $Response) { 'MissingBatchResponse' } else { 'InvalidBatchResponseStatus' }
                        ErrorMessage      = if ($null -eq $Response) { 'Microsoft Graph returned no subresponse for the invitation. The outcome is uncertain and must be reconciled before retrying.' } else { 'Microsoft Graph returned a subresponse without a valid HTTP status. The outcome is uncertain and must be reconciled before retrying.' }
                    }
                    continue
                }

                if ($StatusCode -in 408, 500, 502, 504) {
                    [pscustomobject] @{
                        InputIndex        = $State.InputIndex
                        Context           = $State.Context
                        EmailAddress      = $State.EmailAddress
                        Status            = 'Uncertain'
                        Success           = $false
                        StatusCode        = $StatusCode
                        AttemptCount      = $State.AttemptCount
                        RetryCount        = $State.AttemptCount - 1
                        RetryDelaySeconds = $State.RetryDelaySeconds
                        ThrottleDelaySeconds = $State.ThrottleDelaySeconds
                        BatchRetryDelaySeconds = $State.BatchRetryDelaySeconds
                        BatchThrottleDelaySeconds = $State.BatchThrottleDelaySeconds
                        OperationType     = $State.OperationType
                        InvitedUser       = $null
                        ErrorCode         = 'AmbiguousInvitationResponse'
                        ErrorMessage      = 'Microsoft Graph returned an ambiguous invitation response. Reconcile the invitation before retrying.'
                    }
                    continue
                }

                $IsTransient = $StatusCode -in 429, 503
                if ($IsTransient -and $State.AttemptCount -le $MaxRetries) {
                    $ResponseRetryDelay = Get-GraphimoRetryAfterSeconds -Headers $Response.headers
                    if ($null -eq $ResponseRetryDelay) {
                        $ResponseRetryDelay = [math]::Min($MaxRetryDelaySeconds, [math]::Ceiling($InitialRetryDelaySeconds * [math]::Pow(2, $State.AttemptCount - 1)))
                    }
                    $RetryDelay = [math]::Max($RetryDelay, [int] $ResponseRetryDelay)
                    $State.NextRetryIsThrottle = $StatusCode -eq 429
                    $State.NextRetryDelaySeconds = [int] $ResponseRetryDelay
                    $Retry.Add($State)
                    continue
                }

                $ErrorCode = [string] $Response.body.error.code
                $ErrorMessage = [string] $Response.body.error.message
                [pscustomobject] @{
                    InputIndex        = $State.InputIndex
                    Context           = $State.Context
                    EmailAddress      = $State.EmailAddress
                    Status            = 'Failed'
                    Success           = $false
                    StatusCode        = $StatusCode
                    AttemptCount      = $State.AttemptCount
                    RetryCount        = $State.AttemptCount - 1
                    RetryDelaySeconds = $State.RetryDelaySeconds
                    ThrottleDelaySeconds = $State.ThrottleDelaySeconds
                    BatchRetryDelaySeconds = $State.BatchRetryDelaySeconds
                    BatchThrottleDelaySeconds = $State.BatchThrottleDelaySeconds
                    OperationType     = $State.OperationType
                    InvitedUser       = $null
                    ErrorCode         = $ErrorCode
                    ErrorMessage      = $ErrorMessage
                }
            }

            if ($Retry.Count -gt 0) {
                $TimingState = @($Retry | Sort-Object InputIndex)[0]
                $RetryDelayIsThrottle = @($Retry | Where-Object { $_.NextRetryIsThrottle -and $_.NextRetryDelaySeconds -eq $RetryDelay }).Count -gt 0
                $TimingState.BatchRetryDelaySeconds += $RetryDelay
                if ($RetryDelayIsThrottle) {
                    $TimingState.BatchThrottleDelaySeconds += $RetryDelay
                }
                foreach ($State in $Retry) {
                    $State.RetryDelaySeconds += $RetryDelay
                    if ($State.NextRetryIsThrottle) {
                        $State.ThrottleDelaySeconds += $RetryDelay
                    }
                    $State.NextRetryDelaySeconds = 0
                }
                if ($RetryDelay -gt 0) {
                    Start-Sleep -Seconds $RetryDelay
                }
            }
            $Pending = $Retry
        }
        })
        $OrderedBatchResults = @($BatchResults | Sort-Object InputIndex)
        $BatchWasSimulated = @($OrderedBatchResults | Where-Object Status -eq 'WhatIf').Count -gt 0
        if ($ResultBatchAction -and -not $BatchWasSimulated -and $OrderedBatchResults.Count -gt 0) {
            $null = & $ResultBatchAction ([object[]] $OrderedBatchResults)
        }
        $OrderedBatchResults
    }
}
