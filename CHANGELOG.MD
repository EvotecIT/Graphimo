### 0.2.0 - 2024.07.05
- Added support for `Connect-MgGraph` by using `-MgGraph` directly in the cmdlet or `Connect-Graphimo -MgGraphConfiguration @{}`

### 0.0.20 - 2023.10.20
- Improve `Get-GraphUser` to not crash when no data is returned when using onPremisesExtensionAttributes

### 0.0.19 - 2023.10.02
- Improves `Import-GraphGuest` with ability top choose UserType

### 0.0.18 - 2023.04.11
- Fixes for edge cases

### 0.0.17 - 2023.04.11
- Fix `Stackoverflow` in Invoke-Graphimo

### 0.0.16 - 2023.01.13
- Added support for extensionAttributes
- Added support to limit output to First X entries
- Improve searcing username when using special characters

### 0.0.15 - 2022.09.30
- Support for MsolToken refresh

### 0.0.14 - 2022.09.30
- Added `EmployeeType` with a switch to beta profile when used

### 0.0.13 - 2022.07.27
- Renamed Invoke-Graph to Invoke-Grapimo and Connect-Graph to Connect-Graphimo to not collide with Microsoft Graph module