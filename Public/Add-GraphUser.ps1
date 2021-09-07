function Add-GraphUser {
    [cmdletBinding(SupportsShouldProcess)]
    param(
        [parameter(Mandatory)][alias('Authorization')][System.Collections.IDictionary] $Headers,
        [Parameter(Mandatory)][string] $UserPrincipalName,
        [string] $Name,
        [parameter(Mandatory)][alias('AccountEnabled')][bool] $Enabled,
        [alias('FirstName')][string] $GivenName,
        [alias('LastName')][string] $Surname,
        [string] $JobTitle,
        [string] $EmployeeId,
        [string] $City,
        [Parameter(Mandatory)][string] $MailNickname,
        [string] $Country,
        [string] $Department,
        [string] $PostalCode,
        [string] $State,
        [string] $StreetAddress,
        [string] $BusinessPhones,
        [string] $MobilePhone,
        [string] $OfficeLocation,
        [string] $CompanyName,
        [Parameter(Mandatory)][string] $DisplayName,
        [switch] $ShowInAddressList,
        [switch] $DoNotForceChangePasswordNextSignIn,
        [Parameter(Mandatory)][string] $Password
    )
    $URI = "/users"
    $Body = [ordered]@{}
    <#
    $Body = [ordered]@{
        'userPrincipalName' = $UserPrincipalName
        'jobTitle'          = if ($JobTitle) { $JobTitle } else { $null }
        'accountEnabled'    = $Enabled
        'employeeId'        = if ($EmployeeId) { $EmployeeId } else { $null }
        'mailNickname'      = if ($MailNickname) { $MailNickname } else { $null }
        'givenName'         = if ($givenName) { $givenName } else { $null }
        'surname'           = if ($Surname) { $Surname } else { $null }
        'city'              = if ($City) { $City } else { $null }
        'country'           = if ($Country) { $Country } else { $null }
        'department'        = if ($Department) { $Department } else { $null }
        'postalCode'        = if ($PostalCode) { $PostalCode } else { $null }
        'state'             = if ($State) { $State } else { $null }
        'streetAddress'     = if ($StreetAddress) { $StreetAddress } else { $null }
        'businessPhones'    = if ($businessPhones) { @($businessPhones) } else { '' }
        "mobilePhone"       = if ($mobilePhone) { $mobilePhone } else { $null }
        "officeLocation"    = if ($OfficeLocation) { $OfficeLocation } else { $null }
        'companyName'       = if ($CompanyName) { $CompanyName } else { $null }
        'displayName'       = if ($DisplayName) { $DisplayName } else { $null }
        'showInAddressList' = $ShowInAddressList.IsPresent
        'passwordProfile'   = @{
            forceChangePasswordNextSignIn = -not $DoNotForceChangePasswordNextSignIn.IsPresent
            password                      = $Password
        }
    }
    #>

    if ($PSBoundParameters.ContainsKey('UserPrincipalName')) {
        $Body['userPrincipalName'] = $UserPrincipalName
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

    $Body['passwordProfile'] = @{
        forceChangePasswordNextSignIn = -not $DoNotForceChangePasswordNextSignIn.IsPresent
        password                      = $Password
    }
    #Remove-EmptyValue -Hashtable $Body
    if ($Body.Count -gt 0) {
        Invoke-Graph -Uri $URI -Method POST -Headers $Headers -Body $Body
    }
}