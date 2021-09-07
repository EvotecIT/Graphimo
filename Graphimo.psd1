@{
    AliasesToExport      = 'Get-GraphUsers'
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = 'Przemyslaw Klys. All rights reserved.'
    Description          = 'Module that helps managing some tasks on Office 365/Azure with Microsoft Graph'
    FunctionsToExport    = @('Add-GraphGroupMember', 'Add-GraphUser', 'Connect-Graph', 'Get-GraphGroup', 'Get-GraphGroupMember', 'Get-GraphUser', 'Import-GraphGuest', 'Invoke-Graph', 'Remove-GraphGroupMember', 'Remove-GraphUser', 'Set-GraphUser')
    GUID                 = '48605140-a2a9-44f3-b682-3efc5cc9f2c1'
    ModuleVersion        = '0.0.6'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags       = @('Windows', 'MacOS', 'Linux', 'Office365', 'Graph', 'Azure')
            ProjectUri = 'https://github.com/EvotecIT/Graphimo'
        }
    }
    RequiredModules      = @(@{
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
            ModuleVersion = '0.0.211'
        })
    RootModule           = 'Graphimo.psm1'
}