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
        'jobTitle'          = $JobTitle
        'employeeId'        = $EmployeeId
        'givenName'         = $givenName
        'surname'           = $Surname
        'city'              = $City
        'country'           = $Country
        'department'        = $Department
        'postalCode'        = $PostalCode
        'state'             = $State
        'streetAddress'     = $StreetAddress
        'businessPhones'    = if ($businessPhones) { @($businessPhones) } else {}
        "mobilePhone"       = $mobilePhone
        "officeLocation"    = $OfficeLocation
        'companyName'       = $CompanyName
        'displayName'       = $DisplayName
        'showInAddressList' = $ShowInAddressList.IsPresent
    }
    Remove-EmptyValue -Hashtable $Body
    if ($Body.Count -gt 0) {
        Invoke-O365Graph -Uri $URI -Method PATCH -Headers $Authorization -Body $Body
    }
}