# 08. Troubleshooting & Tools

## Network Troubleshooting Methodology

### Step-by-Step Process
1. **Identify the problem**: Gather information
2. **Establish theory**: Probable cause
3. **Test theory**: Verify hypothesis
4. **Create action plan**: Solution steps
5. **Implement solution**: Fix the issue
6. **Verify functionality**: Test thoroughly
7. **Document**: Record findings and solution

## Essential Network Commands

### ping
Tests connectivity to host

```bash
# Basic ping
ping google.com
ping 8.8.8.8

# Ping with count
ping -c 4 google.com  # Linux/Mac
ping -n 4 google.com  # Windows

# Continuous ping
ping -t google.com  # Windows
ping google.com     # Linux/Mac (Ctrl+C to stop)
```

**What it shows**:
- Host reachability
- Round-trip time (latency)
- Packet loss

### traceroute / tracert
Shows path packets take to destination

```bash
# Linux/Mac
traceroute google.com

# Windows
tracert google.com
```

**What it shows**:
- Each hop (router) along path
- Latency at each hop
- Where connection fails

### nslookup
Queries DNS records

```bash
# Basic lookup
nslookup google.com

# Specific DNS server
nslookup google.com 8.8.8.8

# Specific record type
nslookup -type=MX google.com
nslookup -type=NS google.com
```

**What it shows**:
- IP address for hostname
- DNS server used
- DNS records

### dig (Linux/Mac)
Advanced DNS lookup

```bash
# Basic query
dig google.com

# Specific record
dig google.com MX
dig google.com AAAA

# Reverse lookup
dig -x 8.8.8.8

# Trace DNS path
dig +trace google.com
```

### ipconfig / ifconfig
Display network configuration

```bash
# Windows
ipconfig
ipconfig /all          # Detailed info
ipconfig /release      # Release DHCP
ipconfig /renew        # Renew DHCP
ipconfig /flushdns     # Clear DNS cache

# Linux
ifconfig
ifconfig eth0          # Specific interface
ip addr show           # Modern alternative
ip link show           # Link status
```

**What it shows**:
- IP address, subnet mask, gateway
- MAC address
- DHCP server
- DNS servers

### netstat
Network statistics and connections

```bash
# Active connections
netstat -a            # All connections
netstat -an           # Numeric format
netstat -r            # Routing table
netstat -s            # Statistics

# Listening ports
netstat -l            # Linux
netstat -an | find "LISTENING"  # Windows
```

**What it shows**:
- Active connections
- Listening ports
- Routing table
- Protocol statistics

### arp
View/modify ARP cache

```bash
# View ARP table
arp -a

# Clear ARP cache
arp -d *              # Windows
sudo ip -s -s neigh flush all  # Linux
```

**What it shows**:
- IP to MAC address mappings
- Local network devices

### route
View/modify routing table

```bash
# View routes
route print           # Windows
route -n              # Linux
ip route show         # Linux (modern)

# Add route
route add 192.168.2.0 mask 255.255.255.0 192.168.1.1
```

### telnet
Test port connectivity

```bash
# Test if port is open
telnet google.com 80
telnet 192.168.1.1 22
```

**Use**: Check if service is listening on port

### curl / wget
Test HTTP/HTTPS connectivity

```bash
# Fetch webpage
curl https://google.com
wget https://google.com

# Headers only
curl -I https://google.com

# Verbose output
curl -v https://google.com
```

### ss (Socket Statistics)
Modern alternative to netstat

```bash
# All connections
ss -a

# Listening ports
ss -l

# TCP connections
ss -t

# UDP connections
ss -u

# Process info
ss -p
```

## Advanced Tools

### Wireshark
Packet capture and analysis
- **GUI tool**
- Captures all network traffic
- Deep packet inspection
- Protocol analysis

### tcpdump
Command-line packet capture

```bash
# Capture on interface
sudo tcpdump -i eth0

# Save to file
sudo tcpdump -i eth0 -w capture.pcap

# Filter by host
sudo tcpdump host 192.168.1.1

# Filter by port
sudo tcpdump port 80
```

### nmap
Network scanner

```bash
# Scan host
nmap 192.168.1.1

# Scan network
nmap 192.168.1.0/24

# Port scan
nmap -p 1-1000 192.168.1.1

# OS detection
nmap -O 192.168.1.1
```

### mtr
Combines ping and traceroute

```bash
# Real-time path analysis
mtr google.com
```

### iperf
Network performance testing

```bash
# Server
iperf -s

# Client
iperf -c 192.168.1.100
```

## Common Issues & Solutions

### No Internet Connection
1. Check physical connection
2. `ping 127.0.0.1` (loopback)
3. `ping` default gateway
4. `ping 8.8.8.8` (external IP)
5. `ping google.com` (DNS)

### Slow Network
1. Check bandwidth usage
2. Test with `iperf`
3. Check for packet loss (`ping`)
4. Analyze with Wireshark

### DNS Issues
1. `nslookup` to test DNS
2. Try different DNS server
3. `ipconfig /flushdns`
4. Check DNS configuration

### Can't Reach Specific Host
1. `ping` host
2. `traceroute` to find where it fails
3. Check firewall rules
4. Verify routing

## Troubleshooting Checklist

### Layer 1 (Physical)
- [ ] Cables connected?
- [ ] Link lights on?
- [ ] Port enabled?

### Layer 2 (Data Link)
- [ ] Correct VLAN?
- [ ] MAC address correct?
- [ ] Switch port configured?

### Layer 3 (Network)
- [ ] IP address assigned?
- [ ] Subnet mask correct?
- [ ] Default gateway set?
- [ ] Can ping gateway?

### Layer 4 (Transport)
- [ ] Port open?
- [ ] Firewall blocking?
- [ ] Service running?

### Layer 7 (Application)
- [ ] DNS resolving?
- [ ] Application configured?
- [ ] Credentials correct?

## Next Steps
Practice using these tools in real scenarios in the Labs.
