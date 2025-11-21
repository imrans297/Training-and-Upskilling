# Lab 3: ARP and MAC Addresses

## Objective
Understand Address Resolution Protocol and MAC address mapping.

## Tasks

### Task 1: View ARP Table
Run the ARP command on your system:

```bash
# Windows
arp -a

# Linux/Mac
arp -n
```

Questions:
1. How many entries in your ARP table?
2. What's your gateway's MAC address?
3. What does "incomplete" or "?" mean?

### Task 2: ARP Process
Explain the ARP process step-by-step:

**Scenario:**
- Computer A (192.168.1.100) wants to send data to Computer B (192.168.1.101)
- Computer A doesn't know B's MAC address

Steps:
1. ?
2. ?
3. ?
4. ?

### Task 3: ARP Cache Analysis

**Given ARP table:**
```
IP Address       MAC Address       Type
192.168.1.1      AA:BB:CC:DD:EE:01 dynamic
192.168.1.50     AA:BB:CC:DD:EE:02 dynamic
192.168.1.100    AA:BB:CC:DD:EE:03 static
```

Questions:
1. What's the difference between dynamic and static entries?
2. Which device is likely the gateway?
3. How long do dynamic entries typically last?

### Task 4: Troubleshooting
**Problem:** Computer can ping IP addresses but communication is unreliable.

Possible ARP-related causes:
1. ?
2. ?
3. ?

How to fix:
```bash
# Clear ARP cache
# Windows: arp -d
# Linux: sudo ip -s -s neigh flush all
```

## Expected Outcomes
- Understand ARP's role in networking
- Read and interpret ARP tables
- Troubleshoot ARP-related issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 2:**
1. Computer A broadcasts ARP request: "Who has 192.168.1.101?"
2. All devices receive broadcast
3. Computer B responds: "I have 192.168.1.101, my MAC is XX:XX:XX:XX:XX:XX"
4. Computer A caches the MAC address and sends data

**Task 3:**
1. Dynamic: learned automatically, expires; Static: manually configured, permanent
2. 192.168.1.1 (typically .1 is gateway)
3. Usually 2-20 minutes depending on OS

**Task 4:**
Causes: ARP cache poisoning, duplicate IP, stale ARP entries
</details>
