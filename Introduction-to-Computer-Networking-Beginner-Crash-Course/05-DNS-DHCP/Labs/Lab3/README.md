# Lab 3: DNS and DHCP Integration

## Objective
Understand how DNS and DHCP work together in a network.

## Tasks

### Task 1: DNS Cache Analysis
Check and manage DNS cache:

```bash
# Windows
ipconfig /displaydns
ipconfig /flushdns

# Linux
sudo systemd-resolve --statistics
sudo systemd-resolve --flush-caches

# Mac
sudo dscacheutil -flushcache
```

Questions:
1. Why is DNS caching important?
2. When should you flush DNS cache?
3. What's the typical TTL for DNS records?

### Task 2: Dynamic DNS (DDNS)
Explain how DDNS works:

**Scenario:**
- DHCP assigns IP 192.168.1.50 to computer "PC-SALES-01"
- DDNS enabled

What happens:
1. ?
2. ?
3. ?

### Task 3: Network Configuration Comparison

Compare Static vs DHCP configuration:

**Static IP:**
- Pros: ?
- Cons: ?
- Use cases: ?

**DHCP:**
- Pros: ?
- Cons: ?
- Use cases: ?

### Task 4: Complete Network Setup
Design complete network configuration:

**Network:** 192.168.50.0/24

**Devices:**
- 50 workstations (DHCP)
- 3 servers (Static)
- 2 printers (DHCP reservation)
- 1 router/gateway

Specify:
- Gateway IP
- DNS servers
- DHCP scope
- Static IP assignments
- DHCP reservations (MAC → IP)

### Task 5: Troubleshooting Integration Issues

**Scenario:**
Users can access websites by IP but not by name.

Diagnosis:
1. Test: ?
2. Check: ?
3. Solution: ?

## Expected Outcomes
- Understand DNS-DHCP integration
- Configure complete network services
- Troubleshoot combined DNS/DHCP issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
1. Reduces DNS query traffic, faster responses
2. When DNS records change, troubleshooting DNS issues
3. Typically 300-86400 seconds (5 min - 24 hours)

**Task 2:**
1. DHCP server assigns IP to PC-SALES-01
2. DHCP server updates DNS with hostname → IP mapping
3. Other devices can now resolve PC-SALES-01 to 192.168.1.50

**Task 3:**
Static - Pros: Consistent, good for servers; Cons: Manual config, management overhead; Use: Servers, network devices
DHCP - Pros: Automatic, scalable; Cons: IP may change; Use: Workstations, mobile devices

**Task 5:**
1. Test: nslookup google.com
2. Check: DNS server settings in DHCP
3. Solution: Configure correct DNS servers in DHCP scope
</details>
