# Lab 2: Firewall Rules and Access Control

## Objective
Design firewall rules and implement access control policies.

## Tasks

### Task 1: Firewall Rule Design
Create firewall rules for web server (192.168.1.100):

**Requirements:**
- Allow HTTP (80) from anywhere
- Allow HTTPS (443) from anywhere
- Allow SSH (22) from admin network (10.0.0.0/24) only
- Allow ping from internal network (192.168.1.0/24)
- Block all other traffic

Write rules in this format:
```
Rule # | Action | Source | Destination | Port | Protocol
```

### Task 2: DMZ Configuration
Design DMZ for company:

**Resources:**
- Public web server
- Public email server
- Internal database server
- Internal file server

Network segments:
- Internet: ?
- DMZ: ?
- Internal LAN: ?

Draw network diagram showing:
- Firewall placement
- Allowed traffic flows
- Blocked traffic flows

### Task 3: Port Security
Identify security risk for each open port:

1. Port 21 (FTP): ?
2. Port 23 (Telnet): ?
3. Port 80 (HTTP): ?
4. Port 3389 (RDP): ?
5. Port 445 (SMB): ?

Recommend secure alternatives.

### Task 4: Access Control Lists (ACL)
Create ACL for router:

**Requirements:**
- Sales VLAN (192.168.10.0/24) can access Internet only
- Engineering VLAN (192.168.20.0/24) can access everything
- Guest VLAN (192.168.99.0/24) can access Internet, block internal
- Block all traffic from 192.168.99.0/24 to 192.168.0.0/16

### Task 5: Troubleshooting
**Problem:** Users can't access internal web server after firewall changes.

Diagnosis:
1. Check: ?
2. Verify: ?
3. Test: ?
4. Solution: ?

## Expected Outcomes
- Design effective firewall rules
- Implement DMZ architecture
- Understand port security
- Create access control policies

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
```
1 | Allow | Any | 192.168.1.100 | 80 | TCP
2 | Allow | Any | 192.168.1.100 | 443 | TCP
3 | Allow | 10.0.0.0/24 | 192.168.1.100 | 22 | TCP
4 | Allow | 192.168.1.0/24 | 192.168.1.100 | ICMP | ICMP
5 | Deny | Any | Any | Any | Any
```

**Task 3:**
1. FTP: Unencrypted credentials → Use SFTP/FTPS
2. Telnet: Unencrypted → Use SSH
3. HTTP: Unencrypted → Use HTTPS
4. RDP: Brute force target → Use VPN, strong passwords, MFA
5. SMB: Ransomware vector → Restrict access, use VPN

**Task 5:**
1. Check firewall rules for web server port
2. Verify source/destination IPs in rules
3. Test with telnet to web server port
4. Add/modify rule to allow traffic
</details>
