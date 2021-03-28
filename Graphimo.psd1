@{
    AliasesToExport      = @()
    Author               = 'Przemyslaw Klys'
    CmdletsToExport      = @()
    CompanyName          = 'Evotec'
    CompatiblePSEditions = @('Desktop', 'Core')
    Copyright            = 'Przemyslaw Klys. All rights reserved.'
    Description          = 'Module that helps managing some tasks on Office 365/Azure with Microsoft Graph'
    FunctionsToExport    = @('Connect-O365Graph', 'Get-GraphAzureGuest', 'Get-GraphCalendarEvents', 'Get-GraphUserCalendars', 'Get-GraphUsers', 'Import-GraphAzureGuest', 'Invoke-O365Graph', 'Remove-GraphMailboxCalendar', 'Remove-GraphMailboxCalendarEvent')
    GUID                 = '48605140-a2a9-44f3-b682-3efc5cc9f2c1'
    ModuleVersion        = '0.0.1'
    PowerShellVersion    = '5.1'
    PrivateData          = @{
        PSData = @{
            Tags       = @('Windows', 'MacOS', 'Linux', 'Office365', 'Graph', 'Azure')
            ProjectUri = 'https://github.com/EvotecIT/Graphimo'
        }
    }
    RequiredModules      = @(@{
            ModuleVersion = '0.0.198'
            ModuleName    = 'PSSharedGoods'
            Guid          = 'ee272aa8-baaa-4edf-9f45-b6d6f7d844fe'
        })
    RootModule           = 'Graphimo.psm1'
}