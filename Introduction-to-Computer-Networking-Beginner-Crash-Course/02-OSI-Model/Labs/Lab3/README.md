# Lab 3: Troubleshooting with OSI Model

## Objective
Use the OSI model to systematically troubleshoot network issues.

## Tasks

### Task 1: Layer-by-Layer Troubleshooting
For each problem, identify which OSI layer(s) to check:

1. "I can't access any websites"
2. "My computer shows 'No network cable connected'"
3. "I can ping IP addresses but can't browse websites"
4. "My computer has an IP address but can't reach the gateway"
5. "Websites load but images don't appear"

### Task 2: Troubleshooting Scenarios

**Scenario A:**
User reports: "Internet is down"
- Computer has IP: 192.168.1.50
- Can ping: 127.0.0.1 ✓
- Can ping: 192.168.1.1 (gateway) ✗
- Link light: ON

Which layers should you check? What's likely wrong?

**Scenario B:**
User reports: "Can't send emails"
- Can browse websites ✓
- Can ping mail server ✓
- Email client shows "Connection refused"

Which layers should you check? What's likely wrong?

**Scenario C:**
User reports: "Network is very slow"
- Can access all resources ✓
- High latency on ping
- Frequent packet loss

Which layers should you check? What could be wrong?

### Task 3: Create Troubleshooting Checklist
Create a systematic troubleshooting checklist starting from Layer 1:

**Layer 1 (Physical):**
- [ ] Check 1
- [ ] Check 2

**Layer 2 (Data Link):**
- [ ] Check 1
- [ ] Check 2

(Continue for all layers)

## Expected Outcomes
- Apply OSI model to troubleshooting
- Systematic problem-solving approach
- Identify layer-specific issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
1. Layers 3-7 (could be routing, DNS, application)
2. Layer 1 (Physical)
3. Layer 7 (DNS issue)
4. Layer 2 or 3 (switching/routing)
5. Layer 7 (Application/HTTP)

**Task 2:**
- Scenario A: Layer 2/3 - Check switch port, VLAN, routing
- Scenario B: Layer 7 - Check email service, port 25/587, firewall
- Scenario C: Layer 1/2 - Check cables, switch ports, collisions
</details>
