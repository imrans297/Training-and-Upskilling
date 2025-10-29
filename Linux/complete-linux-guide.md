# Complete Linux Training Guide - Theory to Hands-On Practice

## Table of Contents
1. [What is Linux?](#what-is-linux)
2. [Linux Kernel](#linux-kernel)
3. [File System Structure](#file-system-structure)
4. [Command Categories](#command-categories)
5. [Hands-On Practice Exercises](#hands-on-practice-exercises)
6. [Bash Scripting](#bash-scripting)
7. [Real-World Projects](#real-world-projects)

---

## What is Linux?

### Definition
Linux is a **free and open-source operating system** based on Unix, created by Linus Torvalds in 1991.

### Key Features
- **Open Source**: Source code freely available
- **Multi-user**: Multiple users simultaneously
- **Multi-tasking**: Multiple processes at once
- **Secure**: Built-in security and permissions
- **Stable**: High reliability and uptime

### Linux vs Others
| Feature | Linux | Windows | macOS |
|---------|-------|---------|-------|
| Cost | Free | Paid | Paid |
| Customization | High | Medium | Low |
| Security | High | Medium | High |

---

## Linux Kernel

### What is the Kernel?
The kernel is the core of Linux that manages hardware and system resources.

### Kernel Functions
- **Process Management**: Handle running programs
- **Memory Management**: Manage RAM and storage
- **File System**: Handle files and directories
- **Device Drivers**: Control hardware
- **Network Stack**: Manage network connections

### Check Kernel Information
```bash
uname -r        # Kernel version
uname -a        # Complete system info
lsmod          # Loaded kernel modules
dmesg          # Kernel messages
```

---

## File System Structure

```
/                    # Root directory
├── bin/            # Essential commands (ls, cp, mv)
├── boot/           # Boot files
├── dev/            # Device files
├── etc/            # Configuration files
├── home/           # User directories
├── lib/            # System libraries
├── tmp/            # Temporary files
├── usr/            # User programs
└── var/            # Variable data (logs)
```

---

## Command Categories

## 1. FUNDAMENTAL COMMANDS

### System Information
```bash
# Basic identity and system info
whoami                          # Current username
id                             # User and group IDs
hostname                       # Computer name
uname -a                       # System information
uptime                         # System uptime
date                           # Current date/time
cal                            # Calendar
```

**Hands-On Exercise 1:**
```bash
# Run this complete system check
echo "=== System Information ==="
echo "User: $(whoami)"
echo "Hostname: $(hostname)"
echo "System: $(uname -s)"
echo "Kernel: $(uname -r)"
echo "Date: $(date)"
echo "System uptime: $(uptime)"
```
**Screenshot this output for your documentation**

### Navigation Basics
```bash
# Directory navigation
pwd                            # Show current directory
ls                             # List files
ls -l                          # Detailed list
ls -la                         # Include hidden files
cd /path/to/directory          # Change directory
cd ~                           # Go home
cd ..                          # Go up one level
cd -                           # Go to previous directory
```

**Hands-On Exercise 2:**
```bash
# Navigation practice
echo "=== Navigation Practice ==="
pwd
echo "Home directory contents:"
ls -la ~
echo "Root directory structure:"
ls -l /
echo "Current location after cd /tmp:"
cd /tmp && pwd
echo "Back to home:"
cd ~ && pwd
```
**Screenshot this navigation sequence**

## 2. BASIC COMMANDS

### File Operations
```bash
# File and directory management
touch filename                 # Create empty file
mkdir dirname                  # Create directory
mkdir -p path/to/dir           # Create nested directories
cp source destination          # Copy file
cp -r source destination       # Copy directory
mv source destination          # Move/rename
rm filename                    # Delete file
rm -r dirname                  # Delete directory
rmdir dirname                  # Remove empty directory
```

**Hands-On Exercise 3:**
```bash
# Complete file management workflow
cd ~
mkdir -p linux_practice/{docs,scripts,backups}
cd linux_practice

echo "=== File Management Practice ==="
echo "Created directory structure:"
ls -la

# Create sample files
echo "This is a sample document" > docs/readme.txt
echo "#!/bin/bash" > scripts/hello.sh
echo "echo 'Hello Linux!'" >> scripts/hello.sh

echo "Files created:"
ls -la docs/
ls -la scripts/

# Copy and move operations
cp docs/readme.txt backups/
mv backups/readme.txt backups/readme_backup.txt
echo "Backup operations:"
ls -la backups/

# File permissions
chmod +x scripts/hello.sh
echo "Script permissions:"
ls -la scripts/hello.sh
```
**Screenshot this complete workflow**

### File Viewing and Content
```bash
# View file contents
cat filename                   # Display entire file
head filename                  # First 10 lines
head -n 5 filename            # First 5 lines
tail filename                  # Last 10 lines
tail -f filename              # Follow file changes
less filename                  # Page through file
more filename                  # Page through file
```

**Hands-On Exercise 4:**
```bash
# Create sample data and practice viewing
cd ~/linux_practice

# Create multi-line file
seq 1 50 > docs/numbers.txt
echo -e "apple,red,sweet\nbanana,yellow,sweet\ngrape,purple,sour\norange,orange,citrus" > docs/fruits.csv

echo "=== File Viewing Practice ==="
echo "First 10 numbers:"
head docs/numbers.txt

echo "Last 5 numbers:"
tail -n 5 docs/numbers.txt

echo "Fruit data:"
cat docs/fruits.csv

echo "File information:"
wc -l docs/numbers.txt
wc -w docs/fruits.csv
```
**Screenshot these file viewing operations**

## 3. INTERMEDIATE COMMANDS

### Text Processing
```bash
# Search and process text
grep "pattern" filename        # Search for text
grep -i "pattern" filename     # Case-insensitive search
grep -v "pattern" filename     # Exclude pattern
grep -c "pattern" filename     # Count matches
sed 's/old/new/g' filename     # Replace text
awk '{print $1}' filename      # Print first column
sort filename                  # Sort lines
uniq filename                  # Remove duplicates
cut -d',' -f1 filename         # Extract CSV field
```

**Hands-On Exercise 5:**
```bash
# Advanced text processing
cd ~/linux_practice

# Create sample log file
cat << EOF > docs/system.log
2023-12-18 10:30:15 INFO System started
2023-12-18 10:31:20 ERROR Database connection failed
2023-12-18 10:32:10 INFO User login successful
2023-12-18 10:33:05 ERROR File not found
2023-12-18 10:34:15 WARNING Low disk space
2023-12-18 10:35:20 INFO Backup completed
EOF

echo "=== Text Processing Practice ==="
echo "Total log entries:"
wc -l docs/system.log

echo "Error messages:"
grep "ERROR" docs/system.log

echo "Non-error messages:"
grep -v "ERROR" docs/system.log

echo "Log levels count:"
awk '{print $3}' docs/system.log | sort | uniq -c

echo "Fruit processing:"
echo "Fruit names only:"
cut -d',' -f1 docs/fruits.csv

echo "Sorted fruits:"
sort docs/fruits.csv
```
**Screenshot this text processing session**

### Process Management
```bash
# Manage running processes
ps                             # Current processes
ps aux                         # All processes detailed
top                            # Dynamic process view
htop                           # Enhanced process viewer
jobs                           # Active jobs
bg                             # Background job
fg                             # Foreground job
kill PID                       # Kill process
killall name                   # Kill by name
pgrep name                     # Find process ID
```

**Hands-On Exercise 6:**
```bash
echo "=== Process Management Practice ==="
echo "Current processes:"
ps

echo "Starting background jobs:"
sleep 30 &
job1_pid=$!
sleep 45 &
job2_pid=$!

echo "Active jobs:"
jobs

echo "Process details:"
ps aux | grep sleep | grep -v grep

echo "Killing first job:"
kill $job1_pid
sleep 2
echo "Remaining jobs:"
jobs

# Clean up
kill $job2_pid 2>/dev/null
```
**Screenshot this process management demo**

### System Monitoring
```bash
# Monitor system resources
free -h                        # Memory usage
df -h                          # Disk usage
du -h directory               # Directory size
lscpu                          # CPU information
lsblk                          # Block devices
iostat                         # I/O statistics
vmstat                         # Virtual memory stats
```

**Hands-On Exercise 7:**
```bash
echo "=== System Monitoring ==="
echo "Memory usage:"
free -h

echo "Disk usage:"
df -h

echo "CPU information:"
lscpu | head -10

echo "Current directory size:"
du -sh ~/linux_practice

echo "Top memory processes:"
ps aux --sort=-%mem | head -5

echo "System uptime and load:"
uptime
```
**Screenshot this system monitoring output**

## 4. ADVANCED COMMANDS

### File Permissions and Security
```bash
# Advanced permission management
chmod 755 filename             # rwxr-xr-x permissions
chmod u+rwx,g+rx,o+rx filename # Same as above
chmod -R 644 directory/        # Recursive permission change
chown user:group filename      # Change ownership
chgrp group filename           # Change group only
umask 022                      # Set default permissions
getfacl filename               # Get file ACL
setfacl -m u:user:rwx filename # Set ACL for user
```

**Hands-On Exercise 8:**
```bash
cd ~/linux_practice

echo "=== File Permissions and Security ==="

# Create test files with different permissions
touch security_demo.txt
echo "Sensitive data here" > security_demo.txt

echo "Original permissions:"
ls -l security_demo.txt

# Demonstrate different permission settings
echo "Setting read-only for all:"
chmod 444 security_demo.txt
ls -l security_demo.txt

echo "Setting full access for owner only:"
chmod 600 security_demo.txt
ls -l security_demo.txt

echo "Setting executable script permissions:"
chmod 755 security_demo.txt
ls -l security_demo.txt

# Demonstrate ownership (if you have sudo access)
echo "Current ownership:"
stat security_demo.txt | grep -E "(Uid|Gid)"

# Create directory with specific permissions
mkdir -p secure_folder
chmod 700 secure_folder
echo "Secure folder permissions:"
ls -ld secure_folder

# Demonstrate umask
echo "Current umask:"
umask
echo "Creating file with current umask:"
touch test_umask.txt
ls -l test_umask.txt
```
**Screenshot this permissions demonstration**

### Advanced File Operations
```bash
# Links and advanced file operations
ln -s target linkname          # Create symbolic link
ln target linkname             # Create hard link
readlink linkname              # Show link target
find /path -type l             # Find symbolic links
find /path -links +1           # Find files with multiple hard links
lsattr filename                # List file attributes
chattr +i filename             # Make file immutable
```

**Hands-On Exercise 9:**
```bash
cd ~/linux_practice

echo "=== Advanced File Operations ==="

# Create original file
echo "This is the original file content" > docs/original.txt

# Create symbolic link
ln -s docs/original.txt docs/symbolic_link.txt
echo "Symbolic link created:"
ls -la docs/ | grep link

# Create hard link
ln docs/original.txt docs/hard_link.txt
echo "Hard link created:"
ls -li docs/original.txt docs/hard_link.txt

# Demonstrate link behavior
echo "Adding content to original file:"
echo "Additional content" >> docs/original.txt

echo "Content via symbolic link:"
cat docs/symbolic_link.txt

echo "Content via hard link:"
cat docs/hard_link.txt

# Show link information
echo "Link details:"
readlink docs/symbolic_link.txt
file docs/symbolic_link.txt
file docs/hard_link.txt

# Find all links to the original file
echo "Finding all links to original file:"
find . -samefile docs/original.txt

# Demonstrate what happens when original is deleted
echo "Removing original file:"
rm docs/original.txt

echo "Symbolic link after original deletion:"
ls -la docs/symbolic_link.txt
cat docs/symbolic_link.txt 2>&1 || echo "Symbolic link broken"

echo "Hard link after original deletion:"
cat docs/hard_link.txt
```
**Screenshot this links demonstration**

### Network Operations
```bash
# Network testing and operations
ping -c 3 hostname            # Test connectivity
ping6 -c 3 hostname           # IPv6 ping
traceroute hostname           # Trace network path
wget URL                      # Download file
wget -c URL                   # Continue partial download
curl URL                      # Transfer data
curl -O URL                   # Download and save
curl -I URL                   # Get headers only
netstat -tuln                 # Network connections
ss -tuln                      # Modern netstat alternative
ss -tulpn                     # Include process names
nmap localhost                # Port scan (if available)
```

**Hands-On Exercise 10:**
```bash
echo "=== Network Operations ==="

# Basic connectivity tests
echo "Testing connectivity to Google DNS:"
ping -c 3 8.8.8.8

echo "Testing connectivity to Google:"
ping -c 3 google.com

# DNS resolution
echo "DNS resolution test:"
nslookup google.com
dig google.com 2>/dev/null || echo "dig not available"

# Download operations
echo "Download test:"
wget -O /tmp/test_download.html https://httpbin.org/html 2>/dev/null
echo "Downloaded file info:"
ls -la /tmp/test_download.html
echo "File type:"
file /tmp/test_download.html

# HTTP operations with curl
echo "HTTP headers test:"
curl -I https://httpbin.org/get

echo "JSON API test:"
curl -s https://httpbin.org/json | head -10

# Network interface information
echo "Network interfaces:"
ip addr show | head -20

# Active network connections
echo "Active connections:"
ss -tuln | head -10

# Network statistics
echo "Network statistics:"
cat /proc/net/dev | head -5
```
**Screenshot this network testing session**

### Archive and Compression
```bash
# Create and extract archives
tar -czf archive.tar.gz dir/   # Create gzip compressed archive
tar -cjf archive.tar.bz2 dir/  # Create bzip2 compressed archive
tar -cJf archive.tar.xz dir/   # Create xz compressed archive
tar -xzf archive.tar.gz        # Extract gzip archive
tar -xjf archive.tar.bz2       # Extract bzip2 archive
tar -xJf archive.tar.xz        # Extract xz archive
tar -tzf archive.tar.gz        # List gzip archive contents
zip -r archive.zip dir/        # Create zip archive
unzip archive.zip              # Extract zip archive
unzip -l archive.zip           # List zip contents
gzip filename                  # Compress single file
bzip2 filename                 # Better compression
xz filename                    # Best compression
gunzip filename.gz             # Decompress gzip
bunzip2 filename.bz2           # Decompress bzip2
unxz filename.xz               # Decompress xz
```

**Hands-On Exercise 11:**
```bash
cd ~/linux_practice

echo "=== Archive and Compression Operations ==="

# Create test data for compression
echo "Creating test data for compression:"
seq 1 1000 > docs/large_numbers.txt
cp docs/large_numbers.txt docs/numbers_copy.txt
echo "Test data created:"
ls -lh docs/large_numbers.txt

# Test different compression methods
echo "Testing different compression methods:"

# Gzip compression
echo "Gzip compression:"
tar -czf backup_gzip.tar.gz docs/
ls -lh backup_gzip.tar.gz

# Bzip2 compression
echo "Bzip2 compression:"
tar -cjf backup_bzip2.tar.bz2 docs/
ls -lh backup_bzip2.tar.bz2

# XZ compression (best compression)
echo "XZ compression:"
tar -cJf backup_xz.tar.xz docs/
ls -lh backup_xz.tar.xz

# ZIP archive
echo "ZIP compression:"
zip -r backup.zip docs/
ls -lh backup.zip

# Compare compression ratios
echo "Compression comparison:"
original_size=$(du -sb docs/ | cut -f1)
echo "Original size: $original_size bytes"
for archive in backup_gzip.tar.gz backup_bzip2.tar.bz2 backup_xz.tar.xz backup.zip; do
    size=$(stat -f%z "$archive" 2>/dev/null || stat -c%s "$archive")
    ratio=$(echo "scale=2; $size * 100 / $original_size" | bc -l 2>/dev/null || echo "N/A")
    echo "$archive: $size bytes ($ratio% of original)"
done

# Test extraction
echo "Testing extraction:"
mkdir -p restore_test/{gzip,bzip2,xz,zip}

echo "Extracting gzip archive:"
tar -xzf backup_gzip.tar.gz -C restore_test/gzip/

echo "Extracting bzip2 archive:"
tar -xjf backup_bzip2.tar.bz2 -C restore_test/bzip2/

echo "Extracting xz archive:"
tar -xJf backup_xz.tar.xz -C restore_test/xz/

echo "Extracting zip archive:"
unzip -q backup.zip -d restore_test/zip/

echo "Verification - all extractions should be identical:"
for method in gzip bzip2 xz zip; do
    echo "$method: $(find restore_test/$method -type f | wc -l) files"
done

# Single file compression
echo "Single file compression test:"
cp docs/large_numbers.txt test_compression.txt
original_size=$(stat -f%z test_compression.txt 2>/dev/null || stat -c%s test_compression.txt)
echo "Original file: $original_size bytes"

# Test different single-file compression
cp test_compression.txt test_gzip.txt && gzip test_gzip.txt
cp test_compression.txt test_bzip2.txt && bzip2 test_bzip2.txt
cp test_compression.txt test_xz.txt && xz test_xz.txt

echo "Compressed files:"
ls -lh test_*.txt.*
```
**Screenshot this comprehensive compression demo**

### System Administration Commands
```bash
# User and group management
sudo useradd username          # Add new user
sudo usermod -aG group user    # Add user to group
sudo passwd username           # Set user password
sudo userdel username          # Delete user
sudo groupadd groupname        # Add new group
sudo groupdel groupname        # Delete group
groups username                # Show user groups
id username                    # Show user ID info
who                           # Show logged in users
w                             # Show user activity
last                          # Show login history

# Service management (systemd)
systemctl status service       # Check service status
sudo systemctl start service   # Start service
sudo systemctl stop service    # Stop service
sudo systemctl restart service # Restart service
sudo systemctl enable service  # Enable at boot
sudo systemctl disable service # Disable at boot
systemctl list-units          # List all units
systemctl --failed            # Show failed services

# Process priority and scheduling
nice -n 10 command            # Run with lower priority
renice 5 PID                  # Change process priority
nohup command &               # Run immune to hangups
screen command                # Run in detachable session
tmux new-session -d command   # Run in tmux session
```

**Hands-On Exercise 12:**
```bash
echo "=== System Administration Demo ==="

# User and group information
echo "Current user information:"
whoami
id
groups

echo "All users on system:"
cut -d: -f1 /etc/passwd | head -10

echo "System groups:"
cut -d: -f1 /etc/group | head -10

# Process management
echo "Process management demo:"
echo "Starting background processes:"
sleep 60 &
pid1=$!
nice -n 10 sleep 60 &
pid2=$!

echo "Process information:"
ps -o pid,ppid,ni,comm -p $pid1,$pid2

echo "Changing process priority:"
renice 5 $pid1
ps -o pid,ppid,ni,comm -p $pid1

# Clean up
kill $pid1 $pid2 2>/dev/null

# System service information (read-only)
echo "System services status:"
systemctl list-units --type=service --state=running | head -10

echo "Failed services (if any):"
systemctl --failed --no-pager

# System resource limits
echo "System limits:"
ulimit -a | head -10

# System information
echo "System load and processes:"
uptime
echo "Memory usage:"
free -h
echo "Disk usage:"
df -h | head -5
```
**Screenshot this system administration demo**

### Package Management (Ubuntu/Debian)
```bash
# Package operations
apt list --installed          # List installed packages
apt search package            # Search for packages
apt show package              # Show package information
sudo apt update               # Update package list
sudo apt upgrade              # Upgrade packages
sudo apt install package      # Install package
sudo apt remove package       # Remove package
sudo apt purge package        # Remove package and config
sudo apt autoremove           # Remove unnecessary packages
apt policy package            # Show package policy
dpkg -l                       # List installed packages
dpkg -L package               # List package files
dpkg -S filename              # Find package owning file
```

**Hands-On Exercise 13:**
```bash
echo "=== Package Management Demo ==="

# Note: Most commands require sudo, showing read-only operations
echo "Installed packages count:"
dpkg -l | wc -l

echo "Recently installed packages:"
grep " install " /var/log/dpkg.log | tail -5 2>/dev/null || echo "Log not accessible"

echo "Package information example (coreutils):"
apt show coreutils 2>/dev/null | head -10

echo "Files installed by coreutils package:"
dpkg -L coreutils | head -10

echo "Which package owns /bin/ls:"
dpkg -S /bin/ls

echo "Available package updates:"
apt list --upgradable 2>/dev/null | head -5

echo "Package dependencies for bash:"
apt depends bash 2>/dev/null | head -10

echo "Packages that depend on libc6:"
apt rdepends libc6 2>/dev/null | head -10
```
**Screenshot this package management demo**

---

## Hands-On Practice Exercises

### Exercise Set 1: System Exploration
```bash
#!/bin/bash
# Complete system discovery script

echo "=== LINUX SYSTEM EXPLORATION ==="
echo "Date: $(date)"
echo

echo "--- User Information ---"
echo "Current user: $(whoami)"
echo "User ID: $(id -u)"
echo "Groups: $(groups)"
echo

echo "--- System Information ---"
echo "Hostname: $(hostname)"
echo "Operating System: $(uname -o)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo

echo "--- Hardware Information ---"
echo "CPU cores: $(nproc)"
echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
echo "Disk space: $(df -h / | tail -1 | awk '{print $2}')"
echo

echo "--- File System ---"
echo "Current directory: $(pwd)"
echo "Home directory size: $(du -sh ~ 2>/dev/null | cut -f1)"
echo "Root directory contents:"
ls -la / | head -10
```
**Run this script and screenshot the complete output**

### Exercise Set 2: File System Management
```bash
#!/bin/bash
# File system management project

PROJECT_DIR="$HOME/linux_project"
mkdir -p "$PROJECT_DIR"/{src,docs,tests,logs,backups}
cd "$PROJECT_DIR"

echo "=== FILE SYSTEM MANAGEMENT PROJECT ==="

# Create project structure
echo "Creating project files..."
echo "# Project Documentation" > docs/README.md
echo "## Installation Guide" >> docs/README.md
echo "## User Manual" >> docs/README.md

cat << 'EOF' > src/main.py
#!/usr/bin/env python3
"""
Sample Python application
"""
def main():
    print("Hello, Linux World!")
    return 0

if __name__ == "__main__":
    main()
EOF

cat << 'EOF' > tests/test_main.py
#!/usr/bin/env python3
"""
Test cases for main application
"""
import unittest

class TestMain(unittest.TestCase):
    def test_basic(self):
        self.assertTrue(True)

if __name__ == "__main__":
    unittest.main()
EOF

# Create log entries
echo "$(date): Project initialized" > logs/project.log
echo "$(date): Files created" >> logs/project.log

echo "Project structure created:"
tree . 2>/dev/null || find . -type f

echo -e "\nFile details:"
find . -type f -exec ls -la {} \;

echo -e "\nSetting permissions:"
chmod +x src/main.py tests/test_main.py
ls -la src/ tests/

echo -e "\nCreating backup:"
tar -czf "backups/project_backup_$(date +%Y%m%d_%H%M%S).tar.gz" src/ docs/ tests/
ls -la backups/

echo -e "\nProject statistics:"
echo "Total files: $(find . -type f | wc -l)"
echo "Total directories: $(find . -type d | wc -l)"
echo "Project size: $(du -sh . | cut -f1)"
```
**Execute this project and screenshot each section**

### Exercise Set 3: Log Analysis Challenge
```bash
#!/bin/bash
# Log analysis and monitoring

LOG_DIR="$HOME/log_analysis"
mkdir -p "$LOG_DIR"
cd "$LOG_DIR"

# Create realistic log files
cat << 'EOF' > web_access.log
192.168.1.100 - - [18/Dec/2023:10:30:15 +0000] "GET /index.html HTTP/1.1" 200 1234
192.168.1.101 - - [18/Dec/2023:10:30:16 +0000] "GET /about.html HTTP/1.1" 200 2345
192.168.1.100 - - [18/Dec/2023:10:30:17 +0000] "POST /login HTTP/1.1" 200 567
192.168.1.102 - - [18/Dec/2023:10:30:18 +0000] "GET /products.html HTTP/1.1" 404 0
192.168.1.101 - - [18/Dec/2023:10:30:19 +0000] "GET /contact.html HTTP/1.1" 200 1890
192.168.1.103 - - [18/Dec/2023:10:30:20 +0000] "GET /admin HTTP/1.1" 403 0
192.168.1.100 - - [18/Dec/2023:10:30:21 +0000] "GET /images/logo.png HTTP/1.1" 200 45678
192.168.1.104 - - [18/Dec/2023:10:30:22 +0000] "GET /api/data HTTP/1.1" 500 0
EOF

cat << 'EOF' > application.log
2023-12-18 10:30:15 INFO Application started successfully
2023-12-18 10:30:20 INFO Database connection established
2023-12-18 10:30:25 WARNING High memory usage detected: 85%
2023-12-18 10:30:30 INFO User authentication successful: user123
2023-12-18 10:30:35 ERROR Failed to load configuration file
2023-12-18 10:30:40 INFO Configuration loaded from backup
2023-12-18 10:30:45 WARNING Disk space low: 90% used
2023-12-18 10:30:50 ERROR Database query timeout
2023-12-18 10:30:55 INFO Query retry successful
2023-12-18 10:31:00 INFO Backup process started
EOF

echo "=== LOG ANALYSIS CHALLENGE ==="

echo "1. Web Access Log Analysis:"
echo "   Total requests: $(wc -l < web_access.log)"
echo "   Unique IP addresses:"
awk '{print $1}' web_access.log | sort | uniq
echo "   HTTP status codes:"
awk '{print $9}' web_access.log | sort | uniq -c
echo "   Most requested files:"
awk '{print $7}' web_access.log | sort | uniq -c | sort -nr
echo "   Error requests (4xx, 5xx):"
awk '$9 >= 400 {print $0}' web_access.log

echo -e "\n2. Application Log Analysis:"
echo "   Total log entries: $(wc -l < application.log)"
echo "   Log level distribution:"
awk '{print $3}' application.log | sort | uniq -c
echo "   Error messages:"
grep "ERROR" application.log
echo "   Warning messages:"
grep "WARNING" application.log
echo "   Time range:"
echo "   First entry: $(head -1 application.log | awk '{print $1, $2}')"
echo "   Last entry: $(tail -1 application.log | awk '{print $1, $2}')"

echo -e "\n3. Combined Analysis:"
echo "   Total issues found:"
error_count=$(grep -c "ERROR" application.log)
warning_count=$(grep -c "WARNING" application.log)
http_errors=$(awk '$9 >= 400' web_access.log | wc -l)
echo "   Application errors: $error_count"
echo "   Application warnings: $warning_count"
echo "   HTTP errors: $http_errors"
echo "   Total issues: $((error_count + warning_count + http_errors))"
```
**Run this analysis and screenshot the complete results**

### Exercise Set 4: Advanced System Monitoring
```bash
#!/bin/bash
# Advanced system monitoring and performance analysis

MONITOR_DIR="$HOME/system_monitoring"
mkdir -p "$MONITOR_DIR"
cd "$MONITOR_DIR"

echo "=== ADVANCED SYSTEM MONITORING ==="
echo "Monitoring started at: $(date)"

# System information collection
echo "--- System Information ---"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo "Users logged in: $(who | wc -l)"

# CPU monitoring
echo -e "\n--- CPU Analysis ---"
echo "CPU cores: $(nproc)"
echo "CPU model: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
echo "CPU frequency: $(lscpu | grep 'CPU MHz' | cut -d: -f2 | xargs) MHz"

# Memory analysis
echo -e "\n--- Memory Analysis ---"
free -h
echo "Memory usage percentage:"
free | grep Mem | awk '{printf "Used: %.1f%% Available: %.1f%%\n", $3/$2*100, $7/$2*100}'

# Disk analysis
echo -e "\n--- Disk Analysis ---"
df -h
echo -e "\nDisk usage by directory (top 10):"
du -h / 2>/dev/null | sort -hr | head -10 2>/dev/null || echo "Permission denied for full disk analysis"

# Process analysis
echo -e "\n--- Process Analysis ---"
echo "Total processes: $(ps aux | wc -l)"
echo "Running processes: $(ps aux | grep -v 'Z' | wc -l)"
echo "Zombie processes: $(ps aux | grep 'Z' | wc -l)"

echo -e "\nTop 5 CPU consumers:"
ps aux --sort=-%cpu | head -6

echo -e "\nTop 5 Memory consumers:"
ps aux --sort=-%mem | head -6

# Network analysis
echo -e "\n--- Network Analysis ---"
echo "Network interfaces:"
ip link show | grep -E '^[0-9]+:' | awk '{print $2}' | sed 's/:$//' | tr '\n' ' '
echo

echo "Active network connections:"
ss -tuln | wc -l | xargs echo "Total connections:"
ss -tun | grep ESTAB | wc -l | xargs echo "Established connections:"

# I/O analysis
echo -e "\n--- I/O Analysis ---"
echo "Disk I/O statistics:"
iostat 1 3 2>/dev/null | tail -10 || echo "iostat not available"

# Generate performance report
echo -e "\n--- Performance Report ---"
REPORT_FILE="performance_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "=== System Performance Report ==="
    echo "Generated: $(date)"
    echo "Hostname: $(hostname)"
    echo
    echo "=== Summary ==="
    echo "CPU Cores: $(nproc)"
    echo "Total Memory: $(free -h | grep Mem | awk '{print $2}')"
    echo "Used Memory: $(free -h | grep Mem | awk '{print $3}')"
    echo "Available Memory: $(free -h | grep Mem | awk '{print $7}')"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Uptime: $(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')"
    echo
    echo "=== Top Processes ==="
    ps aux --sort=-%cpu | head -10
    echo
    echo "=== Disk Usage ==="
    df -h
    echo
    echo "=== Network Connections ==="
    ss -tuln | head -10
} > "$REPORT_FILE"

echo "Performance report saved: $REPORT_FILE"
echo "Report location: $MONITOR_DIR/$REPORT_FILE"

# System health check
echo -e "\n--- Health Check ---"
health_score=100

# Check CPU load
load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
cpu_cores=$(nproc)
if (( $(echo "$load_avg > $cpu_cores" | bc -l 2>/dev/null || echo 0) )); then
    echo "⚠️  WARNING: High CPU load ($load_avg on $cpu_cores cores)"
    health_score=$((health_score - 20))
else
    echo "✅ CPU load normal ($load_avg on $cpu_cores cores)"
fi

# Check memory usage
mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')
if [ "$mem_usage" -gt 90 ]; then
    echo "🚨 CRITICAL: Very high memory usage (${mem_usage}%)"
    health_score=$((health_score - 30))
elif [ "$mem_usage" -gt 80 ]; then
    echo "⚠️  WARNING: High memory usage (${mem_usage}%)"
    health_score=$((health_score - 15))
else
    echo "✅ Memory usage normal (${mem_usage}%)"
fi

# Check disk usage
max_disk_usage=$(df | grep -E '^/dev/' | awk '{print $5}' | sed 's/%//' | sort -nr | head -1)
if [ "$max_disk_usage" -gt 95 ]; then
    echo "🚨 CRITICAL: Very high disk usage (${max_disk_usage}%)"
    health_score=$((health_score - 25))
elif [ "$max_disk_usage" -gt 85 ]; then
    echo "⚠️  WARNING: High disk usage (${max_disk_usage}%)"
    health_score=$((health_score - 10))
else
    echo "✅ Disk usage normal (${max_disk_usage}%)"
fi

echo -e "\n=== Overall Health Score: $health_score/100 ==="
if [ "$health_score" -ge 80 ]; then
    echo "🟢 System health: GOOD"
elif [ "$health_score" -ge 60 ]; then
    echo "🟡 System health: FAIR - Monitor closely"
else
    echo "🔴 System health: POOR - Immediate attention required"
fi

echo -e "\nMonitoring completed at: $(date)"
```
**Execute this comprehensive monitoring and screenshot all sections**

### Exercise Set 5: File System Deep Dive
```bash
#!/bin/bash
# File system exploration and analysis

FS_ANALYSIS_DIR="$HOME/filesystem_analysis"
mkdir -p "$FS_ANALYSIS_DIR"
cd "$FS_ANALYSIS_DIR"

echo "=== FILE SYSTEM DEEP DIVE ==="
echo "Analysis started: $(date)"

# File system information
echo "--- File System Overview ---"
echo "Mounted filesystems:"
df -hT

echo -e "\nFile system types:"
df -T | awk 'NR>1 {print $2}' | sort | uniq -c

# Inode analysis
echo -e "\n--- Inode Analysis ---"
echo "Inode usage:"
df -i

echo -e "\nDirectories with most files:"
find /home -type f 2>/dev/null | head -1000 | xargs dirname | sort | uniq -c | sort -nr | head -10

# File type analysis
echo -e "\n--- File Type Analysis ---"
echo "File types in home directory:"
find ~ -type f -name "*.*" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -15

# Large files detection
echo -e "\n--- Large Files Detection ---"
echo "Files larger than 10MB in accessible areas:"
find ~ -type f -size +10M -exec ls -lh {} \; 2>/dev/null | head -10

# Directory size analysis
echo -e "\n--- Directory Size Analysis ---"
echo "Largest directories in home:"
du -h ~ 2>/dev/null | sort -hr | head -15

# File permissions analysis
echo -e "\n--- File Permissions Analysis ---"
echo "Executable files in home directory:"
find ~ -type f -executable 2>/dev/null | wc -l | xargs echo "Total executable files:"

echo "World-writable files (security check):"
find ~ -type f -perm -002 2>/dev/null | head -5

echo "Files with special permissions:"
find ~ -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -5

# Symbolic links analysis
echo -e "\n--- Symbolic Links Analysis ---"
echo "Symbolic links in home directory:"
find ~ -type l 2>/dev/null | head -10

echo "Broken symbolic links:"
find ~ -type l ! -exec test -e {} \; -print 2>/dev/null | head -5

# File age analysis
echo -e "\n--- File Age Analysis ---"
echo "Recently modified files (last 24 hours):"
find ~ -type f -mtime -1 2>/dev/null | wc -l | xargs echo "Files modified today:"

echo "Old files (older than 1 year):"
find ~ -type f -mtime +365 2>/dev/null | wc -l | xargs echo "Files older than 1 year:"

# Generate file system report
REPORT_FILE="filesystem_report_$(date +%Y%m%d_%H%M%S).txt"
{
    echo "=== File System Analysis Report ==="
    echo "Generated: $(date)"
    echo "User: $(whoami)"
    echo "Home Directory: $HOME"
    echo
    echo "=== Summary Statistics ==="
    echo "Total files in home: $(find ~ -type f 2>/dev/null | wc -l)"
    echo "Total directories in home: $(find ~ -type d 2>/dev/null | wc -l)"
    echo "Total symbolic links: $(find ~ -type l 2>/dev/null | wc -l)"
    echo "Home directory size: $(du -sh ~ 2>/dev/null | cut -f1)"
    echo
    echo "=== File System Usage ==="
    df -h
    echo
    echo "=== Inode Usage ==="
    df -i
    echo
    echo "=== Largest Files ==="
    find ~ -type f -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr | head -20
} > "$REPORT_FILE"

echo -e "\nFile system analysis report saved: $REPORT_FILE"
echo "Analysis completed: $(date)"
```
**Run this file system analysis and screenshot the results**



---

## Practice Checklist

### Essential Commands to Master

#### Fundamental Level (Must Know)
- [ ] System info: `whoami`, `uname`, `hostname`, `uptime`, `date`, `cal`
- [ ] Navigation: `pwd`, `ls`, `cd`, file system exploration
- [ ] File operations: `touch`, `mkdir`, `cp`, `mv`, `rm`, `rmdir`
- [ ] File viewing: `cat`, `head`, `tail`, `less`, `more`

#### Basic Level (Should Know)
- [ ] Text processing: `grep`, `sed`, `awk`, `sort`, `cut`, `wc`, `uniq`
- [ ] File search: `find`, `locate`, `which`, `whereis`
- [ ] File info: `file`, `stat`, `du`, `df`
- [ ] Permissions: `chmod`, `chown`, `chgrp`, `umask`

#### Intermediate Level (Good to Know)
- [ ] Process management: `ps`, `top`, `htop`, `jobs`, `kill`, `killall`, `pgrep`
- [ ] System monitoring: `free`, `lscpu`, `lsblk`, `iostat`, `vmstat`
- [ ] Network: `ping`, `wget`, `curl`, `netstat`, `ss`
- [ ] Archives: `tar`, `zip`, `gzip`, `bzip2`, `xz`

#### Advanced Level (Professional)
- [ ] Advanced file ops: `ln`, `readlink`, `lsattr`, `chattr`
- [ ] System admin: `systemctl`, `useradd`, `usermod`, `passwd`
- [ ] Package management: `apt`, `dpkg` (Ubuntu/Debian)
- [ ] Performance: `lsof`, `strace`, `dmesg`, `journalctl`
- [ ] Security: ACLs, file attributes, process priorities

### Hands-On Projects Completed
- [ ] System exploration and documentation (Exercise 1)
- [ ] File system management project (Exercise 2)
- [ ] Log analysis challenge (Exercise 3)
- [ ] Advanced system monitoring (Exercise 4)
- [ ] File system deep dive (Exercise 5)
- [ ] File permissions and security demo (Exercise 8)
- [ ] Advanced file operations with links (Exercise 9)
- [ ] Network operations testing (Exercise 10)
- [ ] Comprehensive compression demo (Exercise 11)
- [ ] System administration demo (Exercise 12)
- [ ] Package management demo (Exercise 13)

### Screenshot Documentation
- [ ] System information commands (Exercise 1)
- [ ] Navigation and file operations (Exercises 2-3)
- [ ] Text processing pipeline (Exercise 5)
- [ ] File permissions demonstration (Exercise 8)
- [ ] Links and advanced file operations (Exercise 9)
- [ ] Network testing session (Exercise 10)
- [ ] Compression comparison demo (Exercise 11)
- [ ] System administration operations (Exercise 12)
- [ ] Package management demo (Exercise 13)
- [ ] Advanced system monitoring (Exercise 4)
- [ ] File system analysis (Exercise 5)
- [ ] Process management examples (Exercise 6)
- [ ] Archive operations workflow (Exercise 11)

---

## Next Steps

1. **Practice Daily**: Use Linux commands regularly
2. **Automate Tasks**: Create scripts for repetitive work
3. **Explore Advanced Topics**: System administration, security
4. **Join Communities**: Linux forums, Stack Overflow
5. **Contribute**: Open source projects, documentation

### Screenshot Naming Convention
Save your screenshots with descriptive names:
- `01_system_exploration.png` - System info and exploration
- `02_file_management.png` - File operations workflow
- `03_text_processing.png` - Text processing and analysis
- `04_system_monitoring.png` - Advanced monitoring
- `05_filesystem_analysis.png` - File system deep dive
- `06_process_management.png` - Process control demo
- `07_network_operations.png` - Network testing
- `08_permissions_security.png` - File permissions demo
- `09_links_advanced_files.png` - Links and advanced operations
- `10_compression_archives.png` - Archive operations
- `11_system_admin.png` - System administration
- `12_package_management.png` - Package operations
- `13_performance_analysis.png` - Performance monitoring

### Performance Benchmarks
After completing all exercises, you should be able to:
- Execute 50+ Linux commands confidently
- Navigate and manage file systems efficiently
- Process and analyze text data effectively
- Monitor and troubleshoot system performance
- Manage processes and system resources
- Handle network operations and connectivity
- Create and manage archives and backups
- Understand and implement file security
- Perform basic system administration tasks

### Certification Readiness
This comprehensive training prepares you for:
- Linux+ certification fundamentals
- System administrator interviews
- DevOps engineer prerequisites
- Cloud engineer Linux requirements
- Technical team leadership roles

This guide provides everything you need for comprehensive Linux learning from theory to practical hands-on experience. Each section builds upon the previous one, with 13 detailed exercises ensuring a solid foundation for Linux mastery and professional competency.