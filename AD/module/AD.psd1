@{
    ModuleVersion     = '1.0.0'
    GUID              = '7c2a9d5e-3b4a-4e9b-a8f7-6d2e1f3c5b6c'
    Author            = 'Chris Ulatowski'
    CompanyName       = 'Enterprise Automation'
    Copyright         = '(c) 2025 Chris Ulatowski. All rights reserved.'
    Description       = 'Active Directory automation module for banking, managing users, groups, and OUs for 50,000+ accounts across 100 global locations. Supports secure bulk operations, compliance reporting, and Azure Sentinel integration.'
    PowerShellVersion = '5.1'
    RootModule        = 'AD.psm1'
    RequiredModules   = @('ActiveDirectory', 'PSFramework')
    FunctionsToExport = @('New-EnterpriseADUser', 'Remove-EnterpriseADUser', 'Disable-EnterpriseADUser', 'Enable-EnterpriseADUser', 'Move-EnterpriseADUser', 'Set-EnterpriseADUserAttribute', 'Export-EnterpriseADUserReport', 'Add-EnterpriseADUserToGroup', 'Remove-EnterpriseADUserFromGroup', 'New-EnterpriseADGroup', 'Export-EnterpriseADGroupReport', 'New-EnterpriseADOU', 'Move-EnterpriseADOU', 'Remove-EnterpriseADOU')
    CmdletsToExport   = @()
    VariablesToExport = '*'
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('ActiveDirectory', 'Automation', 'Banking', 'PowerShell')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/chrisulatowski/Enterprise.Automation.AD'
        }
    }
}
