function Set-GraphAzureUser {
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Collections.IDictionary] $Authorization,
        [string] $UserID,
        [string] $UserPrincipalName,
        [string] $Name,
        [alias('FirstName')][string] $GivenName,
        [alias('LastName')][string] $Surname,
        [string] $JobTitle,
        [string] $EmployeeId,
        [string] $City,
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
    if ($UserID) {
        $URI = "/users/$UserID"
    } else {
        $URI = "/users/$UserPrincipalName"
    }
    $Body = [ordered]@{
        'jobTitle'          = if ($JobTitle) { $JobTitle } else { $null }
        'employeeId'        = if ($EmployeeId) { $EmployeeId } else { $null }
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
    }
    if (-not $SkipRemoveEmptyValues) {
        Remove-EmptyValue -Hashtable $Body -DoNotRemoveNull #-DoNotRemoveEmptyArray:$DoNotRemoveEmptyArray -DoNotRemoveEmptyDictionary:$DoNotRemoveEmptyDictionary
    }
    if ($Body.Count -gt 0) {
        Invoke-O365Graph -Uri $URI -Method PATCH -Headers $Authorization -Body $Body
    }
}