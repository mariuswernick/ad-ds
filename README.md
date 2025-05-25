# Active Directory Domain Services Toolkit

A comprehensive collection of PowerShell scripts and tools for Active Directory Domain Services (AD DS) administration, automation, and management. This repository provides system administrators with battle-tested tools for common AD tasks, from initial deployment to ongoing maintenance.

## 🎯 Overview

This toolkit is designed for system administrators, IT professionals, and organizations who work with Active Directory environments. Whether you're setting up new domains, managing users, or maintaining existing infrastructure, these tools will help streamline your AD operations.

## 🛠️ Available Tools

### 🚀 [Setup-ADDomain.ps1](Setup-ADDomain.ps1) - Automated Domain Controller Deployment

A comprehensive script for automated deployment of Active Directory Domain Services with zero-touch installation.

**What it does:**
- Automated computer renaming to specified DC name (default: HQ-DC01)
- AD DS role installation with management tools
- Domain controller promotion with new forest creation
- Automatic user account and OU creation for testing
- Multi-phase automation using Windows Registry RunOnce entries

**Key Features:**
- ✅ **Zero-Touch Deployment**: Run once, handles everything automatically
- ✅ **Registry-Based Automation**: More reliable than scheduled tasks
- ✅ **Visible Progress**: PowerShell windows remain visible throughout
- ✅ **Customizable Configuration**: Flexible parameters for various scenarios
- ✅ **Enterprise Ready**: Suitable for lab, testing, and PoC deployments

#### Quick Start

```powershell
# Set up the required passwords
$safePassword = ConvertTo-SecureString "YourComplexPassword123!" -AsPlainText -Force
$userPassword = ConvertTo-SecureString "TestUser123!" -AsPlainText -Force

# Run the script with basic configuration
.\Setup-ADDomain.ps1 -DomainName "company.local" -SafeModeAdministratorPassword $safePassword -DefaultUserPassword $userPassword -NumberOfUsers 15
```

#### Advanced Usage

```powershell
# Custom domain controller name and configuration
.\Setup-ADDomain.ps1 -DomainName "corp.example.com" -SafeModeAdministratorPassword $safePassword -DefaultUserPassword $userPassword -NumberOfUsers 25 -DCName "MAIN-DC01"
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `DomainName` | String | No | "contoso.local" | The fully qualified domain name for the new domain |
| `SafeModeAdministratorPassword` | SecureString | Yes* | - | Password for Directory Services Restore Mode |
| `DefaultUserPassword` | SecureString | No | - | Password for automatically created test users |
| `NumberOfUsers` | Integer | No | 10 | Number of test users to create |
| `DCName` | String | No | "HQ-DC01" | Name for the domain controller computer |

*Required only for initial setup

#### Process Flow

The script operates in three distinct phases:

1. **Computer Preparation**: Installs AD DS role, renames computer, creates registry entry, reboots
2. **Domain Provisioning**: Promotes to DC, creates AD forest, installs DNS, reboots
3. **User Creation**: Creates organizational structure and test users, completes setup

#### What Gets Created

**Organizational Structure:**
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

**User Accounts:**
- Random first and last names from predefined lists
- Unique usernames (firstname.lastname + random number)
- Email addresses based on domain name
- Distributed across different department OUs
- Enabled accounts with non-expiring passwords

---

## 🔮 Coming Soon

*Additional tools currently in development:*

- **Bulk User Management Scripts** - Import/export users from CSV
- **Group Policy Automation Tools** - Deploy and manage GPOs at scale
- **AD Health Check Scripts** - Comprehensive domain health monitoring
- **Replication Monitoring Tools** - Track and troubleshoot AD replication
- **Security Audit Scripts** - Identify security gaps and compliance issues
- **Backup and Recovery Tools** - Automated AD backup and restore procedures
- **Migration Utilities** - Tools for domain migrations and upgrades
- **Permission Management** - Audit and manage AD permissions
- **Certificate Services Tools** - PKI deployment and management scripts

## 📋 Prerequisites

- Windows Server (2016, 2019, 2022)
- Administrator privileges
- PowerShell execution policy set to allow script execution
- Appropriate network configuration for domain services

## 🔧 Getting Started

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/mariuswernick/ad-ds.git
   cd ad-ds
   ```

2. **Set execution policy if needed:**
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Choose your tool and review the documentation**

4. **Run the examples or customize for your environment**

## 💡 Examples

Check out the [examples](examples/) directory for:
- **[basic-usage.ps1](examples/basic-usage.ps1)** - Simple setup scenarios
- **[advanced-usage.ps1](examples/advanced-usage.ps1)** - Complex configurations with pre-flight checks

## 🛡️ Security Considerations

- **Production Use**: These tools are designed for lab and testing environments
- **Password Security**: Ensure all passwords meet your organization's complexity requirements
- **Network Security**: Verify network settings and firewall configurations
- **Backup Strategy**: Always have a backup plan before making changes
- **Testing**: Test scripts in non-production environments first

## 📝 Logging and Monitoring

All scripts create detailed logs for troubleshooting and audit purposes:
- Location: `C:\Windows\Temp\`
- Format: `ToolName_[timestamp].log`
- Content: Comprehensive operation logs with timestamps

## ⚠️ Important Notes

- **Environment**: These scripts are designed for lab, testing, and development environments
- **Customization**: Review and modify scripts to match your specific requirements
- **Documentation**: Each tool includes comprehensive inline documentation
- **Support**: Check individual script documentation for specific requirements and limitations

## 🔧 Troubleshooting

### Common Issues

1. **Script Execution Policy**: Set with `Set-ExecutionPolicy RemoteSigned`
2. **Administrator Rights**: Ensure PowerShell runs as Administrator
3. **Network Configuration**: Verify proper network settings
4. **Password Requirements**: Ensure passwords meet complexity requirements
5. **Prerequisites**: Verify all required Windows features are available

### Getting Help

- Check the individual script documentation
- Review the examples directory
- Examine log files in `C:\Windows\Temp\`
- Open an issue in the repository for bugs or feature requests

## 🤝 Contributing

Contributions are welcome! Whether you have:
- New tools to add to the toolkit
- Improvements to existing scripts  
- Bug fixes or optimizations
- Documentation updates
- Usage examples

Please feel free to:
- Fork the repository
- Create feature branches
- Submit pull requests
- Open issues for bugs or feature requests
- Share your experiences and use cases

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Resources

- [Active Directory Domain Services Overview](https://docs.microsoft.com/en-us/windows-server/identity/ad-ds/get-started/virtual-dc/active-directory-domain-services-overview)
- [PowerShell Active Directory Module](https://docs.microsoft.com/en-us/powershell/module/activedirectory/)
- [Windows Server Documentation](https://docs.microsoft.com/en-us/windows-server/)
- [PowerShell Execution Policies](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies)

---

*This toolkit is continuously evolving. Star the repository to stay updated with new tools and improvements!*