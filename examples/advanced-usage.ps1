# Advanced Usage Example for AD DS Setup Script
# This example shows advanced configuration options and custom settings

# Advanced domain configuration
$DomainName = "corp.example.com"
$DCName = "MAIN-DC01"
$NumberOfUsers = 50

# More complex passwords (ensure they meet your security requirements)
$SafeModePassword = ConvertTo-SecureString "VeryComplexSafeModePassword2025!@#" -AsPlainText -Force
$UserPassword = ConvertTo-SecureString "ComplexUserPassword2025!" -AsPlainText -Force

# Pre-flight checks
Write-Host "=== Advanced AD DS Setup Configuration ===" -ForegroundColor Cyan
Write-Host "Domain Name: $DomainName" -ForegroundColor White
Write-Host "Domain Controller: $DCName" -ForegroundColor White
Write-Host "Test Users to Create: $NumberOfUsers" -ForegroundColor White
Write-Host "Current Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Current User: $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)" -ForegroundColor White
Write-Host ""

# Check if running as Administrator
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Verify Windows Server version
$osInfo = Get-WmiObject -Class Win32_OperatingSystem
Write-Host "Operating System: $($osInfo.Caption)" -ForegroundColor White
Write-Host "Version: $($osInfo.Version)" -ForegroundColor White
Write-Host ""

# Network configuration check
$networkAdapters = Get-NetAdapter | Where-Object Status -eq "Up"
Write-Host "Active Network Adapters:" -ForegroundColor Yellow
foreach ($adapter in $networkAdapters) {
    $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ipConfig) {
        Write-Host "  - $($adapter.Name): $($ipConfig.IPAddress)" -ForegroundColor White
    }
}
Write-Host ""

# Final confirmation with detailed information
Write-Host "WARNING: This will completely configure this server as a domain controller!" -ForegroundColor Red
Write-Host "The following changes will be made:" -ForegroundColor Yellow
Write-Host "  1. Install AD DS role and management tools" -ForegroundColor White
Write-Host "  2. Rename computer to: $DCName" -ForegroundColor White
Write-Host "  3. Create new AD forest: $DomainName" -ForegroundColor White
Write-Host "  4. Configure DNS services" -ForegroundColor White
Write-Host "  5. Create $NumberOfUsers test user accounts" -ForegroundColor White
Write-Host "  6. Multiple automatic reboots will occur" -ForegroundColor White
Write-Host ""

$confirmation = Read-Host "Type 'CONFIRM' to proceed with advanced setup"
if ($confirmation -eq 'CONFIRM') {
    Write-Host "Starting advanced AD DS setup..." -ForegroundColor Green
    Write-Host "Monitor the PowerShell windows that appear after each reboot." -ForegroundColor Cyan
    
    # Run the main setup script with advanced options
    .\Setup-ADDomain.ps1 -DomainName $DomainName `
                         -SafeModeAdministratorPassword $SafeModePassword `
                         -DefaultUserPassword $UserPassword `
                         -NumberOfUsers $NumberOfUsers `
                         -DCName $DCName
} else {
    Write-Host "Advanced setup cancelled. Type 'CONFIRM' exactly to proceed." -ForegroundColor Yellow
}
