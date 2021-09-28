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
        [alias('Title')][string] $JobTitle,
        [string] $EmployeeId,
        [string] $City,
        [string] $MailNickname,
        [alias('EmailAddress')][string] $Mail,
        [string] $Country,
        [string] $Department,
        [string] $PostalCode,
        [alias('Fax')][string] $FaxNumber,
        [string] $State,
        [string] $StreetAddress,
        [alias('OfficePhone')][string] $BusinessPhones,
        [alias('Mobile')][string] $MobilePhone,
        [string] $OfficeLocation,
        [string] $CompanyName,
        [string] $DisplayName,
        [switch] $ShowInAddressList,
        [alias('HireDate')][DateTime] $StartDate,
        [alias('CustomProperty')][System.Collections.IDictionary] $CustomProperties
    )
    if ($ID) {
        $URI = "/users/$ID"
    } else {
        $URI = "/users/$UserPrincipalName"
    }
    $Body = [ordered]@{}
    # https://docs.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0
    if ($PSBoundParameters.ContainsKey('StartDate')) {
        # requires fixing
        # The date and time when the user was hired or will start work in case of a future hire.
        $Body['employeeHireDate'] = $StartDate
    }
    if ($PSBoundParameters.ContainsKey('JobTitle')) {
        $Body['jobTitle'] = $JobTitle
    }
    if ($PSBoundParameters.ContainsKey('EmployeeId')) {
        $Body['employeeId'] = $EmployeeId
    }
    if ($PSBoundParameters.ContainsKey('MailNickname')) {
        $Body['mailNickname'] = $MailNickname
    }
    if ($PSBoundParameters.ContainsKey('Mail')) {
        $Body['mail'] = $Mail
    }
    if ($PSBoundParameters.ContainsKey('FaxNumber')) {
        $Body['faxNumber'] = $FaxNumber
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

    foreach ($Property in $CustomProperties.Keys) {
        $Body[$Property] = $CustomProperties[$Property]
    }

    if ($Body.Count -gt 0) {
        Invoke-Graph -Uri $URI -Method PATCH -Headers $Headers -Body $Body
    } else {
        Write-Warning -Message "Set-GraphUser - No changes were made to the user, as no field to change."
    }
}