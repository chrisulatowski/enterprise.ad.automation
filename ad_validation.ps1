# 1. Verify script syntax for all functions
Write-Host "Testing script file syntax..." -ForegroundColor Cyan
Test-ScriptFileInfo .\functions\Public\New-EnterpriseADUser.ps1 -ErrorAction Stop
Test-ScriptFileInfo .\functions\Public\New-EnterpriseADOU.ps1 -ErrorAction Stop
Test-ScriptFileInfo .\functions\Public\New-EnterpriseADGroup.ps1 -ErrorAction Stop
Write-Host "✓ Script syntax validation passed" -ForegroundColor Green

# 2. Re-import module with verbose output
Write-Host "`nRe-importing module..." -ForegroundColor Cyan
Import-Module .\AD.psd1 -Verbose -Force

# 3. Verify module and functions are loaded
Write-Host "`nVerifying module and functions..." -ForegroundColor Cyan
$module = Get-Module Enterprise.Automation.AD
if ($module) {
    Write-Host "✓ Module loaded: $($module.Name) v$($module.Version)" -ForegroundColor Green
} else {
    Write-Host "✗ Module not loaded" -ForegroundColor Red
    exit 1
}

# Verify all functions
$userFunction = Get-Command New-EnterpriseADUser -ErrorAction SilentlyContinue
$ouFunction = Get-Command New-EnterpriseADOU -ErrorAction SilentlyContinue
$groupFunction = Get-Command New-EnterpriseADGroup -ErrorAction SilentlyContinue

$functions = @(
    @{Name = "New-EnterpriseADUser"; Command = $userFunction},
    @{Name = "New-EnterpriseADOU"; Command = $ouFunction},
    @{Name = "New-EnterpriseADGroup"; Command = $groupFunction}
)

foreach ($func in $functions) {
    if ($func.Command) {
        Write-Host "✓ Function loaded: $($func.Name)" -ForegroundColor Green
        Write-Host "  Parameters: $($func.Command.Parameters.Keys -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "✗ Function not found: $($func.Name)" -ForegroundColor Red
    }
}

# 4. Test User creation with -WhatIf
Write-Host "`nTesting User creation with -WhatIf..." -ForegroundColor Cyan
try {
    New-EnterpriseADUser -InputFile "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_users.csv" -BatchSize 10 -WhatIf
    Write-Host "✓ User creation -WhatIf test passed" -ForegroundColor Green
}
catch {
    Write-Host "✗ User creation -WhatIf test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 5. Test OU creation with -WhatIf (if CSV exists)
$ouCsvPath = "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_ous.csv"
if (Test-Path $ouCsvPath) {
    Write-Host "`nTesting OU creation with -WhatIf..." -ForegroundColor Cyan
    try {
        New-EnterpriseADOU -InputFile $ouCsvPath -EnterpriseRootName "Enterprise" -BaseDN "DC=itpositive,DC=com" -WhatIf
        Write-Host "✓ OU creation -WhatIf test passed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ OU creation -WhatIf test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`nOU CSV not found, skipping OU test: $ouCsvPath" -ForegroundColor Yellow
}

# 6. Test Group creation with -WhatIf (if CSV exists)
$groupCsvPath = "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_groups.csv"
if (Test-Path $groupCsvPath) {
    Write-Host "`nTesting Group creation with -WhatIf..." -ForegroundColor Cyan
    try {
        New-EnterpriseADGroup -InputFile $groupCsvPath -WhatIf
        Write-Host "✓ Group creation -WhatIf test passed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Group creation -WhatIf test failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`nGroup CSV not found, skipping Group test: $groupCsvPath" -ForegroundColor Yellow
}

# 7. If no errors, run User creation for real
Write-Host "`nRunning User creation for real..." -ForegroundColor Cyan
try {
    $userResults = New-EnterpriseADUser -InputFile "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_users.csv" -BatchSize 5
    Write-Host "✓ User creation completed successfully" -ForegroundColor Green

    # Show summary
    $userSummary = $userResults | Group-Object Status | ForEach-Object {
        "$($_.Count) users $($_.Name)"
    }
    Write-Host "User creation summary: $($userSummary -join ', ')" -ForegroundColor Cyan
}
catch {
    Write-Host "✗ User creation failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 8. Verify created users
Write-Host "`nVerifying created users..." -ForegroundColor Cyan
try {
    $users = Import-Csv "C:\scripts\Enterprise.AD.Automation\resources\data\enterprise_users.csv" | Select-Object -First 5
    $samAccounts = $users.SamAccountName -join "','"
    $createdUsers = Get-ADUser -Filter "SamAccountName -in ('$samAccounts')" -Properties Name, UserPrincipalName, Department, Title, Enabled

    if ($createdUsers) {
        Write-Host "✓ Successfully verified $($createdUsers.Count) users in AD:" -ForegroundColor Green
        $createdUsers | Format-Table SamAccountName, Name, UserPrincipalName, Enabled, Department -AutoSize
    } else {
        Write-Host "✗ No users found in AD" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ User verification failed: $($_.Exception.Message)" -ForegroundColor Red
}

# 9. Run OU creation for real (if CSV exists)
if (Test-Path $ouCsvPath) {
    Write-Host "`nRunning OU creation for real..." -ForegroundColor Cyan
    try {
        $ouResults = New-EnterpriseADOU -InputFile $ouCsvPath -EnterpriseRootName "Enterprise" -BaseDN "DC=itpositive,DC=com"
        Write-Host "✓ OU creation completed successfully" -ForegroundColor Green

        # Show summary
        $ouSummary = $ouResults | Group-Object Status | ForEach-Object {
            "$($_.Count) OUs $($_.Name)"
        }
        Write-Host "OU creation summary: $($ouSummary -join ', ')" -ForegroundColor Cyan

        # Verify OUs were created
        Write-Host "`nVerifying OUs were created..." -ForegroundColor Cyan
        $enterpriseOU = Get-ADOrganizationalUnit -Filter "Name -eq 'Enterprise'" -SearchBase "DC=itpositive,DC=com" -ErrorAction SilentlyContinue
        if ($enterpriseOU) {
            Write-Host "✓ Enterprise OU created successfully" -ForegroundColor Green
            Get-ADOrganizationalUnit -Filter * -SearchBase $enterpriseOU.DistinguishedName | Select-Object Name, DistinguishedName | Format-Table -AutoSize
        } else {
            Write-Host "✗ Enterprise OU not found" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ OU creation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 10. Run Group creation for real (if CSV exists)
if (Test-Path $groupCsvPath) {
    Write-Host "`nRunning Group creation for real..." -ForegroundColor Cyan
    try {
        $groupResults = New-EnterpriseADGroup -InputFile $groupCsvPath
        Write-Host "✓ Group creation completed successfully" -ForegroundColor Green

        # Show summary
        $groupSummary = $groupResults | Group-Object Status | ForEach-Object {
            "$($_.Count) groups $($_.Name)"
        }
        Write-Host "Group creation summary: $($groupSummary -join ', ')" -ForegroundColor Cyan

        # Verify Groups were created
        Write-Host "`nVerifying Groups were created..." -ForegroundColor Cyan
        $sampleGroups = Import-Csv $groupCsvPath | Select-Object -First 5
        $groupNames = $sampleGroups.SamAccountName -join "','"
        $createdGroups = Get-ADGroup -Filter "SamAccountName -in ('$groupNames')" -Properties Name, Description, GroupCategory, GroupScope

        if ($createdGroups) {
            Write-Host "✓ Successfully verified $($createdGroups.Count) groups in AD:" -ForegroundColor Green
            $createdGroups | Format-Table Name, SamAccountName, GroupCategory, GroupScope -AutoSize
        } else {
            Write-Host "✗ No groups found in AD" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "✗ Group creation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll verification steps completed!" -ForegroundColor Green
