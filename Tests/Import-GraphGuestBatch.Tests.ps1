BeforeAll {
    . (Join-Path $PSScriptRoot '..\Private\ConvertTo-GraphimoBoolean.ps1')
    . (Join-Path $PSScriptRoot '..\Private\Get-GraphimoRetryAfterSeconds.ps1')
    . (Join-Path $PSScriptRoot '..\Private\New-GraphGuestInvitationBody.ps1')
    . (Join-Path $PSScriptRoot '..\Public\Import-GraphGuest.ps1')
    . (Join-Path $PSScriptRoot '..\Public\Import-GraphGuestBatch.ps1')

    function Invoke-Graphimo {
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [uri] $Uri,
            [string] $Method,
            [System.Collections.IDictionary] $Headers,
            [System.Collections.IDictionary] $Body,
            [switch] $MgGraph,
            [switch] $ThrowOnError
        )
    }

    function New-TestInvitation {
        param(
            [int] $Index,
            [string] $EmailAddress = "guest$Index@example.com"
        )

        [pscustomobject] @{
            DisplayName  = "Guest $Index"
            EmailAddress = $EmailAddress
            Context      = [pscustomobject] @{ EmployeeId = "employee-$Index" }
        }
    }
}

Describe 'Import-GraphGuestBatch' {
    BeforeEach {
        $script:BatchBodies = [System.Collections.Generic.List[object]]::new()
        Mock Start-Sleep {}
        Mock Invoke-Graphimo {
            $script:BatchBodies.Add($Body)
            [pscustomobject] @{
                responses = @(
                    foreach ($Request in $Body.requests) {
                        [pscustomobject] @{
                            id      = $Request.id
                            status  = 201
                            headers = @{}
                            body    = [pscustomobject] @{
                                invitedUserEmailAddress = $Request.body.invitedUserEmailAddress
                                invitedUser             = [pscustomobject] @{ id = "created-$($Request.id)" }
                            }
                        }
                    }
                )
            }
        }
    }

    It 'uses Graph batches of at most twenty and emits one successful result per invitation' {
        $invitations = @(for ($Index = 0; $Index -lt 25; $Index++) { New-TestInvitation -Index $Index })

        $result = @(Import-GraphGuestBatch -Invitation $invitations -MgGraph)

        $result.Count | Should -Be 25
        @($result | Where-Object Success).Count | Should -Be 25
        $script:BatchBodies.Count | Should -Be 2
        $script:BatchBodies[0].requests.Count | Should -Be 20
        $script:BatchBodies[1].requests.Count | Should -Be 5
        Should -Invoke Invoke-Graphimo -Times 2 -Exactly -ParameterFilter {
            $Uri -eq '/$batch' -and $Method -eq 'POST' -and $MgGraph -and
            $ThrowOnError -and $Confirm -eq $false
        }
    }

    It 'invokes the durable result callback once per completed Graph batch before emitting results' {
        $script:CheckpointBatches = [System.Collections.Generic.List[object]]::new()
        $checkpointAction = {
            param([object[]] $CompletedBatch)
            $script:CheckpointBatches.Add(@($CompletedBatch))
        }
        $invitations = @(for ($Index = 0; $Index -lt 21; $Index++) { New-TestInvitation -Index $Index })

        $result = @(Import-GraphGuestBatch -Invitation $invitations -MgGraph -ResultBatchAction $checkpointAction)

        $result.Count | Should -Be 21
        $script:CheckpointBatches.Count | Should -Be 2
        $script:CheckpointBatches[0].Count | Should -Be 20
        $script:CheckpointBatches[1].Count | Should -Be 1
    }

    It 'invokes the pending callback only for the batch that is immediately about to dispatch' {
        $script:PendingBatches = [System.Collections.Generic.List[object]]::new()
        $pendingAction = {
            param([object[]] $PendingBatch)
            $script:PendingBatches.Add(@($PendingBatch))
            if ($script:PendingBatches.Count -eq 2) {
                throw 'simulated stop before second dispatch'
            }
        }
        $invitations = @(for ($Index = 0; $Index -lt 21; $Index++) { New-TestInvitation -Index $Index })

        { Import-GraphGuestBatch -Invitation $invitations -MgGraph -PendingBatchAction $pendingAction } | Should -Throw '*simulated stop before second dispatch*'

        $script:PendingBatches.Count | Should -Be 2
        Should -Invoke Invoke-Graphimo -Times 1 -Exactly
    }

    It 'builds the invitation body with caller defaults' {
        $invitation = New-TestInvitation -Index 1

        $null = Import-GraphGuestBatch -Invitation @($invitation) -MgGraph -SendInvitationMessage $true -InviteRedirectUrl 'https://example.com/complete' -UserType Member

        $body = $script:BatchBodies[0].requests[0].body
        $body.invitedUserDisplayName | Should -Be 'Guest 1'
        $body.invitedUserEmailAddress | Should -Be 'guest1@example.com'
        $body.sendInvitationMessage | Should -BeTrue
        $body.inviteRedirectUrl | Should -Be 'https://example.com/complete'
        $body.invitedUserType | Should -Be 'Member'
    }

    It 'parses CSV-style false boolean overrides without enabling invitation email or redemption reset' {
        $invitation = New-TestInvitation -Index 1
        $invitation | Add-Member -NotePropertyName SendInvitationMessage -NotePropertyValue 'False'
        $invitation | Add-Member -NotePropertyName ResetRedemption -NotePropertyValue 'False'

        $null = Import-GraphGuestBatch -Invitation @($invitation) -MgGraph -SendInvitationMessage $true

        $body = $script:BatchBodies[0].requests[0].body
        $body.sendInvitationMessage | Should -BeFalse
        $body.resetRedemption | Should -BeFalse
    }

    It 'keeps callback success output out of the invitation result stream' {
        $pendingAction = { 'pending callback output' }
        $resultAction = { 'result callback output' }

        $result = @(Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph -PendingBatchAction $pendingAction -ResultBatchAction $resultAction)

        $result.Count | Should -Be 1
        $result[0].Status | Should -Be 'Succeeded'
    }

    It 'retries throttled subrequests once after the Retry-After delay' {
        $script:CallCount = 0
        Mock Invoke-Graphimo {
            $script:CallCount++
            $Request = $Body.requests[0]
            if ($script:CallCount -eq 1) {
                [pscustomobject] @{
                    responses = @([pscustomobject] @{
                            id      = $Request.id
                            status  = 429
                            headers = @{ 'Retry-After' = '3' }
                            body    = [pscustomobject] @{ error = [pscustomobject] @{ code = 'TooManyRequests'; message = 'Retry later.' } }
                        })
                }
            } else {
                [pscustomobject] @{
                    responses = @([pscustomobject] @{
                            id      = $Request.id
                            status  = 201
                            headers = @{}
                            body    = [pscustomobject] @{ invitedUser = [pscustomobject] @{ id = 'created-1' } }
                        })
                }
            }
        }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph

        $result.Success | Should -BeTrue
        $result.AttemptCount | Should -Be 2
        $result.RetryCount | Should -Be 1
        $result.RetryDelaySeconds | Should -Be 3
        $result.ThrottleDelaySeconds | Should -Be 3
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 3 }
    }

    It 'retries a service-unavailable subrequest using Retry-After' {
        $script:CallCount = 0
        Mock Invoke-Graphimo {
            $script:CallCount++
            $Request = $Body.requests[0]
            if ($script:CallCount -eq 1) {
                [pscustomobject] @{
                    responses = @([pscustomobject] @{
                            id      = $Request.id
                            status  = 503
                            headers = @{ 'Retry-After' = '4' }
                            body    = [pscustomobject] @{ error = [pscustomobject] @{ code = 'ServiceUnavailable'; message = 'Retry later.' } }
                        })
                }
            } else {
                [pscustomobject] @{
                    responses = @([pscustomobject] @{
                            id      = $Request.id
                            status  = 201
                            headers = @{}
                            body    = [pscustomobject] @{ invitedUser = [pscustomobject] @{ id = 'created-1' } }
                        })
                }
            }
        }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph

        $result.Success | Should -BeTrue
        $result.AttemptCount | Should -Be 2
        $result.RetryDelaySeconds | Should -Be 4
        $result.ThrottleDelaySeconds | Should -Be 0
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 4 }
    }

    It 'builds reset-redemption requests with the existing invited user id' {
        $invitation = New-TestInvitation -Index 1
        $invitation | Add-Member -NotePropertyName ResetRedemption -NotePropertyValue $true
        $invitation | Add-Member -NotePropertyName InvitedUserID -NotePropertyValue 'existing-user-1'
        $invitation | Add-Member -NotePropertyName OperationType -NotePropertyValue 'redemption'

        $result = Import-GraphGuestBatch -Invitation @($invitation) -MgGraph

        $body = $script:BatchBodies[0].requests[0].body
        $body.resetRedemption | Should -BeTrue
        $body.invitedUser.id | Should -Be 'existing-user-1'
        $result.OperationType | Should -Be 'redemption'
    }

    It 'retries only failed subrequests and does not repeat completed invitations' {
        $script:CallCount = 0
        Mock Invoke-Graphimo {
            $script:CallCount++
            if ($script:CallCount -eq 1) {
                [pscustomobject] @{
                    responses = @(
                        [pscustomobject] @{
                            id      = $Body.requests[0].id
                            status  = 201
                            headers = @{}
                            body    = [pscustomobject] @{ invitedUser = [pscustomobject] @{ id = 'created-1' } }
                        }
                        [pscustomobject] @{
                            id      = $Body.requests[1].id
                            status  = 429
                            headers = @{ 'Retry-After' = '2' }
                            body    = [pscustomobject] @{ error = [pscustomobject] @{ code = 'TooManyRequests'; message = 'Retry later.' } }
                        }
                    )
                }
            } else {
                $Body.requests.Count | Should -Be 1
                [pscustomobject] @{
                    responses = @([pscustomobject] @{
                            id      = $Body.requests[0].id
                            status  = 201
                            headers = @{}
                            body    = [pscustomobject] @{ invitedUser = [pscustomobject] @{ id = 'created-2' } }
                        })
                }
            }
        }

        $result = @(Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1), (New-TestInvitation -Index 2)) -MgGraph)

        $result.Count | Should -Be 2
        @($result | Where-Object Success).Count | Should -Be 2
        ($result | Where-Object EmailAddress -eq 'guest1@example.com').AttemptCount | Should -Be 1
        ($result | Where-Object EmailAddress -eq 'guest2@example.com').AttemptCount | Should -Be 2
        Should -Invoke Invoke-Graphimo -Times 2 -Exactly
    }

    It 'does not retry a missing subresponse because the invitation outcome is uncertain' {
        Mock Invoke-Graphimo { [pscustomobject] @{ responses = @() } }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph -MaxRetries 2 -InitialRetryDelaySeconds 1

        $result.Success | Should -BeFalse
        $result.Status | Should -Be 'Uncertain'
        $result.ErrorCode | Should -Be 'MissingBatchResponse'
        $result.AttemptCount | Should -Be 1
        $result.RetryCount | Should -Be 0
        $result.RetryDelaySeconds | Should -Be 0
        Should -Invoke Invoke-Graphimo -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not retry a subresponse without a valid HTTP status' {
        Mock Invoke-Graphimo {
            [pscustomobject] @{ responses = @([pscustomobject] @{ id = $Body.requests[0].id; headers = @{}; body = [pscustomobject] @{} }) }
        }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph -MaxRetries 2

        $result.Status | Should -Be 'Uncertain'
        $result.ErrorCode | Should -Be 'InvalidBatchResponseStatus'
        Should -Invoke Invoke-Graphimo -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'reports shared retry timing once while preserving per-item retry details' {
        $script:CallCount = 0
        Mock Invoke-Graphimo {
            $script:CallCount++
            if ($script:CallCount -eq 1) {
                [pscustomobject] @{ responses = @(
                    foreach ($Request in $Body.requests) {
                        [pscustomobject] @{ id = $Request.id; status = 429; headers = @{ 'Retry-After' = '3' }; body = [pscustomobject] @{ error = [pscustomobject] @{ code = 'TooManyRequests' } } }
                    }
                ) }
            } else {
                [pscustomobject] @{ responses = @(
                    foreach ($Request in $Body.requests) {
                        [pscustomobject] @{ id = $Request.id; status = 201; headers = @{}; body = [pscustomobject] @{ invitedUser = [pscustomobject] @{ id = "created-$($Request.id)" } } }
                    }
                ) }
            }
        }

        $result = @(Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1), (New-TestInvitation -Index 2)) -MgGraph)

        ($result | Measure-Object BatchRetryDelaySeconds -Sum).Sum | Should -Be 3
        ($result | Measure-Object BatchThrottleDelaySeconds -Sum).Sum | Should -Be 3
        ($result | Measure-Object RetryDelaySeconds -Sum).Sum | Should -Be 6
    }

    It 'does not retry a permanent invitation failure' {
        Mock Invoke-Graphimo {
            $Request = $Body.requests[0]
            [pscustomobject] @{
                responses = @([pscustomobject] @{
                        id      = $Request.id
                        status  = 400
                        headers = @{}
                        body    = [pscustomobject] @{ error = [pscustomobject] @{ code = 'Request_BadRequest'; message = 'Domain is blocked.' } }
                    })
            }
        }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph

        $result.Success | Should -BeFalse
        $result.StatusCode | Should -Be 400
        $result.ErrorCode | Should -Be 'Request_BadRequest'
        $result.ErrorMessage | Should -Be 'Domain is blocked.'
        $result.AttemptCount | Should -Be 1
        Should -Invoke Invoke-Graphimo -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'marks ambiguous gateway subresponses uncertain without retrying' {
        Mock Invoke-Graphimo {
            $Request = $Body.requests[0]
            [pscustomobject] @{
                responses = @([pscustomobject] @{
                        id = $Request.id
                        status = 502
                        headers = @{}
                        body = [pscustomobject] @{ error = [pscustomobject] @{ code = 'BadGateway'; message = 'Gateway response was lost.' } }
                    })
            }
        }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph -MaxRetries 2

        $result.Status | Should -Be 'Uncertain'
        $result.ErrorCode | Should -Be 'AmbiguousInvitationResponse'
        Should -Invoke Invoke-Graphimo -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'marks a malformed successful response uncertain instead of retryable failure' {
        Mock Invoke-Graphimo {
            $Request = $Body.requests[0]
            [pscustomobject] @{
                responses = @([pscustomobject] @{
                        id      = $Request.id
                        status  = 201
                        headers = @{}
                        body    = [pscustomobject] @{}
                    })
            }
        }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph

        $result.Success | Should -BeFalse
        $result.Status | Should -Be 'Uncertain'
        $result.ErrorCode | Should -Be 'InvalidInvitationResponse'
        $result.AttemptCount | Should -Be 1
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'does not retry a thrown batch transport failure because the invitation outcome is uncertain' {
        Mock Invoke-Graphimo { throw 'connection closed after send' }

        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph

        $result.Success | Should -BeFalse
        $result.Status | Should -Be 'Uncertain'
        $result.ErrorCode | Should -Be 'BatchTransportUncertain'
        $result.ErrorMessage | Should -BeLike '*reconciled before retrying*'
        Should -Invoke Invoke-Graphimo -Times 1 -Exactly
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }

    It 'returns a local validation failure without sending a batch for a missing email address' {
        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1 -EmailAddress '')) -MgGraph

        $result.Success | Should -BeFalse
        $result.ErrorCode | Should -Be 'InvalidInvitation'
        Should -Invoke Invoke-Graphimo -Times 0 -Exactly
    }

    It 'does not submit mutations under WhatIf' {
        $result = Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1)) -MgGraph -WhatIf

        $result.Status | Should -Be 'WhatIf'
        Should -Invoke Invoke-Graphimo -Times 0 -Exactly
    }

    It 'does not run result callbacks for mixed validation and WhatIf rows' {
        $script:ResultCallbackCount = 0
        $resultAction = { $script:ResultCallbackCount++ }

        $result = @(Import-GraphGuestBatch -Invitation @((New-TestInvitation -Index 1 -EmailAddress ''), (New-TestInvitation -Index 2)) -MgGraph -WhatIf -ResultBatchAction $resultAction)

        $result.Count | Should -Be 2
        $script:ResultCallbackCount | Should -Be 0
        Should -Invoke Invoke-Graphimo -Times 0 -Exactly
    }
}

Describe 'Import-GraphGuest invitation body compatibility' {
    BeforeEach {
        Mock Invoke-Graphimo {}
    }

    It 'uses the same shared body builder for a single reset-redemption invitation' {
        Import-GraphGuest -EmailAddress 'guest@example.com' -Name 'Guest' -SendInvitationMessage -ResetRedemption -InvitedUserID 'guest-id' -UserType Guest -MgGraph

        Should -Invoke Invoke-Graphimo -Times 1 -Exactly -ParameterFilter {
            $Body.invitedUserEmailAddress -eq 'guest@example.com' -and
            $Body.sendInvitationMessage -eq $true -and
            $Body.resetRedemption -eq $true -and
            $Body.invitedUser.id -eq 'guest-id' -and
            $Body.invitedUserType -eq 'Guest'
        }
    }
}

Describe 'Get-GraphimoRetryAfterSeconds' {
    It 'reads Retry-After case-insensitively from a dictionary' {
        Get-GraphimoRetryAfterSeconds -Headers @{ 'retry-AFTER' = '7' } | Should -Be 7
    }
}
