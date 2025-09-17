Describe "New-EnterpriseADUser" {
    BeforeAll {
        Import-Module PSFramework -Force
        Import-Module ActiveDirectory -Force
        Mock Write-PSFMessage { }
        Mock Write-EventLog { }
        Mock Export-Csv { }
    }

    Context "Single User Creation" {
        It "Creates a user successfully" {
            Mock New-ADUser { return $null }
            $result = New-EnterpriseADUser -SamAccountName "test01" -GivenName "Test" -Surname "User" -OU "OU=Test,DC=bankcorp,DC=local" -Password "TempPass123!"
            $result.Status | Should -Be "Success"
            $result.SamAccountName | Should -Be "test01"
        }

        It "Handles invalid SamAccountName" {
            Mock New-ADUser { throw "Invalid SamAccountName" }
            $result = New-EnterpriseADUser -SamAccountName "test/01" -GivenName "Test" -Surname "User" -OU "OU=Test,DC=bankcorp,DC=local" -Password "TempPass123!"
            $result.Status | Should -Be "Failed"
            $result.Error | Should -Be "Invalid SamAccountName"
        }
    }

    Context "Bulk User Creation" {
        BeforeAll {
            $testCsv = @"
SamAccountName,GivenName,Surname,OU,Password
test02,Test2,User2,OU=Trading,OU=New York,DC=bankcorp,DC=local,TempPass123!
test03,Test3,User3,OU=Trading,OU=New York,DC=bankcorp,DC=local,TempPass123!
"@
            $testCsv | Out-File -FilePath "TestDrive:\test_users.csv" -Encoding UTF8
        }

        It "Processes CSV with batch size 2" {
            Mock New-ADUser { return $null }
            $result = New-EnterpriseADUser -InputFile "TestDrive:\test_users.csv" -BatchSize 2
            $result.Count | Should -Be 2
            $result[0].Status | Should -Be "Success"
            $result[0].SamAccountName | Should -Be "test02"
            Assert-MockCalled New-ADUser -Times 2 -Exactly
        }
    }
}
