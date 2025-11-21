# Lab 3: Dynamic Routing Protocols

## Objective
Understand dynamic routing protocols and their characteristics.

## Tasks

### Task 1: Protocol Comparison
Create comparison table:

| Feature | RIP | OSPF | EIGRP | BGP |
|---------|-----|------|-------|-----|
| Type | ? | ? | ? | ? |
| Metric | ? | ? | ? | ? |
| Max Hops | ? | ? | ? | ? |
| Convergence | ? | ? | ? | ? |
| Use Case | ? | ? | ? | ? |

### Task 2: Routing Protocol Selection
Choose appropriate protocol for each scenario:

**Scenario A:** Small office
- 3 routers
- Simple topology
- Limited IT staff

Protocol: ?
Reason: ?

**Scenario B:** Enterprise network
- 50+ routers
- Hierarchical design
- Fast convergence needed

Protocol: ?
Reason: ?

**Scenario C:** ISP network
- Connects to multiple ISPs
- Policy-based routing needed
- Internet-scale

Protocol: ?
Reason: ?

### Task 3: OSPF Areas
Design OSPF area structure:

**Network:**
- Headquarters: 20 routers
- Branch 1: 5 routers
- Branch 2: 5 routers
- Branch 3: 5 routers

Create area design:
- Area 0 (Backbone): ?
- Area 1: ?
- Area 2: ?
- Area 3: ?

### Task 4: Administrative Distance
Given multiple routes to 10.0.0.0/8:
- Connected: 10.0.0.1
- Static: via 192.168.1.1
- OSPF: via 192.168.1.2
- RIP: via 192.168.1.3

Which route is preferred? Why?

### Task 5: Troubleshooting
**Problem:** OSPF neighbors not forming

Check:
1. ?
2. ?
3. ?
4. ?

## Expected Outcomes
- Compare routing protocols
- Select appropriate protocol
- Understand OSPF areas
- Troubleshoot routing protocols

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
- RIP: Distance Vector, Hop Count, 15, Slow, Small networks
- OSPF: Link State, Cost, None, Fast, Enterprise
- EIGRP: Hybrid, Composite, 255, Fast, Cisco networks
- BGP: Path Vector, Path attributes, None, Slow, Internet/ISP

**Task 2:**
- Scenario A: RIP (simple, easy to configure)
- Scenario B: OSPF (scalable, fast convergence)
- Scenario C: BGP (policy control, inter-AS routing)

**Task 3:**
- Area 0: Headquarters core routers
- Area 1: Branch 1 routers
- Area 2: Branch 2 routers
- Area 3: Branch 3 routers

**Task 4:**
Connected (AD=0) is preferred. Order: Connected > Static > OSPF > RIP

**Task 5:**
1. Check interface status (up/up)
2. Verify same area ID
3. Check hello/dead timers match
4. Verify authentication settings
</details>
