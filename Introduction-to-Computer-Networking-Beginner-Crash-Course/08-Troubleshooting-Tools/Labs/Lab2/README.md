# Lab 2: Advanced Network Tools

## Objective
Use advanced network diagnostic tools for in-depth troubleshooting.

## Tasks

### Task 1: netstat Analysis
Run netstat commands:

```bash
# Active connections
netstat -an

# Listening ports
netstat -l  # Linux
netstat -an | findstr LISTENING  # Windows

# Routing table
netstat -r

# Statistics
netstat -s
```

Questions:
1. Which ports are listening on your system?
2. Any established connections?
3. What's your default gateway?
4. Any unusual connections?

### Task 2: Port Connectivity Testing
Test if services are accessible:

```bash
# Test web server
telnet google.com 80
curl -I https://google.com

# Test SSH
telnet [server-ip] 22

# Test custom port
nc -zv [server-ip] [port]  # Linux
```

Test these services and document results:
1. google.com:80 (HTTP)
2. google.com:443 (HTTPS)
3. 8.8.8.8:53 (DNS)
4. Your gateway:22 (SSH)

### Task 3: DNS Troubleshooting
Perform comprehensive DNS testing:

```bash
# Basic lookup
nslookup google.com

# Specific DNS server
nslookup google.com 8.8.8.8
nslookup google.com 1.1.1.1

# Different record types
nslookup -type=MX gmail.com
nslookup -type=NS google.com

# Using dig (Linux/Mac)
dig google.com
dig +trace google.com
dig -x 8.8.8.8  # Reverse lookup
```

Compare results:
- Your DNS vs Google DNS (8.8.8.8)
- Response times
- Any differences in results?

### Task 4: Network Performance Testing
Test network performance:

**Bandwidth Test:**
```bash
# Using iperf (if available)
# Server: iperf -s
# Client: iperf -c [server-ip]

# Using speedtest-cli
speedtest-cli
```

**Latency Test:**
```bash
# Continuous ping
ping -c 100 8.8.8.8  # Linux/Mac
ping -n 100 8.8.8.8  # Windows

# Calculate average, min, max, packet loss
```

Document:
- Download speed
- Upload speed
- Latency (avg/min/max)
- Packet loss percentage

### Task 5: Comprehensive Troubleshooting
**Scenario:** Web application is slow

Investigation steps:
1. Test connectivity: ?
2. Check DNS: ?
3. Test port: ?
4. Check latency: ?
5. Analyze route: ?
6. Check local resources: ?

Document your findings and recommendations.

## Expected Outcomes
- Use advanced diagnostic tools
- Test port connectivity
- Perform DNS troubleshooting
- Measure network performance
- Conduct comprehensive analysis

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 5:**
1. ping [web-server]
2. nslookup [web-server]
3. telnet [web-server] 80/443
4. ping -c 50 [web-server] (check latency)
5. traceroute [web-server] (find bottleneck)
6. Check CPU, memory, network utilization

Possible issues:
- High latency on specific hop
- DNS resolution slow
- Server overloaded
- Network congestion
- Application performance issue
</details>
