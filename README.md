# enterprise.ad.automation

[![Python Version](https://img.shields.io/badge/python-3.8%2B-blue.svg)](https://www.python.org/downloads/)
![PowerShell](https://img.shields.io/badge/powershell-5.1%2B-5391FE.svg?logo=powershell)
![Shell](https://img.shields.io/badge/shell-bash-black.svg?logo=gnu-bash)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![CI](https://github.com/chrisulatowski/enterprise.ad.automation/actions/workflows/ci.yml/badge.svg)](https://github.com/chrisulatowski/enterprise.ad.automation/actions/workflows/ci.yml)

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

Active Directory automation framework for banking environments, managing users, groups, and OUs for 50,000+ accounts across 100 global locations. Supports secure bulk operations, compliance reporting (FCA, PCI DSS), and Azure Sentinel integration using PowerShell, Python, and Bash.

## Overview
This repository provides a modular automation framework for enterprise-scale Active Directory management, tailored for regulated FinTech and banking sectors. It includes scripts for user provisioning, OU management, group operations, auditing, and compliance, with a focus on scalability and security.

## Repository Structure
- **AD**: Active Directory module with PowerShell scripts (e.g., `New-EnterpriseADUser.ps1`) for user, group, and OU management.
- **Audit**: Scripts for auditing AD configurations and compliance (e.g., user access reports).
- **CI_CD**: CI/CD pipelines for automated testing and deployment.
- **Common**: Shared utilities and helper functions for cross-module use.
- **docs**: Documentation for modules and workflows.
- **Entra**: Scripts for Microsoft Entra ID (Azure AD) integration and management.
- **GPO**: Group Policy Object management scripts for policy automation.
- **Hardening**: Security hardening scripts for Windows environments.
- **Infrastructure**: Infrastructure-as-code scripts (e.g., Terraform) for environment setup.
- **Logs**: Centralized logging for audit trails (Azure Sentinel-compatible).
- **Monitoring**: Monitoring scripts for AD health and performance.
- **Pentesting**: Security testing scripts for vulnerability assessments.
- **Provisioning**: Automated provisioning scripts for users and resources.
- **Recon**: Reconnaissance scripts for environment discovery.
- **resources**: Supporting files (e.g., CSVs, templates) for automation scripts.
- **Security**: Security-focused scripts for access control and compliance.
- **Troubleshooting**: Diagnostic scripts for resolving AD issues.

## Setup
    # Clone the repository
    git clone https://github.com/chrisulatowski/enterprise.ad.automation.git

    # Install dependencies
    Install-Module ActiveDirectory, PSFramework

    # Import the AD module
    Import-Module ./AD/module/AD.psd1

    # Run example (create 10 users from CSV)
    New-EnterpriseADUser -InputFile "./resources/data/enterprise_users.csv" -BatchSize 10

## License
This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
