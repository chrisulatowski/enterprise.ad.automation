<#PSScriptInfo
.VERSION 1.0.0
.GUID a1b2c3d4-e5f6-7890-abcd-ef1234567890
.AUTHOR Chris Ulatowski
.COMPANYNAME Enterprise Automation
.COPYRIGHT (c) 2025 Chris Ulatowski. All rights reserved.
.DESCRIPTION Creates enterprise security groups from CSV for banking environment.
.TAGS ActiveDirectory, Automation, Banking, PowerShell, Group
.LICENSEURI https://opensource.org/licenses/MIT
.PROJECTURI https://github.com/chrisulatowski/Enterprise.Automation.AD
#>

function New-EnterpriseADGroup {
    <#
    .SYNOPSIS
        Creates enterprise security groups from CSV for banking environment.
    .DESCRIPTION
        Creates security groups for each city-department combination based on enterprise_ous.csv structure.
        Groups follow naming convention: city-department (e.g., toronto-businessbanking).
    .PARAMETER InputFile
        Path to CSV file for bulk creation (e.g., enterprise_groups.csv with Name,SamAccountName,GroupCategory,GroupScope,Description,OU,Email).
    .EXAMPLE
        New-EnterpriseADGroup -InputFile "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_groups.csv"
        Creates security groups for all city-department combinations.
    #>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$InputFile
    )

    begin {
        Import-Module ActiveDirectory -ErrorAction Stop
        Import-Module PSFramework -ErrorAction Stop

        # Create logs directory if it doesn't exist
        $logFolder = Join-Path $PSScriptRoot "../logs"
        if (-not (Test-Path $logFolder)) {
            New-Item -ItemType Directory -Path $logFolder -Force | Out-Null
        }

        $logFile = Join-Path $logFolder "ADGroup_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $eventSource = "EnterpriseADAutomation"

        if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
            New-EventLog -LogName Application -Source $eventSource -ErrorAction SilentlyContinue
        }

        Write-PSFMessage -Level Host -Message "Starting group creation process" -FunctionName "New-EnterpriseADGroup"
        $script:results = @()
    }

    process {
        try {
            # Import group data from CSV
            $groups = Import-Csv -Path $InputFile

            foreach ($group in $groups) {
                try {
                    # Clean up the data (trim whitespace)
                    foreach ($prop in $group.PSObject.Properties) {
                        if ($prop.Value -and $prop.Value -is [string]) {
                            $group.$($prop.Name) = $group.$($prop.Name).Trim()
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($group.SamAccountName, "Create AD group")) {
                        # Check if group already exists
                        if (-not (Get-ADGroup -Filter "SamAccountName -eq '$($group.SamAccountName)'" -ErrorAction SilentlyContinue)) {
                            $groupParams = @{
                                Name = $group.Name
                                SamAccountName = $group.SamAccountName
                                GroupCategory = $group.GroupCategory
                                GroupScope = $group.GroupScope
                                Path = $group.OU
                                ErrorAction = 'Stop'
                            }

                            # Add optional parameters if provided
                            if (-not [string]::IsNullOrWhiteSpace($group.Description)) {
                                $groupParams.Description = $group.Description
                            }

                            if (-not [string]::IsNullOrWhiteSpace($group.Email)) {
                                $groupParams.OtherAttributes = @{mail=$group.Email}
                            }

                            New-ADGroup @groupParams

                            Write-PSFMessage -Level Host -Message "Created group: $($group.SamAccountName)" -FunctionName "New-EnterpriseADGroup"
                            $script:results += [PSCustomObject]@{SamAccountName=$group.SamAccountName; Name=$group.Name; Status="Created"}
                        } else {
                            Write-PSFMessage -Level Host -Message "Group already exists: $($group.SamAccountName)" -FunctionName "New-EnterpriseADGroup"
                            $script:results += [PSCustomObject]@{SamAccountName=$group.SamAccountName; Name=$group.Name; Status="Exists"}
                        }
                    }
                }
                catch {
                    Write-PSFMessage -Level Error -Message "Failed to create group $($group.SamAccountName): $($_.Exception.Message)" -FunctionName "New-EnterpriseADGroup"
                    Write-EventLog -LogName Application -Source $eventSource -EntryType Error -EventId 3001 -Message "Failed to create group $($group.SamAccountName): $($_.Exception.Message)"
                    $script:results += [PSCustomObject]@{SamAccountName=$group.SamAccountName; Name=$group.Name; Status="Failed"; Error=$_.Exception.Message}
                }
            }
        }
        catch {
            Write-PSFMessage -Level Error -Message "Failed to process group creation: $($_.Exception.Message)" -FunctionName "New-EnterpriseADGroup"
            Write-EventLog -LogName Application -Source $eventSource -EntryType Error -EventId 3000 -Message "Failed to process group creation: $($_.Exception.Message)"
            $script:results += [PSCustomObject]@{SamAccountName="N/A"; Name="Group Processing"; Status="Failed"; Error=$_.Exception.Message}
        }
    }

    end {
        $script:results | Export-Csv -Path $logFile -NoTypeInformation
        Write-PSFMessage -Level Host -Message "Group creation completed. Log saved to $logFile" -FunctionName "New-EnterpriseADGroup"

        # Display summary
        $summary = $script:results | Group-Object Status | ForEach-Object {
            "$($_.Count) groups $($_.Name)"
        }
        Write-PSFMessage -Level Host -Message "Summary: $($summary -join ', ')" -FunctionName "New-EnterpriseADGroup"

        return $script:results
    }
}
