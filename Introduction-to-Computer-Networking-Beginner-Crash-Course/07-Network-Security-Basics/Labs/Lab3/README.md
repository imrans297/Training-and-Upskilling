# Lab 3: Wireless Security and VPN

## Objective
Implement wireless security and understand VPN technologies.

## Tasks

### Task 1: Wireless Security Assessment
Evaluate security of each WiFi configuration:

**Config A:**
- SSID: CompanyWiFi (broadcast)
- Security: WEP
- Password: 12345

Security rating: ?
Vulnerabilities: ?
Recommendations: ?

**Config B:**
- SSID: Hidden
- Security: WPA2-PSK
- Password: C0mp1ex!P@ssw0rd2024

Security rating: ?
Vulnerabilities: ?
Recommendations: ?

**Config C:**
- SSID: Enterprise-WiFi
- Security: WPA2-Enterprise (802.1X)
- Authentication: RADIUS

Security rating: ?
Benefits: ?

### Task 2: WiFi Security Configuration
Design WiFi security for office:

**Requirements:**
- Employee WiFi: Secure, individual authentication
- Guest WiFi: Isolated from internal network
- IoT devices: Separate network

For each network specify:
- SSID
- Security type
- Authentication method
- VLAN assignment
- Access restrictions

### Task 3: VPN Configuration
Choose VPN type for each scenario:

**Scenario A:** Remote employee needs access to office network
- VPN Type: ?
- Protocol: ?
- Configuration: ?

**Scenario B:** Connect two office locations
- VPN Type: ?
- Protocol: ?
- Configuration: ?

**Scenario C:** Secure browsing on public WiFi
- VPN Type: ?
- Use case: ?

### Task 4: Encryption Methods
Match encryption with use case:

**Encryption Types:** WEP, WPA, WPA2, WPA3, SSL/TLS, IPSec

**Use Cases:**
1. Modern WiFi security: ?
2. Web traffic (HTTPS): ?
3. VPN tunnel: ?
4. Legacy device (avoid if possible): ?
5. Latest WiFi standard: ?

### Task 5: Security Audit
Perform security audit on home network:

Checklist:
- [ ] Router admin password changed from default?
- [ ] WiFi using WPA2 or WPA3?
- [ ] WiFi password strong (12+ characters)?
- [ ] SSID not revealing personal info?
- [ ] Guest network enabled and isolated?
- [ ] Router firmware up to date?
- [ ] WPS disabled?
- [ ] Remote management disabled?

Document findings and recommendations.

## Expected Outcomes
- Implement wireless security best practices
- Configure VPN solutions
- Understand encryption methods
- Perform security audits

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
- Config A: Poor - WEP crackable, weak password, visible SSID
- Config B: Good - WPA2 secure, strong password; hiding SSID adds little security
- Config C: Excellent - Enterprise authentication, individual credentials, centralized control

**Task 2:**
- Employee: WPA2-Enterprise, 802.1X/RADIUS, VLAN 10, full access
- Guest: WPA2-PSK, simple password, VLAN 99, Internet only
- IoT: WPA2-PSK, separate password, VLAN 50, restricted access

**Task 3:**
- Scenario A: Remote Access VPN, SSL-VPN or IPSec
- Scenario B: Site-to-Site VPN, IPSec
- Scenario C: Personal VPN service, privacy protection

**Task 4:**
1. WPA2, 2. SSL/TLS, 3. IPSec, 4. WEP, 5. WPA3
</details>
