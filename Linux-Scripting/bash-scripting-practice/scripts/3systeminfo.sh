#!/bin/bash
# System Information Script

echo "====S YSTEM INFORMATION ===="
echo "Hostname: $(hostname)"
echo "Operating System: $(uname -o)"
echo "Kernel Version: $(uname -r)"
echo "Current_USER: $(whoami)"
echo "Current_DIRECTORY: $(pwd)"
echo "Date and Time: $(date)"
echo "Uptime: $(uptime -p)"
