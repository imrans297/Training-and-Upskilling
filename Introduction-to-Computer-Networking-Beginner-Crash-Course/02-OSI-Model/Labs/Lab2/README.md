# Lab 2: Data Encapsulation Process

## Objective
Understand how data is encapsulated as it moves down the OSI layers.

## Tasks

### Task 1: Encapsulation Steps
Fill in the blanks for the encapsulation process:

1. Application Layer: User data → _______
2. Transport Layer: Data + TCP/UDP header → _______
3. Network Layer: Segment + IP header → _______
4. Data Link Layer: Packet + MAC header/trailer → _______
5. Physical Layer: Frame → _______

### Task 2: Header Analysis
For each layer, list what information is added:

**Layer 4 (Transport):**
- Source Port: ?
- Destination Port: ?
- Other: ?

**Layer 3 (Network):**
- Source IP: ?
- Destination IP: ?
- Other: ?

**Layer 2 (Data Link):**
- Source MAC: ?
- Destination MAC: ?
- Other: ?

### Task 3: Sending an Email
Trace the encapsulation process for sending an email:

**Given:**
- Your IP: 192.168.1.100
- Your MAC: AA:BB:CC:DD:EE:01
- Mail Server IP: 74.125.224.108
- Gateway MAC: AA:BB:CC:DD:EE:FF
- Protocol: SMTP (port 25)

Show the headers added at each layer.

### Task 4: De-encapsulation
Explain what happens when the destination receives the data. Describe the de-encapsulation process from Physical to Application layer.

## Expected Outcomes
- Understand encapsulation/de-encapsulation
- Identify header information at each layer
- Trace complete data flow

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
1. Data
2. Segment
3. Packet
4. Frame
5. Bits

**Task 4:**
De-encapsulation reverses the process:
1. Physical → Bits to Frame
2. Data Link → Remove MAC header, pass Packet up
3. Network → Remove IP header, pass Segment up
4. Transport → Remove TCP/UDP header, pass Data up
5. Application → Process data
</details>
