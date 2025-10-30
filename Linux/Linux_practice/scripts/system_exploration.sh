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
