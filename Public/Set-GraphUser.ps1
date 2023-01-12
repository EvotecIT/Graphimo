function Set-GraphUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [alias('UserID')][string] $ID,
        [string] $SearchUserPrincipalName,
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
        [string] $EmployeeType,
        [switch] $ShowInAddressList,
        [alias('HireDate')][DateTime] $StartDate,
        [alias('CustomProperty')][System.Collections.IDictionary] $CustomProperties,
        [string] $ExtensionAttribute1,
        [string] $ExtensionAttribute2,
        [string] $ExtensionAttribute3,
        [string] $ExtensionAttribute4,
        [string] $ExtensionAttribute5,
        [string] $ExtensionAttribute6,
        [string] $ExtensionAttribute7,
        [string] $ExtensionAttribute8,
        [string] $ExtensionAttribute9,
        [string] $ExtensionAttribute10,
        [string] $ExtensionAttribute11,
        [string] $ExtensionAttribute12,
        [string] $ExtensionAttribute13,
        [string] $ExtensionAttribute14,
        [string] $ExtensionAttribute15,
        [System.Collections.IDictionary] $OnPremisesExtensionAttributes
    )
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
    if ($PSBoundParameters.ContainsKey('UserPrincipalName')) {
        $Body['userPrincipalName'] = $UserPrincipalName
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
    if ($PSBoundParameters.ContainsKey('EmployeeType')) {
        $Body['employeeType'] = $EmployeeType
        $BaseUri = 'https://graph.microsoft.com/beta'
    } else {
        $BaseUri = 'https://graph.microsoft.com/v1.0'
    }
    foreach ($Property in $CustomProperties.Keys) {
        $Body[$Property] = $CustomProperties[$Property]
    }

    $Body['onPremisesExtensionAttributes'] = [ordered] @{}
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute1')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute1'] = $ExtensionAttribute1
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute2')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute2'] = $ExtensionAttribute2
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute3')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute3'] = $ExtensionAttribute3
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute4')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute4'] = $ExtensionAttribute4
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute5')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute5'] = $ExtensionAttribute5
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute6')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute6'] = $ExtensionAttribute6
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute7')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute7'] = $ExtensionAttribute7
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute8')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute8'] = $ExtensionAttribute8
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute9')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute9'] = $ExtensionAttribute9
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute10')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute10'] = $ExtensionAttribute10
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute11')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute11'] = $ExtensionAttribute11
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute12')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute12'] = $ExtensionAttribute12
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute13')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute13'] = $ExtensionAttribute13
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute14')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute14'] = $ExtensionAttribute14
    }
    if ($PSBoundParameters.ContainsKey('ExtensionAttribute15')) {
        $Body['onPremisesExtensionAttributes']['extensionAttribute15'] = $ExtensionAttribute15
    }
    if ($ID) {
        $URI = "/users/$ID"
    } else {
        $URI = "/users/$SearchUserPrincipalName"
    }
    if ($Body['onPremisesExtensionAttributes'].Count -eq 0) {
        $Body.Remove('onPremisesExtensionAttributes')
    }
    if ($Body.Count -gt 0) {
        Invoke-Graphimo -Uri $URI -Method PATCH -Headers $Headers -Body $Body -BaseUri $BaseUri
    } else {
        Write-Warning -Message "Set-GraphUser - No changes were made to the user, as no field to change."
    }
}