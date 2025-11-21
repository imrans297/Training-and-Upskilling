# Lab 1: DNS Queries and Record Types

## Objective
Perform DNS queries and understand different DNS record types.

## Tasks

### Task 1: Basic DNS Queries
Use nslookup or dig to query:

```bash
# Query A record
nslookup google.com
dig google.com A

# Query MX record
nslookup -type=MX gmail.com
dig gmail.com MX

# Query NS record
nslookup -type=NS amazon.com
dig amazon.com NS
```

Record the results for each query.

### Task 2: DNS Record Types
Match each record type with its purpose:

**Record Types:** A, AAAA, CNAME, MX, NS, TXT, PTR

**Purposes:**
1. IPv4 address
2. IPv6 address
3. Mail server
4. Alias/canonical name
5. Nameserver
6. Reverse lookup
7. Text information

### Task 3: DNS Hierarchy
Trace the DNS resolution for www.example.com:

1. Root server returns: ?
2. TLD server returns: ?
3. Authoritative server returns: ?

### Task 4: DNS Troubleshooting

**Scenario A:**
User can ping 8.8.8.8 but can't access www.google.com

Diagnosis steps:
1. ?
2. ?
3. ?

**Scenario B:**
DNS queries are very slow

Possible causes:
1. ?
2. ?
3. ?

## Expected Outcomes
- Perform DNS queries using command-line tools
- Understand DNS record types
- Troubleshoot DNS issues

## Answers
<details>
<summary>Click to reveal answers</summary>

**Task 2:**
1. A, 2. AAAA, 3. MX, 4. CNAME, 5. NS, 6. PTR, 7. TXT

**Task 3:**
1. .com TLD nameserver
2. example.com authoritative nameserver
3. IP address for www.example.com

**Task 4 - Scenario A:**
1. Test DNS: nslookup google.com
2. Try different DNS server: nslookup google.com 8.8.8.8
3. Check DNS settings, flush DNS cache
</details>
