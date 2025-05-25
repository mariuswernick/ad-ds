param(
    [Parameter(Mandatory=$false)]
    [string]$DomainName = "contoso.local",
    
    [Parameter(Mandatory=$false)]
    [SecureString]$SafeModeAdministratorPassword,
    
    [Parameter(Mandatory=$false)]
    [int]$NumberOfUsers = 10,

    [Parameter(Mandatory=$false)]
    [SecureString]$DefaultUserPassword,

    [Parameter(Mandatory=$false)]
    [string]$DCName = "HQ-DC01",

    [Parameter(Mandatory=$false)]
    [switch]$InstallADDS,

    [Parameter(Mandatory=$false)]
    [switch]$ProvisionDomain,

    [Parameter(Mandatory=$false)]
    [switch]$CreateUsers
)

$DomainPrefix = $DomainName.Split('.')[0]
$NetBiosName = $DomainPrefix.ToUpper()
$NewHostName = $DCName

$logPath = "C:\Windows\Temp\ADSetup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logPath -Force

function Test-Administrator {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Save-SetupParameters {
    param([string]$Phase)
    
    $passwordFile = "C:\Windows\Temp\ad_setup_data.xml"
    $setupData = @{
        DomainName = $DomainName
        NetBiosName = $NetBiosName  
        NewHostName = $NewHostName
        DCName = $DCName
        NumberOfUsers = $NumberOfUsers
        SafeModePassword = if ($SafeModeAdministratorPassword) { $SafeModeAdministratorPassword | ConvertFrom-SecureString } else { $null }
        DefaultUserPassword = if ($DefaultUserPassword) { $DefaultUserPassword | ConvertFrom-SecureString } else { $null }
        CurrentPhase = $Phase
        LogPath = $logPath
        ScriptPath = $PSCommandPath
    }
    $setupData | Export-Clixml -Path $passwordFile
    Write-Host "Setup parameters saved for phase: $Phase" -ForegroundColor Yellow
}

function Load-SetupParameters {
    $passwordFile = "C:\Windows\Temp\ad_setup_data.xml"
    if (Test-Path $passwordFile) {
        $data = Import-Clixml -Path $passwordFile
        $script:DomainName = $data.DomainName
        $script:NetBiosName = $data.NetBiosName
        $script:NewHostName = $data.NewHostName
        $script:DCName = if ($data.DCName) { $data.DCName } else { "HQ-DC01" }
        $script:NumberOfUsers = $data.NumberOfUsers
        if ($data.SafeModePassword) {
            $script:SafeModeAdministratorPassword = $data.SafeModePassword | ConvertTo-SecureString
        }
        if ($data.DefaultUserPassword) {
            $script:DefaultUserPassword = $data.DefaultUserPassword | ConvertTo-SecureString
        }
        Write-Host "Loaded parameters from previous phase: $($data.CurrentPhase)" -ForegroundColor Green
        return $data
    }
    return $null
}

function Set-RunOnceRegistry {
    param(
        [string]$KeyName,
        [string]$ScriptContent,
        [string]$Description
    )
    
    $scriptPath = "C:\Windows\Temp\$KeyName.ps1"
    $ScriptContent | Out-File -FilePath $scriptPath -Force -Encoding UTF8
    
    $runOncePath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    $command = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Normal -File `"$scriptPath`""
    
    Set-ItemProperty -Path $runOncePath -Name $KeyName -Value $command -Force
    Write-Host "Created RunOnce registry entry: $KeyName" -ForegroundColor Green
    Write-Host "Description: $Description" -ForegroundColor Cyan
}

function Remove-RunRegistry {
    param([string]$KeyName)
    
    $runPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    $runOncePath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
    
    Remove-ItemProperty -Path $runPath -Name $KeyName -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $runOncePath -Name $KeyName -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\$KeyName.ps1" -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned up registry entry: $KeyName" -ForegroundColor Yellow
}

if (-not (Test-Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

Write-Host "=== Active Directory Domain Setup Script ===" -ForegroundColor Cyan
Write-Host "Target Domain: $DomainName" -ForegroundColor White
Write-Host "Domain Controller Name: $NewHostName" -ForegroundColor White
Write-Host "NetBIOS Name: $NetBiosName" -ForegroundColor White
Write-Host ""
Write-Host "Current User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor White
Write-Host "Computer Name: $env:COMPUTERNAME" -ForegroundColor White
Write-Host ""

if ($CreateUsers) {
    Write-Host "=== PHASE 3: Creating Users ===" -ForegroundColor Cyan
    $savedData = Load-SetupParameters
    
    Remove-RunRegistry -KeyName "ADSetup_CreateUsers"
    
    # Load user password from saved data if not provided
    if (-not $DefaultUserPassword -and $savedData -and $savedData.DefaultUserPassword) {
        $script:DefaultUserPassword = $savedData.DefaultUserPassword | ConvertTo-SecureString
        Write-Host "Using saved user password from previous phase" -ForegroundColor Green
    }
    
    if ($DefaultUserPassword) {
        Write-Host "Waiting for Active Directory services..." -ForegroundColor Yellow
        $maxAttempts = 12
        $attempt = 0
        do {
            $attempt++
            Start-Sleep -Seconds 30
            $adReady = $false
            if (Get-Module -ListAvailable -Name ActiveDirectory) {
                Import-Module ActiveDirectory -ErrorAction SilentlyContinue
                if (Get-Command Get-ADDomain -ErrorAction SilentlyContinue) {
                    $domain = Get-ADDomain -ErrorAction SilentlyContinue
                    if ($domain) {
                        $adReady = $true
                        Write-Host "Active Directory services are ready!" -ForegroundColor Green
                    }
                }
            }
            if (-not $adReady) {
                Write-Host "Attempt $attempt/$maxAttempts - waiting..." -ForegroundColor Yellow
            }
        } while (-not $adReady -and $attempt -lt $maxAttempts)

        if ($adReady) {
            Write-Host "Creating Organizational Units..." -ForegroundColor Green
            $domainDN = "DC=$($DomainName -replace '\.', ',DC=')"
            $departments = @('IT','HR','Finance','Marketing','Sales','Operations')
            
            New-ADOrganizationalUnit -Name "Company" -Path $domainDN -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
            foreach ($dept in $departments) {
                New-ADOrganizationalUnit -Name $dept -Path "OU=Company,$domainDN" -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
            }

            Write-Host "Creating $NumberOfUsers users..." -ForegroundColor Green
            $firstNames = @('John','Jane','Michael','Sarah','David','Lisa','Robert','Emma','William','Olivia','James','Sophia','Daniel','Ava','Matthew','Isabella')
            $lastNames = @('Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Taylor','Thomas','Moore','Jackson','Martin','Thompson')
            
            $createdCount = 0
            for ($i = 1; $i -le $NumberOfUsers; $i++) {
                $firstName = $firstNames | Get-Random
                $lastName = $lastNames | Get-Random
                $department = $departments | Get-Random
                $username = "$($firstName.ToLower()).$($lastName.ToLower())$(Get-Random -Minimum 100 -Maximum 999)"
                $email = "$username@$DomainName"
                $ouPath = "OU=$department,OU=Company,$domainDN"
                
                $newUser = New-ADUser -Name "$firstName $lastName" -GivenName $firstName -Surname $lastName -UserPrincipalName $email -SamAccountName $username -EmailAddress $email -Path $ouPath -Department $department -Company $NetBiosName -AccountPassword $DefaultUserPassword -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires $true -ErrorAction SilentlyContinue -PassThru
                if ($newUser) {
                    Write-Host "Created user: $username in $department" -ForegroundColor Green
                    $createdCount++
                } else {
                    Write-Warning "Failed to create user $username"
                }
            }

            Write-Host ""
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host "    ACTIVE DIRECTORY SETUP COMPLETED!" -ForegroundColor Green
            Write-Host "=========================================================" -ForegroundColor Green
            Write-Host "Domain: $DomainName" -ForegroundColor White
            Write-Host "Domain Controller: $NewHostName" -ForegroundColor White
            Write-Host "NetBIOS Name: $NetBiosName" -ForegroundColor White
            Write-Host "Users Created: $createdCount" -ForegroundColor White
            Write-Host "DNS Server: Configured" -ForegroundColor White
            Write-Host ""
            Write-Host "You can now join computers to the domain!" -ForegroundColor Cyan
            Write-Host "Domain Admin: $NetBiosName\Administrator" -ForegroundColor Cyan
        }
    } else {
        Write-Host "No user password available. Skipping user creation." -ForegroundColor Yellow
        Write-Host "To create users manually later, run:" -ForegroundColor Cyan
        Write-Host ".\Setup-ADDomain.ps1 -CreateUsers -DefaultUserPassword `$yourPassword" -ForegroundColor White
    }
    
    Remove-Item "C:\Windows\Temp\ad_setup_data.xml" -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\ADSetup_*.ps1" -Force -ErrorAction SilentlyContinue
    
    Write-Host ""
    Write-Host "Setup Complete! Press any key to close..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

} elseif ($ProvisionDomain) {
    Write-Host "=== PHASE 2: Provisioning Domain ===" -ForegroundColor Cyan
    $savedData = Load-SetupParameters
    
    Remove-RunRegistry -KeyName "ADSetup_ProvisionDomain"
    
    # Load SafeModePassword from saved data if not provided
    if (-not $SafeModeAdministratorPassword -and $savedData -and $savedData.SafeModePassword) {
        $script:SafeModeAdministratorPassword = $savedData.SafeModePassword | ConvertTo-SecureString
        Write-Host "Using saved SafeMode password from previous phase" -ForegroundColor Green
    }
    
    if (-not $SafeModeAdministratorPassword) {
        Write-Error "SafeModeAdministratorPassword is required for domain provisioning but not found in saved data"
        exit 1
    }
    
    Write-Host "Installing Active Directory forest: $DomainName" -ForegroundColor Green
    Write-Host "This will take several minutes and reboot automatically." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "IMPORTANT: After reboot, log in as: $NetBiosName\Administrator" -ForegroundColor Cyan
    Write-Host "A PowerShell window will appear automatically to create users." -ForegroundColor Cyan
    Write-Host ""
    
    # Only create user creation task if we have a user password
    if ($savedData -and $savedData.DefaultUserPassword) {
        $userCreationScript = @'
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   AD Setup - Final Phase: Creating Users" -ForegroundColor White
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Domain promotion completed successfully!" -ForegroundColor Green
Write-Host "Please make sure you are logged in as domain administrator." -ForegroundColor Yellow
Write-Host "Starting user creation in 10 seconds..." -ForegroundColor Yellow
Write-Host ""

for ($i = 10; $i -gt 0; $i--) {
    Write-Host "Starting in $i seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

$dataFile = "C:\Windows\Temp\ad_setup_data.xml"
if (Test-Path $dataFile) {
    $data = Import-Clixml -Path $dataFile
    $scriptPath = $data.ScriptPath
    if (Test-Path $scriptPath) {
        Write-Host "Continuing with user creation..." -ForegroundColor Green
        & $scriptPath -CreateUsers
    } else {
        Write-Host "Original script not found. Please run user creation manually." -ForegroundColor Red
        Write-Host "Press any key to close..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
} else {
    Write-Host "Setup data not found. Please run user creation manually." -ForegroundColor Red
    Write-Host "Press any key to close..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
'@
        Set-RunOnceRegistry -KeyName "ADSetup_CreateUsers" -ScriptContent $userCreationScript -Description "Complete AD setup by creating users"
        Write-Host "Registry entry created for user creation phase." -ForegroundColor Green
    } else {
        Write-Host "No user password provided - skipping user creation phase." -ForegroundColor Yellow
    }
    
    Write-Host "Starting domain controller promotion..." -ForegroundColor Cyan
    Write-Host ""
    
    Start-Sleep -Seconds 5
    Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $SafeModeAdministratorPassword -DomainNetbiosName $NetBiosName -InstallDns -Force -NoRebootOnCompletion:$false

} else {
    Write-Host "=== PHASE 1: Computer Preparation and AD DS Installation ===" -ForegroundColor Cyan
    
    # Validate SafeModePassword for initial setup
    if (-not $SafeModeAdministratorPassword) {
        Write-Error "SafeModeAdministratorPassword is required for initial setup"
        exit 1
    }
    
    $currentHostName = $env:COMPUTERNAME
    
    Write-Host "Installing AD DS role and management tools..." -ForegroundColor Green
    Write-Host "This may take a few minutes..." -ForegroundColor Yellow
    $result = Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
    
    if (-not $result.Success) {
        Write-Error "Failed to install AD DS role: $($result.ExitCode)"
        exit 1
    }
    
    Write-Host "AD DS role installed successfully" -ForegroundColor Green
    Write-Host ""
    
    if ($currentHostName -ne $NewHostName) {
        Write-Host "Current computer name: $currentHostName" -ForegroundColor White
        Write-Host "Target computer name: $NewHostName" -ForegroundColor White
        Write-Host "Renaming computer..." -ForegroundColor Green
        
        Save-SetupParameters -Phase "ADDSInstalled_ComputerRenamed"
        
        $domainProvisionScript = @'
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "   AD Setup - Phase 2: Domain Provisioning" -ForegroundColor White
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Computer rename completed successfully!" -ForegroundColor Green
Write-Host "Current computer name: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Starting domain provisioning in 10 seconds..." -ForegroundColor Yellow
Write-Host ""

for ($i = 10; $i -gt 0; $i--) {
    Write-Host "Starting in $i seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
}

$dataFile = "C:\Windows\Temp\ad_setup_data.xml"
if (Test-Path $dataFile) {
    $data = Import-Clixml -Path $dataFile
    $scriptPath = $data.ScriptPath
    if (Test-Path $scriptPath) {
        Write-Host "Continuing with domain provisioning..." -ForegroundColor Green
        & $scriptPath -ProvisionDomain
    } else {
        Write-Host "Original script not found!" -ForegroundColor Red
        Write-Host "Press any key to close..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
} else {
    Write-Host "Setup data not found!" -ForegroundColor Red
    Write-Host "Press any key to close..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
'@
        Set-RunOnceRegistry -KeyName "ADSetup_ProvisionDomain" -ScriptContent $domainProvisionScript -Description "Continue AD setup after computer rename"
        
        Rename-Computer -NewName $NewHostName -Force
        Write-Host "Computer renamed successfully" -ForegroundColor Green
        Write-Host ""
        Write-Host "Registry entry created for next phase." -ForegroundColor Green
        Write-Host "After restart, a PowerShell window will appear automatically." -ForegroundColor Yellow
        Write-Host ""
        
        for ($i = 15; $i -gt 0; $i--) {
            Write-Host "Restarting in $i seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        
        Restart-Computer -Force
    } else {
        Write-Host "Computer name is already correct: $NewHostName" -ForegroundColor Green
        Write-Host "Proceeding directly to domain provisioning..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
        & $PSCommandPath -ProvisionDomain
    }
}

Stop-Transcript