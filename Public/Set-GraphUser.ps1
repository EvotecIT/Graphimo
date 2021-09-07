function Set-GraphUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [alias('UserID')][string] $ID,
        [string] $UserPrincipalName,
        [string] $Name,
        [alias('AccountEnabled')][nullable[bool]] $Enabled,
        [alias('FirstName')][string] $GivenName,
        [alias('LastName')][string] $Surname,
        [string] $JobTitle,
        [string] $EmployeeId,
        [string] $City,
        [string] $MailNickname,
        [string] $Country,
        [string] $Department,
        [string] $PostalCode,
        [string] $State,
        [string] $StreetAddress,
        [string] $BusinessPhones,
        [string] $MobilePhone,
        [string] $OfficeLocation,
        [string] $CompanyName,
        [string] $DisplayName,
        [switch] $ShowInAddressList
    )
    if ($ID) {
        $URI = "/users/$ID"
    } else {
        $URI = "/users/$UserPrincipalName"
    }
    $Body = [ordered]@{}
    <#
    $Body = [ordered]@{
        'jobTitle'          = if ($JobTitle) { $JobTitle } else { $null }
        'accountEnabled'    = $Enabled
        'employeeId'        = if ($PSBoundParameters.ContainsKey('EmployeeId')) { $EmployeeId } else { $null }
        'mailNickname'      = if ($PSBoundParameters.ContainsKey('MailNickname')) { $MailNickname } else { $null }
        'givenName'         = if ($PSBoundParameters.ContainsKey('givenName')) { $givenName } else { $null }
        'surname'           = if ($PSBoundParameters.ContainsKey('Surname')) { $Surnam } else { $null }
        'city'              = if ($PSBoundParameters.ContainsKey('City')) { $City } else { $null }
        'country'           = if ($PSBoundParameters.ContainsKey('Country')) { $Country } else { $null }
        'department'        = if ($PSBoundParameters.ContainsKey('Department')) { $Department } else { $null }
        'postalCode'        = if ($PSBoundParameters.ContainsKey('PostalCode')) { $PostalCode } else { $null }
        'state'             = if ($PSBoundParameters.ContainsKey('State')) { $State } else { $null }
        'streetAddress'     = if ($PSBoundParameters.ContainsKey('StreetAddress')) { $StreetAddress } else { $null }
        'businessPhones'    = if ($PSBoundParameters.ContainsKey('businessPhones')) { @($businessPhones) } else { '' }
        "mobilePhone"       = if ($PSBoundParameters.ContainsKey('mobilePhone')) { $mobilePhone } else { $null }
        "officeLocation"    = if ($PSBoundParameters.ContainsKey('OfficeLocation')) { $OfficeLocation } else { $null }
        'companyName'       = if ($PSBoundParameters.ContainsKey('CompanyName')) { $CompanyName } else { $null }
        'displayName'       = if ($PSBoundParameters.ContainsKey('DisplayName')) { $DisplayName } else { $null }
        'showInAddressList' = if ($PSBoundParameters.ContainsKey('ShowInAddressList')) { $ShowInAddressList.IsPresent } else { $null }
    }
    #>
    if ($PSBoundParameters.ContainsKey('JobTitle')) {
        $Body['jobTitle'] = $JobTitle
    }
    if ($PSBoundParameters.ContainsKey('EmployeeId')) {
        $Body['employeeId'] = $EmployeeId
    }
    if ($PSBoundParameters.ContainsKey('MailNickname')) {
        $Body['mailNickname'] = $MailNickname
    }
    if ($PSBoundParameters.ContainsKey('givenName')) {
        $Body['givenName'] = $givenName
    }
    if ($PSBoundParameters.ContainsKey('Surname')) {
        $Body['surname'] = $Surname
    }
    if ($PSBoundParameters.ContainsKey('City')) {
        $Body['city'] = $City
    }
    if ($PSBoundParameters.ContainsKey('Country')) {
        $Body['country'] = $Country
    }
    if ($PSBoundParameters.ContainsKey('Department')) {
        $Body['department'] = $Department
    }
    if ($PSBoundParameters.ContainsKey('PostalCode')) {
        $Body['postalCode'] = $PostalCode
    }
    if ($PSBoundParameters.ContainsKey('State')) {
        $Body['state'] = $State
    }
    if ($PSBoundParameters.ContainsKey('StreetAddress')) {
        $Body['streetAddress'] = $StreetAddress
    }
    if ($PSBoundParameters.ContainsKey('businessPhones')) {
        $Body['businessPhones'] = @($businessPhones)
    }
    if ($PSBoundParameters.ContainsKey('mobilePhone')) {
        $Body['mobilePhone'] = $mobilePhone
    }
    if ($PSBoundParameters.ContainsKey('OfficeLocation')) {
        $Body['officeLocation'] = $OfficeLocation
    }
    if ($PSBoundParameters.ContainsKey('CompanyName')) {
        $Body['companyName'] = $CompanyName
    }
    if ($PSBoundParameters.ContainsKey('DisplayName')) {
        $Body['displayName'] = $DisplayName
    }
    if ($PSBoundParameters.ContainsKey('ShowInAddressList')) {
        $Body['showInAddressList'] = $ShowInAddressList.IsPresent
    }
    if ($PSBoundParameters.ContainsKey('Enabled')) {
        $Body['accountEnabled'] = $Enabled
    }

    <#
    if (-not $SkipRemoveEmptyValues) {
        Remove-EmptyValue -Hashtable $Body -DoNotRemoveNull
    } else {
        Remove-EmptyValue -Hashtable $Body
    }

    #>
    if ($Body.Count -gt 0) {
        Invoke-Graph -Uri $URI -Method PATCH -Headers $Headers -Body $Body
    } else {
        Write-Warning -Message "Set-GraphUser - No changes were made to the user, as no field to change."
    }
}