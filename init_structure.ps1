<#
.SYNOPSIS
    Initializes the Enterprise.Automation repo with module skeletons.
.DESCRIPTION
    Creates folder structure, placeholder files, and module manifests for each automation domain.
.NOTES
    Author: Chris Ulatowski
    Date: 2024-04-17
#>

# -----------------------------
# Config
# -----------------------------
$Root = "Enterprise.Automation"

$Modules = @(
    "AD",
    "Entra",
    "GPO",
    "Troubleshooting",
    "Provisioning",
    "Audit",
    "Security",
    "Monitoring",
    "Logs",
    "Recon",
    "Hardening",
    "Pentesting",
    "Infrastructure",
    "Common",
    "CI_CD"
)

# -----------------------------
# Helper: Create Module Skeleton
# -----------------------------
function New-ModuleSkeleton {
    param([string]$ModuleName)

    Write-Host "[*] Creating module: $ModuleName"

    $ModulePath = Join-Path $Root $ModuleName

    # Core directories
    $dirs = @(
        "module/functions/Public",
        "module/functions/Private",
        "module/classes",
        "module/types",
        "module/resources/templates",
        "tests",
        "examples",
        "resources",
        "docs"
    )

    foreach ($dir in $dirs) {
        $fullPath = Join-Path $ModulePath $dir
        if (-not (Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        }
    }

    # Placeholder files
    $psm1 = Join-Path $ModulePath "module/$ModuleName.psm1"
    $psd1 = Join-Path $ModulePath "module/$ModuleName.psd1"
    $readme = Join-Path $ModulePath "README.md"
    $license = Join-Path $ModulePath "LICENSE"

    # .psm1 file
    if (-not (Test-Path $psm1)) { New-Item -ItemType File -Path $psm1 | Out-Null }

    # .psd1 manifest
    if (-not (Test-Path $psd1)) {
        $guid = [guid]::NewGuid()
        @"
@{
    RootModule = '$ModuleName.psm1'
    ModuleVersion = '0.1.0'
    GUID = '$guid'
    Author = 'Your Name'
    CompanyName = 'BankCorp'
    Description = '$ModuleName automation module'
    PowerShellVersion = '5.1'
    FunctionsToExport = @()
    CmdletsToExport   = @()
    AliasesToExport   = @()
}
"@ | Out-File -FilePath $psd1 -Encoding UTF8
    }

    # README.md
    if (-not (Test-Path $readme)) {
        @"
# $ModuleName Module

Placeholder README for $ModuleName automation.

"@ | Out-File -FilePath $readme -Encoding UTF8
    }

    # LICENSE
    if (-not (Test-Path $license)) {
        "MIT License" | Out-File -FilePath $license -Encoding UTF8
    }
}

# -----------------------------
# Main
# -----------------------------
Write-Host "[*] Initializing $Root project structure..."
# Create root directories
$rootDirs = @(
    "resources/data",
    "resources/scripts",
    "docs"
)
foreach ($d in $rootDirs) {
    $fullPath = Join-Path $Root $d
    if (-not (Test-Path $fullPath)) { New-Item -ItemType Directory -Path $fullPath -Force | Out-Null }
}

# Global placeholders
$readmeRoot = Join-Path $Root "README.md"
$licenseRoot = Join-Path $Root "LICENSE"
$gitignoreRoot = Join-Path $Root ".gitignore"

if (-not (Test-Path $readmeRoot)) { "# Enterprise.Automation`n" | Out-File -FilePath $readmeRoot -Encoding UTF8 }
if (-not (Test-Path $licenseRoot)) { "MIT License" | Out-File -FilePath $licenseRoot -Encoding UTF8 }

# Add basic .gitignore
if (-not (Test-Path $gitignoreRoot)) {
    @"
# Global ignores
.DS_Store
Thumbs.db
*.swp
*.tmp
*.bak
*.log
.vscode/
.idea/

# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
*.egg-info/
.venv/
venv/
.env

# PowerShell
*.pssproj
*.pssc
*.ps1xml
*.cdxml
*.cache
*.psm1.psd1.test

# Terraform
.terraform/
terraform.tfstate*
*.tfvars

# Ansible
*.retry

# Logs & temp
logs/
*.log
*.out
*.err

# Security-sensitive
*.pem
*.crt
*.key
*.pfx
secrets.json
secrets.yaml

# Generated data
resources/data/*.csv
!resources/data/README.md

# CI/CD artifacts
coverage/
dist/
build/
*.zip
*.tar.gz
*.tgz
"@ | Out-File -FilePath $gitignoreRoot -Encoding UTF8
}

# Create all modules
foreach ($mod in $Modules) {
    New-ModuleSkeleton -ModuleName $mod
}

# Example CSV placeholders
$csvFiles = @(
    "resources/data/bankcorp_users.csv",
    "resources/data/bankcorp_managers.csv",
    "resources/data/bankcorp_executives.csv"
)
foreach ($csv in $csvFiles) {
    $path = Join-Path $Root $csv
    if (-not (Test-Path $path)) { New-Item -ItemType File -Path $path | Out-Null }
}

Write-Host "[+] Project scaffold complete at: $Root/"
