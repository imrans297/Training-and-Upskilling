# Lab 3: Packet Analysis and Network Monitoring

## Objective
Capture and analyze network traffic using packet analysis tools.

## Tasks

### Task 1: Wireshark Basics
Install and use Wireshark:

**Capture Exercise:**
1. Start capture on your network interface
2. Open a web browser and visit http://example.com
3. Stop capture

**Analysis Questions:**
1. Find the DNS query for example.com
   - What's the query type?
   - What's the response?

2. Find the TCP 3-way handshake
   - Identify SYN, SYN-ACK, ACK packets
   - What are the port numbers?

3. Find the HTTP GET request
   - What's the User-Agent?
   - What's the Host header?

4. Find the HTTP response
   - What's the status code?
   - What's the Content-Type?

### Task 2: Capture Filters
Practice using capture filters:

```
# Capture only HTTP traffic
tcp port 80

# Capture traffic to/from specific IP
host 192.168.1.100

# Capture DNS traffic
udp port 53

# Capture traffic on subnet
net 192.168.1.0/24
```

Create filters for:
1. Only HTTPS traffic
2. Traffic between your PC and gateway
3. All ICMP traffic
4. SSH connections

### Task 3: Display Filters
Apply display filters in Wireshark:

```
# Show only HTTP
http

# Show specific IP
ip.addr == 192.168.1.100

# Show TCP errors
tcp.analysis.flags

# Show DNS queries
dns.flags.response == 0
```

Find in your capture:
1. All packets to/from google.com
2. All TCP retransmissions
3. All ARP requests
4. All packets larger than 1000 bytes

### Task 4: Protocol Analysis
Analyze captured traffic:

**TCP Analysis:**
- Identify connection establishment
- Find data transfer
- Locate connection termination (FIN)
- Any retransmissions?

**HTTP Analysis:**
- Request methods (GET, POST)
- Response codes
- Headers
- Cookies

**DNS Analysis:**
- Query types
- Response times
- Cached vs non-cached

### Task 5: Troubleshooting with Packet Capture
**Scenario:** User reports intermittent connection drops

Capture traffic and analyze:
1. What to look for?
   - TCP retransmissions
   - Duplicate ACKs
   - Connection resets
   - High latency

2. How to identify the problem?
3. What metrics to check?

### Task 6: tcpdump (Command-Line Alternative)
Use tcpdump for packet capture:

```bash
# Capture on interface
sudo tcpdump -i eth0

# Save to file
sudo tcpdump -i eth0 -w capture.pcap

# Read from file
tcpdump -r capture.pcap

# Filter examples
sudo tcpdump host 192.168.1.1
sudo tcpdump port 80
sudo tcpdump icmp
```

Capture and analyze:
1. All traffic to/from your gateway
2. All DNS queries
3. All SSH traffic

## Expected Outcomes
- Capture network traffic
- Apply filters effectively
- Analyze protocols in detail
- Troubleshoot using packet analysis
- Use both GUI and CLI tools

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 2 - Filters:**
1. tcp port 443
2. host 192.168.1.1
3. icmp
4. tcp port 22

**Task 3 - Display Filters:**
1. ip.addr == [google-ip]
2. tcp.analysis.retransmission
3. arp.opcode == 1
4. frame.len > 1000

**Task 5:**
Look for:
- High number of retransmissions (network issues)
- RST packets (connection resets)
- Duplicate ACKs (packet loss)
- Increasing RTT (latency issues)
- ARP failures (Layer 2 issues)
</details>
