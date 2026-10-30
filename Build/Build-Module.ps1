param(
    [Alias('ConfigurationGateMode')]
    [ValidateSet('Manifest', 'Build', 'Publish')][string] $RunMode = 'Build',
    [bool] $SignModule = $true,
    [string] $CertificateThumbprint = '',
    [string[]] $AllowedCertificateThumbprints = @('92E95FB58EFFA6A4A75E77A33CDD6BFE6DD30F1A'),
    [string] $PackageRoot = (Join-Path $PSScriptRoot '../Artefacts'),
    [string] $PowerShellGalleryApiKeyPath = (Join-Path $HOME '.config/evotec/psgallery-api-key.txt'),
    [string] $GitHubApiKeyPath = (Join-Path $HOME '.config/evotec/github-api-key.txt')
)

Import-Module PSPublishModule -MinimumVersion 3.0.182 -Force -ErrorAction Stop

Invoke-ModuleBuild -ModuleName Graphimo {
    New-ConfigurationGate -Mode $RunMode
    New-ConfigurationManifest -ModuleVersion '0.2.5' -CompatiblePSEditions Desktop, Core `
        -Guid '48605140-a2a9-44f3-b682-3efc5cc9f2c1' -Author 'Przemyslaw Klys' -CompanyName Evotec `
        -Copyright 'Przemyslaw Klys. All rights reserved.' `
        -Description 'Module that helps managing some tasks on Office 365/Azure with Microsoft Graph' `
        -PowerShellVersion '5.1' -Tags Windows, MacOS, Linux, Office365, Graph, Azure `
        -ProjectUri 'https://github.com/EvotecIT/Graphimo'
    New-ConfigurationModule -Type RequiredModule -Name PSSharedGoods -Guid Auto -Version Latest -VersionSource PSGallery
    New-ConfigurationModule -Type ApprovedModule -Name PSSharedGoods, PSWriteColor, Connectimo, PSUnifi, PSWebToolbox, PSMyPassword, ADEssentials
    New-ConfigurationModuleSkip -IgnoreModuleName MSAL.PS, Microsoft.Graph.Authentication `
        -IgnoreFunctionName Connect-MgGraph, Invoke-MgGraphRequest, Get-MsalToken
    New-ConfigurationFormat -ApplyTo OnMergePSM1, OnMergePSD1 -EnableFormatting -PSD1Style Minimal
    New-ConfigurationDocumentation -Enable:$false -PathReadme 'Docs/Readme.md' -Path Docs
    New-ConfigurationTest -TestsPath Tests -Enable
    New-ConfigurationBuild -Enable -SignModule:$SignModule -CertificateThumbprint $CertificateThumbprint `
        -AllowedCertificateThumbprints $AllowedCertificateThumbprints -MergeModuleOnBuild -MergeFunctionsFromApprovedModules
    New-ConfigurationArtefact -Type Unpacked -Enable -Path (Join-Path $PackageRoot 'Unpacked') -AddRequiredModules
    New-ConfigurationArtefact -Type Packed -Enable -Path (Join-Path $PackageRoot 'Packed') `
        -ArtefactName '<ModuleName>.v<ModuleVersion>.zip' -AddRequiredModules
    New-ConfigurationPublish -Type PowerShellGallery -FilePath $PowerShellGalleryApiKeyPath -Enabled
    New-ConfigurationPublish -Type GitHub -FilePath $GitHubApiKeyPath -UserName EvotecIT -RepositoryName Graphimo -GenerateReleaseNotes -Enabled
} -SkipInstall -NoInteractive -ExitCode
