# Lab 2: ICMP and Network Tools

## Objective
Use ICMP-based tools for network diagnostics.

## Tasks

### Task 1: Ping Analysis
Run these ping commands and analyze results:

```bash
ping 127.0.0.1
ping 192.168.1.1
ping 8.8.8.8
ping google.com
```

For each, record:
- Success/Failure
- Average latency
- Packet loss %
- What it tests

### Task 2: Traceroute
Run traceroute to a website:

```bash
# Linux/Mac
traceroute google.com

# Windows
tracert google.com
```

Questions:
1. How many hops to destination?
2. Which hop has highest latency?
3. Can you identify your ISP's routers?

### Task 3: Troubleshooting Scenarios

**Scenario A:**
- `ping 127.0.0.1` ✓
- `ping 192.168.1.1` ✗
- What's the problem?

**Scenario B:**
- `ping 8.8.8.8` ✓
- `ping google.com` ✗
- What's the problem?

**Scenario C:**
- `ping google.com` shows 500ms latency
- Normal is 20ms
- What could be wrong?

### Task 4: ICMP Messages
Match ICMP message types with scenarios:
1. Echo Request/Reply
2. Destination Unreachable
3. Time Exceeded
4. Redirect

## Expected Outcomes
- Use ping and traceroute effectively
- Interpret ICMP messages
- Diagnose connectivity issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
- 127.0.0.1: Tests local TCP/IP stack
- 192.168.1.1: Tests local network/gateway
- 8.8.8.8: Tests Internet connectivity
- google.com: Tests DNS + Internet

**Task 3:**
- Scenario A: Network cable, switch, or gateway issue
- Scenario B: DNS problem
- Scenario C: Network congestion, routing issue, or ISP problem
</details>
