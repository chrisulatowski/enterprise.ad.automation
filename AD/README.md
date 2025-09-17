# Enterprise.Automation.AD

PowerShell module for Active Directory user management in a banking environment, designed for 100+ users across 100 OUs, scalable to 50,000 accounts. Supports secure, auditable user creation with batching, logging, and error handling.

## Features
- **User Creation**: Create single or bulk users (CSV input) with minimal attributes.
- **Batching**: Supports batch sizes (10, 20, 50, 100, 200, 500, 1000) for scalability.
- **Logging**: Generic CSV logs for Azure Sentinel and Windows Event Viewer for compliance.
- **Safety**: `-WhatIf` and `-Confirm` for safe operations.
- **Testing**: Pester tests for reliability.

## Example
Create 100 trader accounts from CSV:
```powershell
New-EnterpriseADUser -InputFile ".\examples\bankcorp_users.csv" -BatchSize 100
