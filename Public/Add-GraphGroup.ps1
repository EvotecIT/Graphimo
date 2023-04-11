function Add-GraphGroup {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [string] $DisplayName,
        [string] $Name,
        [string] $Description,
        [string] $MailNickname,
        [switch] $SecurityEnabled,
        [switch] $MailEnabled
    )
    $URI = "/groups"
    $BaseUri = 'https://graph.microsoft.com/v1.0'
    $Body = [ordered]@{
        groupTypes = @()
    }

    if ($PSBoundParameters.ContainsKey('DisplayName')) {
        $Body['displayName'] = $DisplayName
    }
    if ($PSBoundParameters.ContainsKey('Name')) {
        $Body['name'] = $Name
    }
    if ($PSBoundParameters.ContainsKey('Description')) {
        $Body['description'] = $Description
    }
    if ($PSBoundParameters.ContainsKey('MailNickname')) {
        $Body['mailNickname'] = $MailNickname
    }
    if ($PSBoundParameters.ContainsKey('SecurityEnabled')) {
        $Body['securityEnabled'] = $SecurityEnabled.IsPresent
    }
    if ($PSBoundParameters.ContainsKey('MailEnabled')) {
        $Body['mailEnabled'] = $MailEnabled.IsPresent
    }
    if ($Body.Count -gt 0) {
        Invoke-Graphimo -Uri $URI -Method POST -Headers $Headers -Body $Body -BaseUri $BaseUri
    }
}