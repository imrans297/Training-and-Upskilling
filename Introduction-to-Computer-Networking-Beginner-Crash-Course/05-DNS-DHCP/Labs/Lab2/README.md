# Lab 2: DHCP Configuration and Troubleshooting

## Objective
Understand DHCP process and troubleshoot DHCP issues.

## Tasks

### Task 1: View DHCP Information
Check your current DHCP configuration:

```bash
# Windows
ipconfig /all

# Linux
ip addr show
cat /var/lib/dhcp/dhclient.leases

# Mac
ipconfig getpacket en0
```

Record:
- Your IP address
- Subnet mask
- Default gateway
- DNS servers
- DHCP server
- Lease obtained/expires

### Task 2: DHCP DORA Process
Explain each step of DORA:

1. **Discover:** ?
2. **Offer:** ?
3. **Request:** ?
4. **Acknowledge:** ?

### Task 3: DHCP Scope Planning
Design DHCP scope for office network:

**Requirements:**
- Network: 192.168.10.0/24
- Gateway: 192.168.10.1
- DNS: 8.8.8.8, 8.8.4.4
- Reserve IPs for:
  - Gateway: .1
  - Servers: .2-.10
  - Printers: .11-.20
- DHCP pool: ?
- Lease time: 8 hours

### Task 4: DHCP Troubleshooting

**Scenario A:**
Computer shows IP: 169.254.x.x

Problem: ?
Solution: ?

**Scenario B:**
Users report "IP address conflict"

Problem: ?
Solution: ?

**Scenario C:**
New devices can't get IP addresses

Problem: ?
Solution: ?

### Task 5: Release and Renew
Practice DHCP commands:

```bash
# Windows
ipconfig /release
ipconfig /renew

# Linux
sudo dhclient -r
sudo dhclient

# Mac
sudo ipconfig set en0 DHCP
```

When would you use these commands?

## Expected Outcomes
- Understand DHCP process
- Design DHCP scopes
- Troubleshoot DHCP issues
- Use DHCP commands

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 2:**
1. Discover: Client broadcasts request for IP
2. Offer: Server offers available IP
3. Request: Client requests the offered IP
4. Acknowledge: Server confirms assignment

**Task 3:**
DHCP pool: 192.168.10.21 - 192.168.10.254

**Task 4:**
- Scenario A: Can't reach DHCP server (APIPA assigned). Check network connection, DHCP server status
- Scenario B: Duplicate IP assignment. Check DHCP scope, static IPs, release/renew
- Scenario C: DHCP scope exhausted. Expand scope, reduce lease time, remove unused reservations

**Task 5:**
Use when: IP issues, network changes, troubleshooting connectivity
</details>
