<#PSScriptInfo
.VERSION 1.0.0
.GUID a1b2c3d4-e5f6-7890-abcd-ef1234567890
.AUTHOR Chris Ulatowski
.COMPANYNAME Enterprise Automation
.COPYRIGHT (c) 2025 Chris Ulatowski. All rights reserved.
.DESCRIPTION Creates enterprise OU structure from CSV for banking environment with Country->City->Department hierarchy.
.TAGS ActiveDirectory, Automation, Banking, PowerShell, OU
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/chrisulatowski/Enterprise.Automation.AD
#>

function New-EnterpriseADOU {
    <#
    .SYNOPSIS
        Creates enterprise OU structure from CSV for banking environment.
    .DESCRIPTION
        Creates hierarchical OU structure from CSV: Enterprise -> Country -> City -> Department within Active Directory.
        Designed for banking environments with multiple international branches.
    .PARAMETER InputFile
        Path to CSV file for bulk creation (e.g., enterprise_ous.csv with Type,Name,ParentPath,Description).
    .PARAMETER EnterpriseRootName
        Name of the root enterprise OU (default: "Enterprise").
    .PARAMETER BaseDN
        Base Distinguished Name (e.g., "DC=itpositive,DC=com").
    .EXAMPLE
        New-EnterpriseADOU -InputFile "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_ous.csv" -EnterpriseRootName "Enterprise" -BaseDN "DC=itpositive,DC=com"
        Creates the entire enterprise OU structure from CSV.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile,

        [Parameter(Mandatory=$false)]
        [string]$EnterpriseRootName = "Enterprise",

        [Parameter(Mandatory=$true)]
        [string]$BaseDN
    )

    begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        Import-Module PSFramework -ErrorAction Stop

        # Create logs directory if it doesn't exist
        $logFolder = Join-Path $PSScriptRoot "../logs"
        if (-not (Test-Path $logFolder)) {
            New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
        }

        $logFile = Join-Path $logFolder "ADOU_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $eventSource = "EnterpriseADAutomation"

        if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
            New-EventLog -LogName Application -Source $eventSource -ErrorAction SilentlyContinue
        }

        Write-PSFMessage -Level Host -Message "Starting OU creation process" -FunctionName "New-EnterpriseADOU"
        $script:results = @()
    }

    process {
        try {
            # Create Enterprise root OU if it doesn't exist
            $enterpriseRootPath = "OU=$EnterpriseRootName,$BaseDN"
            if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$EnterpriseRootName'" -SearchBase $BaseDN -ErrorAction SilentlyContinue)) {
                if ($PSCmdlet.ShouldProcess($enterpriseRootPath, "Create Enterprise Root OU")) {
                    New-ADOrganizationalUnit -Name $EnterpriseRootName -Path $BaseDN -ProtectedFromAccidentalDeletion $false -Description "Enterprise Root Organization Unit"
                    Write-PSFMessage -Level Host -Message "Created Enterprise Root OU: $EnterpriseRootName" -FunctionName "New-EnterpriseADOU"
                    $script:results += [PSCustomObject]@{Type="Enterprise"; Name=$EnterpriseRootName; Path=$BaseDN; Status="Created"}
                }
            } else {
                Write-PSFMessage -Level Info -Message "Enterprise Root OU already exists: $EnterpriseRootName" -FunctionName "New-EnterpriseADOU"
                $script:results += [PSCustomObject]@{Type="Enterprise"; Name=$EnterpriseRootName; Path=$BaseDN; Status="Exists"}
            }

            # Import OU data from CSV
            $ous = Import-Csv -Path $InputFile

            # Process each OU from CSV
            foreach ($ou in $ous) {
                try {
                    # Clean up the data (trim whitespace)
                    foreach ($prop in $ou.PSObject.Properties) {
                        if ($prop.Value -and $prop.Value -is [string]) {
                            $ou.$($prop.Name) = $ou.$($prop.Name).Trim()
                        }
                    }

                    # Build the full OU path
                    $fullPath = "OU=$($ou.Name),$($ou.ParentPath)"

                    # Check if parent path exists
                    $parentExists = $true
                    try {
                        Get-ADObject -Identity $ou.ParentPath -ErrorAction Stop | Out-Null
                    } catch {
                        $parentExists = $false
                        Write-PSFMessage -Level Warning -Message "Parent path does not exist: $($ou.ParentPath). Skipping OU: $($ou.Name)" -FunctionName "New-EnterpriseADOU"
                        $script:results += [PSCustomObject]@{Type=$ou.Type; Name=$ou.Name; Path=$fullPath; Status="Skipped"; Error="Parent path does not exist"}
                    }

                    if ($parentExists) {
                        if ($PSCmdlet.ShouldProcess($fullPath, "Create $($ou.Type) OU")) {
                            # Check if OU already exists
                            if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($ou.Name)'" -SearchBase $ou.ParentPath -ErrorAction SilentlyContinue)) {
                                $ouParams = @{
                                    Name = $ou.Name
                                    Path = $ou.ParentPath
                                    ProtectedFromAccidentalDeletion = $false
                                    ErrorAction = 'Stop'
                                }

                                # Add description if provided
                                if (-not [string]::IsNullOrWhiteSpace($ou.Description)) {
                                    $ouParams.Description = $ou.Description
                                }

                                New-ADOrganizationalUnit @ouParams

                                Write-PSFMessage -Level Host -Message "Created $($ou.Type) OU: $($ou.Name) in $($ou.ParentPath)" -FunctionName "New-EnterpriseADOU"
                                $script:results += [PSCustomObject]@{Type=$ou.Type; Name=$ou.Name; Path=$fullPath; Status="Created"}
                            } else {
                                Write-PSFMessage -Level Info -Message "$($ou.Type) OU already exists: $($ou.Name) in $($ou.ParentPath)" -FunctionName "New-EnterpriseADOU"
                                $script:results += [PSCustomObject]@{Type=$ou.Type; Name=$ou.Name; Path=$fullPath; Status="Exists"}
                            }
                        }
                    }
                }
                catch {
                    Write-PSFMessage -Level Error -Message "Failed to create OU $($ou.Name): $($_.Exception.Message)" -FunctionName "New-EnterpriseADOU"
                    Write-EventLog -LogName Application -Source $eventSource -EntryType Error -EventId 2001 -Message "Failed to create OU $($ou.Name): $($_.Exception.Message)"
                    $script:results += [PSCustomObject]@{Type=$ou.Type; Name=$ou.Name; Path=$fullPath; Status="Failed"; Error=$_.Exception.Message}
                }
            }
        }
        catch {
            Write-PSFMessage -Level Error -Message "Failed to process OU creation: $($_.Exception.Message)" -FunctionName "New-EnterpriseADOU"
            Write-EventLog -LogName Application -Source $eventSource -EntryType Error -EventId 2000 -Message "Failed to process OU creation: $($_.Exception.Message)"
            $script:results += [PSCustomObject]@{Type="Error"; Name="OU Processing"; Path="N/A"; Status="Failed"; Error=$_.Exception.Message}
        }
    }

    end {
        $script:results | Export-Csv -Path $logFile -NoTypeInformation
        Write-PSFMessage -Level Host -Message "OU creation completed. Log saved to $logFile" -FunctionName "New-EnterpriseADOU"

        # Display summary
        $summary = $script:results | Group-Object Status | ForEach-Object {
            "$($_.Count) OUs $($_.Name)"
        }
        Write-PSFMessage -Level Host -Message "Summary: $($summary -join ', ')" -FunctionName "New-EnterpriseADOU"

        return $script:results
    }
}
