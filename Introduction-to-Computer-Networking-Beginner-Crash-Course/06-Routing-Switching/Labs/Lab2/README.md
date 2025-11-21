# Lab 2: Routing Tables and Static Routes

## Objective
Understand routing tables and configure static routes.

## Tasks

### Task 1: Reading Routing Tables
View your routing table:

```bash
# Windows
route print

# Linux/Mac
route -n
ip route show
```

Identify:
1. Default gateway
2. Local network routes
3. Loopback route

### Task 2: Routing Decision
Given routing table:
```
Destination      Gateway         Interface
192.168.1.0/24   0.0.0.0         eth0
192.168.2.0/24   192.168.1.254   eth0
10.0.0.0/8       192.168.1.1     eth0
0.0.0.0/0        192.168.1.1     eth0
```

Where will packets be routed:
1. Destination: 192.168.1.50
2. Destination: 192.168.2.100
3. Destination: 10.50.100.200
4. Destination: 8.8.8.8

### Task 3: Static Route Configuration
Network topology:
```
Network A: 192.168.1.0/24 ← Router1 → 10.0.0.0/30 ← Router2 → Network B: 192.168.2.0/24
```

Configure static routes:
- On Router1 to reach Network B
- On Router2 to reach Network A

### Task 4: Multi-Path Routing
Given:
```
Network: 192.168.10.0/24
Two paths to 10.0.0.0/8:
- Path A: via 192.168.10.1 (fast, reliable)
- Path B: via 192.168.10.2 (slow, backup)
```

How to configure:
1. Primary route
2. Backup route (floating static)

### Task 5: Troubleshooting
**Problem:** Can't reach remote network 10.50.0.0/16

Diagnosis steps:
1. Check: ?
2. Verify: ?
3. Test: ?

## Expected Outcomes
- Read and interpret routing tables
- Configure static routes
- Understand routing decisions
- Troubleshoot routing issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 2:**
1. 192.168.1.50 → Direct (eth0)
2. 192.168.2.100 → via 192.168.1.254
3. 10.50.100.200 → via 192.168.1.1
4. 8.8.8.8 → via 192.168.1.1 (default route)

**Task 3:**
Router1: ip route 192.168.2.0 255.255.255.0 10.0.0.2
Router2: ip route 192.168.1.0 255.255.255.0 10.0.0.1

**Task 4:**
Primary: ip route 10.0.0.0 255.0.0.0 192.168.10.1
Backup: ip route 10.0.0.0 255.0.0.0 192.168.10.2 10 (higher AD)

**Task 5:**
1. Check routing table for 10.50.0.0/16
2. Verify gateway is reachable
3. Test with traceroute to see where packets stop
</details>
