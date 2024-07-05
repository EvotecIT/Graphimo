function Get-GraphUser {
    [alias('Get-GraphUsers')]
    [cmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        [parameter(ParameterSetName = 'Default')]
        [parameter(ParameterSetName = 'EmailAddress')]
        [parameter(ParameterSetName = 'UserPrincipalName')]
        [parameter(ParameterSetName = 'Filter')]
        [parameter(ParameterSetName = 'Id')]
        [alias('Authorization')][System.Collections.IDictionary] $Headers,

        [parameter(ParameterSetName = 'Id')][string] $Id,
        [parameter(ParameterSetName = 'UserPrincipalName')][string] $UserPrincipalName,
        [alias('Mail')][parameter(ParameterSetName = 'EmailAddress')][string] $EmailAddress,

        [string[]] $Property,

        [parameter(ParameterSetName = 'Filter')][string] $Filter,
        [string] $OrderBy,
        [switch] $IncludeManager,
        [int] $First,
        [string] $CountVariable,
        [string] $ConsistencyLevel,

        [switch] $MgGraph
    )

    if (-not $MgGraph -and -not $Headers -and $Script:MgGraphAuthenticated -ne $true) {
        Write-Warning -Message "No headers or MgGraph switch provided. Skipping."
        return
    }

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
    $Property = $NewProperties | Select-Object -Unique

    if ($UserPrincipalName) {
        $RelativeURI = '/users'
        $QueryParameter = [ordered]@{
            '$Select' = $Property -join ','
            '$filter' = "userPrincipalName eq '$UserPrincipalName'"
        }
    } elseif ($EmailAddress) {
        $RelativeURI = '/users'
        $QueryParameter = [ordered]@{
            '$Select' = $Property -join ','
            '$filter' = "mail eq '$EmailAddress'"
        }
    } elseif ($ID) {
        # Query a single user
        # doing it standard way doesn't seem to work so lets user filter instead
        #$RelativeURI = "/users/$ID"
        $RelativeURI = "/users"
        $QueryParameter = [ordered]@{
            '$filter' = "id eq '$ID'"
            '$Select' = $Property -join ','
        }
    } else {
        # Query multiple groups
        $RelativeURI = '/users'
        $QueryParameter = [ordered]@{
            '$Select'  = $Property -join ','
            '$filter'  = $Filter
            '$orderby' = $OrderBy
        }
    }
    if ($IncludeManager) {
        $QueryParameter['$expand'] = 'manager'
    }
    if ($CountVariable) {
        $QueryParameter['$count'] = 'true'
    }
    # if ($ConsistencyLevel) {
    #     $Headers['consistencyLevel'] = $ConsistencyLevel
    # }

    Remove-EmptyValue -Hashtable $QueryParameter

    $invokeGraphimoSplat = @{
        Uri              = $RelativeURI
        Method           = 'GET'
        QueryParameter   = $QueryParameter
        BaseUri          = $BaseURI
        First            = $First
        CountVariable    = $CountVariable
        ConsistencyLevel = $ConsistencyLevel
        MgGraph          = $MgGraph.IsPresent
    }
    if ($Headers) {
        $invokeGraphimoSplat['Headers'] = $Headers
    }

    if ($Property -contains 'onPremisesExtensionAttributes') {
        $OutputData = Invoke-Graphimo @invokeGraphimoSplat
        if ($OutputData) {
            $OutputData | Convert-GraphInternalUser
        }
    } else {
        Invoke-Graphimo @invokeGraphimoSplat
    }
}