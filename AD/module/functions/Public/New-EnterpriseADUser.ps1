<#PSScriptInfo
.VERSION 1.0.0
.GUID 8d3e4b1a-2c4f-4b7b-9c2e-7f1a3d5c6b8a
.AUTHOR Chris Ulatowski
.COMPANYNAME Enterprise Automation
.COPYRIGHT (c) 2025 Chris Ulatowski. All rights reserved.
.DESCRIPTION Creates single or bulk AD users from CSV for a banking environment, supporting 100+ users across 100 OUs with batching, logging, and error handling.
.TAGS ActiveDirectory, Automation, Banking, PowerShell
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/chrisulatowski/Enterprise.Automation.AD
#>

function New-EnterpriseADUser {
    <#
    .SYNOPSIS
        Creates an Active Directory user account for a banking environment.
    .DESCRIPTION
        Creates single or bulk AD users from CSV with banking attributes, designed for 100+ users across 100 OUs. Supports batching, logging to Azure Sentinel-compatible CSV and Event Viewer, with error handling and -WhatIf.
    .PARAMETER SamAccountName
        The SAM account name of the user (mandatory).
    .PARAMETER FirstName
        The user's first name (mandatory).
    .PARAMETER LastName
        The user's last name (mandatory).
    .PARAMETER OU
        The organizational unit path (mandatory, e.g., OU=Trading,OU=New York,DC=itpositive,DC=com).
    .PARAMETER Password
        The initial password (mandatory, SecureString).
    .PARAMETER UserPrincipalName
        The user's UPN (e.g., user@itpositive.com).
    .PARAMETER DisplayName
        The user's display name (e.g., First Last).
    .PARAMETER Department
        The user's department (e.g., Trading).
    .PARAMETER Title
        The user's title (e.g., Employee).
    .PARAMETER Email
        The user's email address.
    .PARAMETER EmployeeID
        The user's employee ID.
    .PARAMETER PhoneNumber
        The user's phone number.
    .PARAMETER Manager
        The user's manager (DistinguishedName, optional).
    .PARAMETER Notes
        Additional notes (maps to AD 'info' attribute).
    .PARAMETER BatchSize
        Number of users to process per batch (default: 100).
    .PARAMETER InputFile
        Path to CSV file for bulk creation (e.g., enterprise_users.csv with Name,SamAccountName,FirstName,LastName,DisplayName,OU,Password,UserPrincipalName,Department,Title,Email,EmployeeID,PhoneNumber,Manager,Notes).
    .EXAMPLE
        $pwd = ConvertTo-SecureString "TempPass123!" -AsPlainText -Force
        New-EnterpriseADUser -SamAccountName jdoe -FirstName John -LastName Doe -OU "OU=Trading,OU=New York,DC=itpositive,DC=com" -Password $pwd -UserPrincipalName jdoe@itpositive.com -DisplayName "John Doe"
        Creates a single user with banking attributes.
    .EXAMPLE
        New-EnterpriseADUser -InputFile "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_users.csv" -BatchSize 10
        Creates 10 trader accounts from CSV in a batch.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true, ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$SamAccountName,

        [Parameter(Mandatory=$true, ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FirstName,

        [Parameter(Mandatory=$true, ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$LastName,

        [Parameter(Mandatory=$true, ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$OU,

        [Parameter(Mandatory=$true, ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [SecureString]$Password,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$UserPrincipalName,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$DisplayName,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$Department,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$Title,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$Email,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$EmployeeID,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$PhoneNumber,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$Manager,

        [Parameter(ParameterSetName="Single", ValueFromPipelineByPropertyName=$true)]
        [string]$Notes,

        [Parameter(ParameterSetName="Bulk")]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile,

        [Parameter(ParameterSetName="Single")]
        [Parameter(ParameterSetName="Bulk")]
        [ValidateRange(10,1000)]
        [int]$BatchSize = 100
    )

    begin {
        Import-Module PSFramework -ErrorAction Stop
        $logFile = Join-Path $PSScriptRoot "../logs/ADUser_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $eventSource = "EnterpriseADAutomation"
        if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
            New-EventLog -LogName Application -Source $eventSource -ErrorAction SilentlyContinue
        }
        Write-PSFMessage -Level Host -Message "Starting user creation process" -FunctionName "New-EnterpriseADUser"
        $results = @()
        $batch = @()
    }

    process {
        if ($InputFile) {
            $users = Import-Csv -Path $InputFile
            $batchCount = 0
            foreach ($user in $users) {
                $batch += $user
                $batchCount++
                if ($batchCount -ge $BatchSize -or $batchCount -eq $users.Count) {
                    foreach ($u in $batch) {
                        try {
                            Write-PSFMessage -Level Verbose -Message "Processing user $($u.SamAccountName): Name='$($u.Name)'" -FunctionName "New-EnterpriseADUser"
                            $name = if ([string]::IsNullOrWhiteSpace($u.Name)) { "$($u.FirstName) $($u.LastName)" } else { $u.Name }
                            if ($PSCmdlet.ShouldProcess($u.SamAccountName, "Create AD user")) {
                                $securePassword = ConvertTo-SecureString $u.Password -AsPlainText -Force
                                New-ADUser -SamAccountName $u.SamAccountName `
                                           -Name $name `
                                           -GivenName $u.FirstName `
                                           -Surname $u.LastName `
                                           -Path $u.OU `
                                           -UserPrincipalName $u.UserPrincipalName `
                                           -Department $u.Department `
                                           -Title $u.Title `
                                           -EmailAddress $u.Email `
                                           -EmployeeID $u.EmployeeID `
                                           -OfficePhone $u.PhoneNumber `
                                           -Manager $u.Manager `
                                           -AccountPassword $securePassword `
                                           -Enabled ([bool]$u.AccountEnabled) `
                                           -OtherAttributes @{info=$u.Notes} `
                                           -ErrorAction Stop
                                Write-PSFMessage -Level Host -Message "Created user $($u.SamAccountName)" -FunctionName "New-EnterpriseADUser"
                                Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 1000 -Message "Created user $($u.SamAccountName)"
                                $results += [PSCustomObject]@{SamAccountName=$u.SamAccountName; Status="Success"}
                            }
                        }
                        catch {
                            Write-PSFMessage -Level Error -Message "Failed to create $($u.SamAccountName): $($_.Exception.Message)" -FunctionName "New-EnterpriseADUser"
                            Write-EventLog -LogName Application -Source $eventSource -EntryType Error -EventId 1001 -Message "Failed to create $($u.SamAccountName): $($_.Exception.Message)"
                            $results += [PSCustomObject]@{SamAccountName=$u.SamAccountName; Status="Failed"; Error=$_.Exception.Message}
                        }
                    }
                    $batch = @()
                    $batchCount = 0
                }
            }
        }
        else {
            try {
                if ($PSCmdlet.ShouldProcess($SamAccountName, "Create AD user")) {
                    $securePassword = $Password
                    $name = $SamAccountName
                    Write-PSFMessage -Level Verbose -Message "Processing user $SamAccountName: Name='$name'" -FunctionName "New-EnterpriseADUser"
                    New-ADUser -SamAccountName $SamAccountName `
                               -Name $name `
                               -GivenName $FirstName `
                               -Surname $LastName `
                               -Path $OU `
                               -UserPrincipalName $UserPrincipalName `
                               -Department $Department `
                               -Title $Title `
                               -EmailAddress $Email `
                               -EmployeeID $EmployeeID `
                               -OfficePhone $PhoneNumber `
                               -Manager $Manager `
                               -AccountPassword $securePassword `
                               -Enabled $true `
                               -OtherAttributes @{info=$Notes} `
                               -ErrorAction Stop
                    Write-PSFMessage -Level Host -Message "Created user $SamAccountName" -FunctionName "New-EnterpriseADUser"
                    Write-EventLog -LogName Application -Source $eventSource -EntryType Information -EventId 1000 -Message "Created user $SamAccountName"
                    $results += [PSCustomObject]@{SamAccountName=$SamAccountName; Status="Success"}
                }
            }
            catch {
                Write-PSFMessage -Level Error -Message "Failed to create $SamAccountName: $($_.Exception.Message)" -FunctionName "New-EnterpriseADUser"
                Write-EventLog -LogName Application -Source $eventSource -EntryType Error -EventId 1001 -Message "Failed to create $SamAccountName: $($_.Exception.Message)"
                $results += [PSCustomObject]@{SamAccountName=$SamAccountName; Status="Failed"; Error=$_.Exception.Message}
            }
        }
    }

    end {
        $results | Export-Csv -Path $logFile -NoTypeInformation
        Write-PSFMessage -Level Host -Message "User creation completed. Log saved to $logFile" -FunctionName "New-EnterpriseADUser"
        return $results
    }
}
