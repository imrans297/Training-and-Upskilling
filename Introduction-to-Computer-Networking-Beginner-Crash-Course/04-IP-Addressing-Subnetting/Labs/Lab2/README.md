# Lab 2: Subnetting Practice

## Objective
Master subnetting calculations and subnet design.

## Tasks

### Task 1: Basic Subnetting
Given network: 192.168.10.0/24
Create 4 equal subnets.

Calculate for each subnet:
1. New subnet mask
2. Network address
3. First usable IP
4. Last usable IP
5. Broadcast address
6. Number of usable hosts

### Task 2: CIDR Notation
Convert between subnet mask and CIDR:

1. 255.255.255.0 = /?
2. 255.255.255.128 = /?
3. 255.255.255.192 = /?
4. /27 = ?
5. /30 = ?
6. /26 = ?

### Task 3: Subnet Design
Network: 172.16.0.0/16

Create subnets for:
- Subnet A: 500 hosts
- Subnet B: 200 hosts
- Subnet C: 100 hosts
- Subnet D: 50 hosts

For each, determine:
- Appropriate subnet mask
- Network address
- Usable IP range

### Task 4: Quick Calculations
Answer without calculator:

1. How many hosts in /25?
2. How many hosts in /28?
3. How many subnets from /24 to /26?
4. What's the broadcast for 192.168.1.64/26?

## Expected Outcomes
- Perform subnetting calculations
- Design efficient subnet schemes
- Convert between CIDR and subnet masks
- Quick mental subnet math

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
New mask: /26 (255.255.255.192)
Hosts per subnet: 62

Subnet 1: 192.168.10.0/26
- Network: 192.168.10.0
- Usable: 192.168.10.1 - 192.168.10.62
- Broadcast: 192.168.10.63

Subnet 2: 192.168.10.64/26
- Network: 192.168.10.64
- Usable: 192.168.10.65 - 192.168.10.126
- Broadcast: 192.168.10.127

(Continue for subnets 3 and 4)

**Task 2:**
1. /24, 2. /25, 3. /26, 4. 255.255.255.224, 5. 255.255.255.252, 6. 255.255.255.192

**Task 4:**
1. 126 hosts, 2. 14 hosts, 3. 4 subnets, 4. 192.168.1.127
</details>
