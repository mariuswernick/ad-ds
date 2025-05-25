# Basic Usage Example for AD DS Setup Script
# This example demonstrates how to use the Setup-ADDomain.ps1 script with basic configuration

# Set execution policy if needed (run as Administrator)
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Define your domain configuration
$DomainName = "company.local"
$DCName = "HQ-DC01"
$NumberOfUsers = 15

# Create secure password objects
# Replace these with your actual passwords
$SafeModePassword = ConvertTo-SecureString "YourComplexSafeModePassword123!" -AsPlainText -Force
$UserPassword = ConvertTo-SecureString "TestUser123!" -AsPlainText -Force

# Display configuration before running
Write-Host "=== AD DS Setup Configuration ===" -ForegroundColor Cyan
Write-Host "Domain Name: $DomainName" -ForegroundColor White
Write-Host "DC Name: $DCName" -ForegroundColor White
Write-Host "Test Users: $NumberOfUsers" -ForegroundColor White
Write-Host "" 

# Confirm before proceeding
$confirmation = Read-Host "Do you want to proceed with AD DS setup? (y/N)"
if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
    Write-Host "Starting AD DS automated setup..." -ForegroundColor Green
    
    # Run the main setup script
    .\Setup-ADDomain.ps1 -DomainName $DomainName `
                         -SafeModeAdministratorPassword $SafeModePassword `
                         -DefaultUserPassword $UserPassword `
                         -NumberOfUsers $NumberOfUsers `
                         -DCName $DCName
} else {
    Write-Host "Setup cancelled by user." -ForegroundColor Yellow
}
