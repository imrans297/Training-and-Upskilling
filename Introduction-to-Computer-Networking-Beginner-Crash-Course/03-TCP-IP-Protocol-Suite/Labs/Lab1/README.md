# Lab 1: TCP vs UDP

## Objective
Understand the differences between TCP and UDP protocols.

## Tasks

### Task 1: Protocol Selection
For each application, choose TCP or UDP and explain why:

1. Web browsing (HTTP/HTTPS)
2. Video streaming (YouTube)
3. File transfer (FTP)
4. Online gaming
5. Email (SMTP)
6. Voice call (VoIP)
7. DNS query
8. Remote desktop (RDP)

### Task 2: TCP 3-Way Handshake
Draw and label the TCP 3-way handshake process:
- Client and Server
- SYN, SYN-ACK, ACK packets
- Sequence numbers

### Task 3: Scenario Analysis

**Scenario A:** Video Conference
- Requirements: Real-time, some packet loss acceptable
- Which protocol? Why?

**Scenario B:** Bank Transaction
- Requirements: Data integrity critical, no loss acceptable
- Which protocol? Why?

**Scenario C:** Live Sports Streaming
- Requirements: Speed important, occasional glitch acceptable
- Which protocol? Why?

### Task 4: Port Numbers
Match common services with their port numbers:
- HTTP: ?
- HTTPS: ?
- FTP: ?
- SSH: ?
- DNS: ?
- SMTP: ?

## Expected Outcomes
- Choose appropriate protocol for applications
- Understand TCP reliability vs UDP speed
- Recognize common port numbers

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 1:**
1. TCP - Reliability needed
2. UDP - Speed over reliability
3. TCP - No data loss acceptable
4. UDP - Low latency critical
5. TCP - Message integrity important
6. UDP - Real-time communication
7. UDP - Fast, small queries
8. TCP - Accurate screen updates needed

**Task 4:**
HTTP: 80, HTTPS: 443, FTP: 21, SSH: 22, DNS: 53, SMTP: 25
</details>
