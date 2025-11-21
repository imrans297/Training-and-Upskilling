# 07. Network Security Basics

## Security Fundamentals

### CIA Triad
- **Confidentiality**: Data accessible only to authorized users
- **Integrity**: Data remains accurate and unaltered
- **Availability**: Systems accessible when needed

## Common Network Threats

### Malware
- **Virus**: Attaches to files, spreads when executed
- **Worm**: Self-replicating, spreads without user action
- **Trojan**: Disguised as legitimate software
- **Ransomware**: Encrypts data, demands payment
- **Spyware**: Monitors user activity

### Network Attacks

#### DoS/DDoS (Denial of Service)
- Overwhelms system with traffic
- Makes service unavailable
- DDoS uses multiple sources

#### Man-in-the-Middle (MITM)
- Intercepts communication between parties
- Can read or modify data
- Common on public WiFi

#### Phishing
- Fraudulent emails/websites
- Tricks users into revealing credentials
- Spear phishing targets specific individuals

#### SQL Injection
- Malicious SQL code in input fields
- Accesses or modifies database

#### Cross-Site Scripting (XSS)
- Injects malicious scripts into websites
- Steals session cookies, credentials

#### Brute Force
- Tries all possible password combinations
- Time-consuming but effective on weak passwords

#### Port Scanning
- Identifies open ports and services
- Reconnaissance for attacks

## Security Devices & Technologies

### Firewall
- Filters traffic based on rules
- Types:
  - **Packet Filtering**: Layer 3/4
  - **Stateful**: Tracks connections
  - **Application**: Layer 7, deep inspection
  - **Next-Gen**: IPS, malware detection

### IDS/IPS

#### IDS (Intrusion Detection System)
- Monitors and alerts on suspicious activity
- Passive (doesn't block)

#### IPS (Intrusion Prevention System)
- Monitors and blocks threats
- Active protection

### VPN (Virtual Private Network)
- Encrypts traffic over public networks
- Creates secure tunnel
- Types:
  - **Site-to-Site**: Connects networks
  - **Remote Access**: Connects users to network

### Proxy Server
- Intermediary between client and server
- Filters content, caches data
- Hides client IP address

### DMZ (Demilitarized Zone)
- Isolated network segment
- Hosts public-facing servers
- Adds security layer

## Authentication & Access Control

### Authentication Methods
- **Something you know**: Password, PIN
- **Something you have**: Token, smart card
- **Something you are**: Biometrics (fingerprint, face)

### Multi-Factor Authentication (MFA)
- Combines 2+ authentication methods
- Significantly improves security

### Access Control Models
- **MAC**: Mandatory Access Control
- **DAC**: Discretionary Access Control
- **RBAC**: Role-Based Access Control

## Encryption

### Symmetric Encryption
- Same key for encryption/decryption
- Fast, efficient
- Examples: AES, DES, 3DES

### Asymmetric Encryption
- Public/private key pair
- Slower but more secure
- Examples: RSA, ECC

### Hashing
- One-way function
- Verifies data integrity
- Examples: MD5, SHA-256

### SSL/TLS
- Secures web traffic (HTTPS)
- Encrypts data in transit
- Uses certificates

## Wireless Security

### WEP (Wired Equivalent Privacy)
- **Obsolete**: Easily cracked
- **Don't use**

### WPA (WiFi Protected Access)
- Better than WEP
- Still vulnerable

### WPA2
- Current standard
- Uses AES encryption
- Personal (PSK) or Enterprise (802.1X)

### WPA3
- Latest standard
- Improved encryption
- Better protection on public WiFi

## Security Best Practices

### Network Hardening
- Change default passwords
- Disable unused services/ports
- Keep systems updated
- Use strong passwords
- Implement least privilege
- Regular backups
- Network segmentation

### Password Security
- Minimum 12 characters
- Mix of upper/lower/numbers/symbols
- No dictionary words
- Unique per account
- Use password manager

### Monitoring & Logging
- Enable logging on all devices
- Monitor for anomalies
- Regular security audits
- Incident response plan

## Common Ports & Security
| Port | Service | Security Risk |
|------|---------|---------------|
| 21 | FTP | Unencrypted |
| 22 | SSH | Secure (if configured) |
| 23 | Telnet | Unencrypted |
| 80 | HTTP | Unencrypted |
| 443 | HTTPS | Encrypted |
| 3389 | RDP | Target for attacks |

## Next Steps
Practice security configurations and threat identification in the Labs.
