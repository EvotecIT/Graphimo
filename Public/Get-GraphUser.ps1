function Get-GraphUser {
    [alias('Get-GraphUsers')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [parameter(ParameterSetName = 'Default', Mandatory)]
        [parameter(ParameterSetName = 'EmailAddress', Mandatory)]
        [parameter(ParameterSetName = 'UserPrincipalName', Mandatory)]
        [parameter(ParameterSetName = 'Filter', Mandatory)]
        [parameter(ParameterSetName = 'Id', Mandatory)]
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,

        [parameter(ParameterSetName = 'Id')][string] $Id,
        [parameter(ParameterSetName = 'UserPrincipalName')][string] $UserPrincipalName,
        [alias('Mail')][parameter(ParameterSetName = 'EmailAddress')][string] $EmailAddress,

        [string[]] $Property,

        [parameter(ParameterSetName = 'Filter')][string] $Filter,
        [string] $OrderBy,
        [switch] $IncludeManager
    )
    if ($Property -contains 'EmployeeType') {
        $BaseURI = 'https://graph.microsoft.com/beta'
    } else {
        $BaseURI = 'https://graph.microsoft.com/v1.0'
    }
    $NewProperties = foreach ($P in $Property) {
        if ($P -like "extensionAttribute*") {
            'onPremisesExtensionAttributes'
        } else {
            $P
        }
    }
    $Property = $NewProperties | Sort-Object -Unique

    if ($UserPrincipalName) {
        $RelativeURI = '/users'
        $QueryParameter = @{
            '$Select' = $Property -join ','
            '$filter' = "userPrincipalName eq '$UserPrincipalName'"
        }
    } elseif ($EmailAddress) {
        $RelativeURI = '/users'
        $QueryParameter = @{
            '$Select' = $Property -join ','
            '$filter' = "mail eq '$EmailAddress'"
        }
    } elseif ($ID) {
        # Query a single user
        # doing it standard way doesn't seem to work so lets user filter instead
        #$RelativeURI = "/users/$ID"
        $RelativeURI = "/users"
        $QueryParameter = @{
            '$filter' = "id eq '$ID'"
            '$Select' = $Property -join ','
        }
    } else {
        # Query multiple groups
        $RelativeURI = '/users'
        $QueryParameter = @{
            '$Select'  = $Property -join ','
            '$filter'  = $Filter
            '$orderby' = $OrderBy
        }
    }
    if ($IncludeManager) {
        $QueryParameter['$expand'] = 'manager'
    }

    Remove-EmptyValue -Hashtable $QueryParameter

    $Output = Invoke-Graphimo -Uri $RelativeURI -Method GET -Headers $Headers -QueryParameter $QueryParameter -BaseUri $BaseURI
    if ($Property -contains 'onPremisesExtensionAttributes') {
        Convert-GraphInternalUser -InputObject $Output
    } else {
        $Output
    }
}