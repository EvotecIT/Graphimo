function Convert-GraphInternalUser {
    <#
    .SYNOPSIS
    Converts user returned by graph with onPremisesExtensionAttributes to new simplified object

    .DESCRIPTION
    Converts user returned by graph with onPremisesExtensionAttributes to new simplified object

    .PARAMETER InputObject
    The object to convert

    .EXAMPLE
    An example

    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline)][PSCustomObject[]] $InputObject
    )
    Process {
        $InputObject | ForEach-Object {
            $NewObject = [ordered] @{}
            $Object = $_
            foreach ($Property in $Object.PSObject.Properties.Name) {
                if ($Property -eq 'onPremisesExtensionAttributes') {
                    foreach ($ExtensionAttribute in $Object.onPremisesExtensionAttributes.PSObject.Properties.Name) {
                        $NewObject[$ExtensionAttribute] = $Object.onPremisesExtensionAttributes.$ExtensionAttribute
                    }
                } else {
                    $NewObject[$Property] = $Object.$Property
                }
            }
            [PSCustomObject] $NewObject
        }
    }
}