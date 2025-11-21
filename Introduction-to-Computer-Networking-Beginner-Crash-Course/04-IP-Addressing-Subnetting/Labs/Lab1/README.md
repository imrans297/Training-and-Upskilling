# Lab 1: IP Address Classes and Private IPs

## Objective
Identify IP address classes and distinguish between public and private IPs.

## Tasks

### Task 1: Class Identification
Identify the class for each IP address:

1. 10.0.0.1
2. 172.16.0.1
3. 192.168.1.1
4. 8.8.8.8
5. 224.0.0.1
6. 127.0.0.1
7. 150.100.50.25
8. 200.50.100.150

### Task 2: Public vs Private
Mark each IP as Public or Private:

1. 10.50.100.200
2. 74.125.224.72 (Google)
3. 172.16.0.50
4. 192.168.0.1
5. 172.32.0.1
6. 8.8.4.4 (Google DNS)
7. 169.254.1.1
8. 192.168.255.255

### Task 3: Special Addresses
Explain the purpose of these special IPs:

1. 127.0.0.1
2. 0.0.0.0
3. 255.255.255.255
4. 169.254.x.x

### Task 4: Network Planning
Design IP addressing for a company:

**Requirements:**
- 3 departments: Sales (50 users), Engineering (100 users), HR (20 users)
- Use private IP space
- Each department needs separate network

Choose appropriate private IP ranges for each department.

## Expected Outcomes
- Identify IP address classes
- Distinguish public from private IPs
- Understand special IP addresses
- Plan IP addressing schemes

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
1. Class A, 2. Class B, 3. Class C, 4. Class A, 5. Class D, 6. Class A (loopback), 7. Class B, 8. Class C

**Task 2:**
1. Private, 2. Public, 3. Private, 4. Private, 5. Public, 6. Public, 7. APIPA (special), 8. Private

**Task 3:**
1. Loopback (localhost)
2. Default route or unspecified
3. Broadcast address
4. APIPA (auto-assigned when DHCP fails)

**Task 4:**
Example:
- Sales: 192.168.1.0/26 (62 hosts)
- Engineering: 192.168.2.0/25 (126 hosts)
- HR: 192.168.3.0/27 (30 hosts)
</details>
