# Lab 3: VLSM and Advanced Subnetting

## Objective
Implement Variable Length Subnet Masking for efficient IP utilization.

## Tasks

### Task 1: VLSM Design
Given: 192.168.100.0/24

Create subnets for:
- Branch A: 100 hosts
- Branch B: 50 hosts
- Branch C: 25 hosts
- Branch D: 10 hosts
- 3 point-to-point links (2 hosts each)

Use VLSM to minimize IP waste.

### Task 2: Subnet Verification
Determine if these IPs are in the same subnet:

**Scenario A:**
- IP1: 192.168.1.50/26
- IP2: 192.168.1.70/26
- Same subnet? Why?

**Scenario B:**
- IP1: 10.0.0.100/25
- IP2: 10.0.0.200/25
- Same subnet? Why?

**Scenario C:**
- IP1: 172.16.10.15/28
- IP2: 172.16.10.20/28
- Same subnet? Why?

### Task 3: Supernetting
Combine these networks into one supernet:
- 192.168.0.0/24
- 192.168.1.0/24
- 192.168.2.0/24
- 192.168.3.0/24

What's the supernet address and mask?

### Task 4: Real-World Scenario
You're assigned 10.50.0.0/22 for your organization.

Design subnets for:
- Main office: 400 hosts
- Branch 1: 150 hosts
- Branch 2: 100 hosts
- DMZ: 30 hosts
- Management: 10 hosts
- 5 WAN links: 2 hosts each

## Expected Outcomes
- Apply VLSM efficiently
- Verify subnet membership
- Understand supernetting
- Design complex network addressing

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
- Branch A: 192.168.100.0/25 (126 hosts)
- Branch B: 192.168.100.128/26 (62 hosts)
- Branch C: 192.168.100.192/27 (30 hosts)
- Branch D: 192.168.100.224/28 (14 hosts)
- Links: 192.168.100.240/30, .244/30, .248/30 (2 hosts each)

**Task 2:**
- Scenario A: Yes (both in 192.168.1.0/26)
- Scenario B: No (100 in .0/25, 200 in .128/25)
- Scenario C: No (15 in .0/28, 20 in .16/28)

**Task 3:**
Supernet: 192.168.0.0/22
</details>
