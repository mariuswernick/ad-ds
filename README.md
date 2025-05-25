# Active Directory Domain Services Automation Script

A comprehensive PowerShell script for automated deployment of Active Directory Domain Services (AD DS) on Windows Server environments. This script provides a complete, hands-off approach to setting up a domain controller with minimal manual intervention.

## 🎯 Purpose

This script automates the entire Active Directory deployment process, eliminating the need for manual intervention across multiple reboots and configuration phases. It's designed for system administrators, IT professionals, and organizations who need to deploy AD DS environments quickly and consistently.

### What It Does

- **Automated Computer Renaming**: Renames the server to your specified domain controller name (default: HQ-DC01)
- **AD DS Role Installation**: Installs Active Directory Domain Services role and management tools
- **Domain Controller Promotion**: Creates a new Active Directory forest and promotes the server to domain controller
- **User Account Creation**: Automatically creates organizational units and user accounts for testing
- **Multi-Phase Automation**: Uses Windows Registry RunOnce entries to handle reboots seamlessly

## ✨ Key Features

- **Zero-Touch Deployment**: Run once, then the script handles everything automatically
- **Registry-Based Automation**: Uses Windows RunOnce registry entries (more reliable than scheduled tasks)
- **Visible Progress**: PowerShell windows remain visible throughout all phases for transparency
- **Customizable Configuration**: Flexible parameters for domain names, DC names, and user counts
- **Enterprise Ready**: Suitable for lab environments, testing, and proof-of-concept deployments
- **Error Handling**: Comprehensive error checking and logging throughout the process

## 🚀 Quick Start

### Prerequisites

- Windows Server (2016, 2019, 2022)
- Administrator privileges
- PowerShell execution policy set to allow script execution

### Basic Usage

```powershell
# Set up the required passwords
$safePassword = ConvertTo-SecureString "YourComplexPassword123!" -AsPlainText -Force
$userPassword = ConvertTo-SecureString "TestUser123!" -AsPlainText -Force

# Run the script with basic configuration
.\Setup-ADDomain.ps1 -DomainName "company.local" -SafeModeAdministratorPassword $safePassword -DefaultUserPassword $userPassword -NumberOfUsers 15
```

### Advanced Usage

```powershell
# Custom domain controller name and configuration
.\Setup-ADDomain.ps1 -DomainName "corp.example.com" -SafeModeAdministratorPassword $safePassword -DefaultUserPassword $userPassword -NumberOfUsers 25 -DCName "MAIN-DC01"
```

## 📋 Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `DomainName` | String | No | "contoso.local" | The fully qualified domain name for the new domain |
| `SafeModeAdministratorPassword` | SecureString | Yes* | - | Password for Directory Services Restore Mode |
| `DefaultUserPassword` | SecureString | No | - | Password for automatically created test users |
| `NumberOfUsers` | Integer | No | 10 | Number of test users to create |
| `DCName` | String | No | "HQ-DC01" | Name for the domain controller computer |

*Required only for initial setup

## 🔄 Process Flow

The script operates in three distinct phases:

### Phase 1: Computer Preparation
- Installs Active Directory Domain Services role
- Renames computer to specified DC name
- Creates registry entry for Phase 2
- Automatically reboots

### Phase 2: Domain Provisioning
- Promotes server to domain controller
- Creates new Active Directory forest
- Installs and configures DNS services
- Creates registry entry for Phase 3
- Automatically reboots

### Phase 3: User Creation
- Waits for Active Directory services to be ready
- Creates organizational structure (Company OU with department sub-OUs)
- Generates specified number of test users with random names
- Distributes users across different departments
- Completes setup and cleans up temporary files

## 📁 What Gets Created

### Organizational Structure
```
Domain Root
└── Company OU
    ├── IT OU
    ├── HR OU
    ├── Finance OU
    ├── Marketing OU
    ├── Sales OU
    └── Operations OU
```

### User Accounts
- Random first and last names from predefined lists
- Unique usernames (firstname.lastname + random number)
- Email addresses based on domain name
- Distributed across different department OUs
- Enabled accounts with non-expiring passwords

## 🛡️ Security Considerations

- **DSRM Password**: The SafeModeAdministratorPassword is used for Directory Services Restore Mode
- **User Passwords**: Test user accounts use the same password for simplicity
- **Registry Storage**: Passwords are temporarily stored in encrypted format in the registry
- **Cleanup**: All temporary files and registry entries are cleaned up after completion

## 📝 Logging

The script creates detailed logs at `C:\Windows\Temp\ADSetup_[timestamp].log` for troubleshooting and audit purposes.

## ⚠️ Important Notes

- **Production Use**: This script is designed for lab and testing environments
- **Password Complexity**: Ensure passwords meet your organization's complexity requirements
- **Network Configuration**: Verify network settings before running the script
- **Backup**: Consider taking a system backup before running the script

## 🔧 Troubleshooting

### Common Issues

1. **Script Execution Policy**: Set execution policy with `Set-ExecutionPolicy RemoteSigned`
2. **Administrator Rights**: Ensure PowerShell is running as Administrator
3. **Network Connectivity**: Verify the server has proper network configuration
4. **Password Requirements**: Ensure SafeModePassword meets complexity requirements

### Manual Recovery

If the automated process fails, you can run individual phases:

```powershell
# Run domain provisioning manually
.\Setup-ADDomain.ps1 -ProvisionDomain

# Run user creation manually
.\Setup-ADDomain.ps1 -CreateUsers -DefaultUserPassword $userPassword
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Related Resources

- [Active Directory Domain Services Overview](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)
- [Install-ADDSForest Documentation](https://docs.microsoft.com/en-us/powershell/module/addsdeployment/install-addsforest)
- [PowerShell Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

---

*This script automates complex Active Directory deployment tasks, making it easier for administrators to set up consistent AD environments for testing, development, and proof-of-concept scenarios.*