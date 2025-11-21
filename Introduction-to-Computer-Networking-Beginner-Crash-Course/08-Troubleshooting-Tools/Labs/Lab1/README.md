# Lab 1: Basic Network Troubleshooting

## Objective
Use basic network commands to diagnose connectivity issues.

## Tasks

### Task 1: Connectivity Testing
Perform systematic connectivity test:

```bash
# Test 1: Loopback
ping 127.0.0.1

# Test 2: Local IP
ping [your-ip]

# Test 3: Default gateway
ping [gateway-ip]

# Test 4: External IP
ping 8.8.8.8

# Test 5: DNS resolution
ping google.com
```

For each test, document:
- Result (success/fail)
- What it tests
- If failed, what's the problem?

### Task 2: Troubleshooting Scenarios

**Scenario A:**
```
ping 127.0.0.1 → Success
ping 192.168.1.100 (local IP) → Success
ping 192.168.1.1 (gateway) → Failed
ping 8.8.8.8 → Failed
```

Problem: ?
Layer: ?
Solution: ?

**Scenario B:**
```
ping 127.0.0.1 → Success
ping 192.168.1.100 → Success
ping 192.168.1.1 → Success
ping 8.8.8.8 → Success
ping google.com → Failed
```

Problem: ?
Layer: ?
Solution: ?

**Scenario C:**
```
All pings successful but very slow
Average latency: 500ms (normal is 20ms)
Packet loss: 15%
```

Problem: ?
Possible causes: ?
Next steps: ?

### Task 3: Traceroute Analysis
Run traceroute to a website:

```bash
traceroute google.com  # Linux/Mac
tracert google.com     # Windows
```

Analyze results:
1. How many hops?
2. Where is the highest latency?
3. Any timeouts (*)?
4. Can you identify your ISP?

### Task 4: Network Configuration Check
Verify your network configuration:

```bash
# Windows
ipconfig /all

# Linux
ip addr show
ip route show

# Mac
ifconfig
netstat -nr
```

Document:
- IP address
- Subnet mask
- Default gateway
- DNS servers
- DHCP enabled?

### Task 5: Create Troubleshooting Flowchart
Create a flowchart for "No Internet" problem:

Start → Check 1 → Check 2 → ... → Solution

## Expected Outcomes
- Systematic troubleshooting approach
- Use ping and traceroute effectively
- Interpret network configuration
- Develop troubleshooting methodology

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
- Test 1: TCP/IP stack working
- Test 2: Network adapter working
- Test 3: Local network connectivity
- Test 4: Internet connectivity
- Test 5: DNS resolution

**Task 2:**
- Scenario A: Gateway unreachable, Layer 2/3, check cable/switch/gateway
- Scenario B: DNS issue, Layer 7, check DNS settings, flush cache
- Scenario C: Network congestion/routing issue, check bandwidth, ISP, routing

**Task 5 Flowchart:**
1. Check physical connection
2. Ping loopback (127.0.0.1)
3. Ping local IP
4. Ping gateway
5. Ping external IP (8.8.8.8)
6. Ping domain name
7. Identify and fix issue at failed step
</details>
