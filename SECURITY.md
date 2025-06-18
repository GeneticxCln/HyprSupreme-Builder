# Security Policy

## Supported Versions

We provide security updates for the following versions of HyprSupreme-Builder:

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| 1.9.x   | :white_check_mark: |
| 1.8.x   | :x:                |
| < 1.8   | :x:                |

## Reporting a Vulnerability

We take the security of HyprSupreme-Builder seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### How to Report

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@hyprsupreme.dev**

Include the following information in your report:

- **Type of issue** (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- **Full paths** of source file(s) related to the manifestation of the issue
- **Location** of the affected source code (tag/branch/commit or direct URL)
- **Special configuration** required to reproduce the issue
- **Step-by-step instructions** to reproduce the issue
- **Proof-of-concept or exploit code** (if possible)
- **Impact** of the issue, including how an attacker might exploit the issue

### What to Expect

- **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 48 hours.
- **Updates**: We will provide regular updates on our progress at least every 7 days.
- **Timeline**: We aim to resolve critical vulnerabilities within 30 days of initial report.
- **Credit**: We will credit security researchers who responsibly disclose vulnerabilities.

## Security Best Practices

### For Users

1. **Keep Updated**: Always use the latest version of HyprSupreme-Builder
2. **Verify Downloads**: Check SHA256 checksums for downloaded packages
3. **Review Permissions**: Understand what permissions the installer requires
4. **Backup Configurations**: Always backup your configurations before installation
5. **Use Official Sources**: Only download from official GitHub releases

### For Developers

1. **Code Review**: All code changes require review before merging
2. **Dependency Scanning**: Regularly scan for vulnerable dependencies
3. **Input Validation**: Validate all user inputs and external data
4. **Secure Defaults**: Use secure configurations by default
5. **Principle of Least Privilege**: Request only necessary permissions

## Security Features

### Current Security Measures

- **Input Validation**: All user inputs are validated and sanitized
- **Path Traversal Protection**: File operations are restricted to safe directories
- **Command Injection Prevention**: Shell commands are properly escaped
- **Configuration Backup**: Automatic backups before making changes
- **Permission Checks**: Verification of file/directory permissions
- **Checksum Verification**: File integrity checking for downloads

### Planned Security Enhancements

- **Code Signing**: Digital signatures for releases
- **Supply Chain Security**: Enhanced dependency verification
- **Runtime Security**: Additional runtime security checks
- **Audit Logging**: Comprehensive security event logging

## Known Security Considerations

### Installation Scripts

- Installation scripts require root/sudo privileges for system-wide changes
- Scripts modify system configurations and install packages
- Always review scripts before execution in production environments

### Web Interface

- Community web interface runs on localhost by default
- No authentication required for local access
- Consider firewall rules if exposing to network

### Theme Installation

- Themes may contain executable code
- Only install themes from trusted sources
- Review theme contents before installation

## Vulnerability Disclosure Timeline

1. **Day 0**: Vulnerability reported
2. **Day 1-2**: Acknowledgment and initial assessment
3. **Day 3-7**: Detailed analysis and impact assessment
4. **Day 8-14**: Develop and test fix
5. **Day 15-21**: Prepare security advisory and release
6. **Day 22-30**: Public disclosure and release

## Contact

- **Security Email**: security@hyprsupreme.dev
- **General Support**: support@hyprsupreme.dev
- **Project Repository**: https://github.com/GeneticxCln/HyprSupreme-Builder

## Attribution

We would like to thank the following individuals for responsibly disclosing security vulnerabilities:

- (No vulnerabilities reported yet)

---

*This security policy is based on industry best practices and will be updated as needed.*

