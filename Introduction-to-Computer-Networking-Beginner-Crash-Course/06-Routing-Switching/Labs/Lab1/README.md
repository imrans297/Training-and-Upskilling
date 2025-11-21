# Lab 1: Switch Operations and MAC Address Table

## Objective
Understand how switches learn MAC addresses and forward frames.

## Tasks

### Task 1: MAC Address Learning
Given this network:
```
PC-A (MAC: AA:AA:AA:AA:AA:01) → Port 1
PC-B (MAC: BB:BB:BB:BB:BB:02) → Port 2  } Switch
PC-C (MAC: CC:CC:CC:CC:CC:03) → Port 3
```

**Scenario:** PC-A sends frame to PC-B

Show MAC address table after each step:
1. Initial state (empty table)
2. After PC-A sends frame
3. After PC-B replies
4. After PC-C sends to PC-A

### Task 2: Frame Forwarding
For each scenario, explain switch behavior:

**Scenario A:**
- Source MAC: AA:AA:AA:AA:AA:01 (Port 1)
- Dest MAC: BB:BB:BB:BB:BB:02 (Port 2, in table)
- Action: ?

**Scenario B:**
- Source MAC: AA:AA:AA:AA:AA:01 (Port 1)
- Dest MAC: DD:DD:DD:DD:DD:04 (not in table)
- Action: ?

**Scenario C:**
- Source MAC: AA:AA:AA:AA:AA:01 (Port 1)
- Dest MAC: FF:FF:FF:FF:FF:FF (broadcast)
- Action: ?

### Task 3: VLAN Configuration
Design VLANs for company:

**Departments:**
- Sales: 20 users
- Engineering: 30 users
- HR: 10 users
- Guest: WiFi access

Create VLAN plan:
- VLAN IDs
- IP subnets
- Port assignments

### Task 4: Troubleshooting
**Problem:** PC-A can't communicate with PC-B on same switch

Check:
1. ?
2. ?
3. ?
4. ?

## Expected Outcomes
- Understand MAC address learning
- Predict switch forwarding behavior
- Design VLAN schemes
- Troubleshoot switching issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
1. Empty: No entries
2. After PC-A sends: Port 1 → AA:AA:AA:AA:AA:01
3. After PC-B replies: Port 1 → AA:01, Port 2 → BB:02
4. After PC-C sends: Port 1 → AA:01, Port 2 → BB:02, Port 3 → CC:03

**Task 2:**
- Scenario A: Forward to Port 2 only
- Scenario B: Flood to all ports except Port 1
- Scenario C: Flood to all ports except Port 1

**Task 3:**
Example:
- VLAN 10 (Sales): 192.168.10.0/24
- VLAN 20 (Engineering): 192.168.20.0/24
- VLAN 30 (HR): 192.168.30.0/24
- VLAN 99 (Guest): 192.168.99.0/24

**Task 4:**
1. Check if same VLAN
2. Check port status (up/down)
3. Check MAC address table
4. Check for port security restrictions
</details>
