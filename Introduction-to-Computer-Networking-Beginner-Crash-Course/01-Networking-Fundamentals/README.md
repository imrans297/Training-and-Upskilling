# 01. Networking Fundamentals

## What is a Network?
A computer network is a collection of interconnected devices that can communicate and share resources.

## Network Types

### LAN (Local Area Network)
- Small geographic area (home, office, building)
- High speed, low latency
- Example: Office network, home WiFi

### WAN (Wide Area Network)
- Large geographic area (cities, countries)
- Lower speed, higher latency
- Example: Internet, corporate networks across cities

### MAN (Metropolitan Area Network)
- City-wide network
- Between LAN and WAN in size
- Example: City government network

## Network Topologies

### Bus Topology
- Single cable connects all devices
- Simple but single point of failure

### Star Topology
- All devices connect to central hub/switch
- Most common in modern networks
- Easy to troubleshoot

### Ring Topology
- Devices connected in circular fashion
- Data travels in one direction

### Mesh Topology
- Every device connects to every other device
- Highly redundant and reliable
- Expensive to implement

## Network Devices

### Hub
- Layer 1 device (Physical layer)
- Broadcasts data to all ports
- No intelligence, causes collisions
- **Obsolete** - replaced by switches

### Switch
- Layer 2 device (Data Link layer)
- Forwards data only to destination port
- Uses MAC addresses
- Reduces collisions, improves performance

### Router
- Layer 3 device (Network layer)
- Connects different networks
- Uses IP addresses
- Makes routing decisions

### Modem
- Modulates/demodulates signals
- Converts digital to analog and vice versa
- Connects to ISP

### Firewall
- Security device
- Filters traffic based on rules
- Can be hardware or software

## Key Concepts

### Bandwidth
- Maximum data transfer rate
- Measured in bps, Kbps, Mbps, Gbps

### Latency
- Time delay in data transmission
- Measured in milliseconds (ms)

### Throughput
- Actual data transfer rate
- Usually less than bandwidth

### Packet
- Unit of data transmitted over network
- Contains header and payload

## Real-World Example
```
Home Network Setup:
Internet → Modem → Router → Switch → Devices
                      ↓
                   WiFi AP → Wireless Devices
```

## Next Steps
Move to Labs to practice identifying network devices and topologies.
