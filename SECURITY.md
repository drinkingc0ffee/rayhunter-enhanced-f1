# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.4.x   | :white_check_mark: |
| 0.3.x   | :x:                |
| < 0.3   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in Rayhunter Enhanced, please follow responsible disclosure:

### How to Report

1. **DO NOT** open a public GitHub issue for security vulnerabilities
2. Use GitHub's [private vulnerability reporting tool](https://github.com/[your-org]/rayhunter-enhanced/security/advisories/new)
3. **Include** the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact assessment
   - Suggested fix (if available)

### What to Expect

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity (Critical: 7 days, High: 30 days, Medium: 90 days)

### Security Best Practices for Users

#### Data Handling
- **Never commit** real QMDL files containing personal data
- **Sanitize** all data before sharing or publishing
- **Use isolated environments** for analysis of sensitive captures

#### Legal Compliance
- **Obtain explicit permission** before analyzing cellular networks
- **Comply with local laws** regarding telecommunications monitoring
- **Use only for authorized security research** and testing

#### Tool Security
- **Keep tools updated** to the latest version
- **Verify file integrity** before analyzing unknown captures
- **Run in sandboxed environments** when possible

## Security Measures in Rayhunter Enhanced

### Built-in Protections
- **Input validation** for all file formats
- **Memory safety** through Rust implementation
- **Sanitized output** options for sensitive data
- **Configurable security settings**

### Recommended Usage
- **Isolated analysis environment** (VM or container)
- **Regular security updates**
- **Authorized use only** with proper permissions
- **Data destruction** after analysis completion

---

**Remember**: This tool is designed for defensive security research. Misuse for unauthorized surveillance or interception is strictly prohibited and may violate local and international laws.
