﻿@{
    AliasesToExport      = @('Get-GraphUsers')
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = 'Przemyslaw Klys. All rights reserved.'
    Description          = 'Module that helps managing some tasks on Office 365/Azure with Microsoft Graph'
    FunctionsToExport    = @('Add-GraphGroup', 'Add-GraphGroupMember', 'Add-GraphUser', 'Connect-Graphimo', 'Get-GraphApplication', 'Get-GraphContact', 'Get-GraphGroup', 'Get-GraphGroupMember', 'Get-GraphUser', 'Import-GraphGuest', 'Invoke-Graphimo', 'Remove-GraphGroupMember', 'Remove-GraphManager', 'Remove-GraphUser', 'Set-GraphManager', 'Set-GraphUser')
    GUID                 = '48605140-a2a9-44f3-b682-3efc5cc9f2c1'
    ModuleVersion        = '0.2.2'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            ExternalModuleDependencies = @('Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Security')
            ProjectUri                 = 'https://github.com/EvotecIT/Graphimo'
            Tags                       = @('Windows', 'MacOS', 'Linux', 'Office365', 'Graph', 'Azure')
        }
    }
    RequiredModules      = @(@{
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
            ModuleName    = 'PSSharedGoods'
            ModuleVersion = '0.0.308'
        }, 'Microsoft.PowerShell.Utility', 'Microsoft.PowerShell.Security')
    RootModule           = 'Graphimo.psm1'
}