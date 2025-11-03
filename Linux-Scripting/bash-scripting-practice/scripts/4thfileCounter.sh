#!/bin/bash
# Count files in current directory


echo "=== FILE COUNTER ==="
echo "Current directory: $(pwd)"
echo "Total files: $(ls -1 | wc -l)"
echo "Hidden files: $(ls -1a | grep '^\\.' | wc -l)"
echo "Directories: $(ls -1 -d */ 2>/dev/null | wc -l)"
echo "Regular files: $(ls -1 -p | grep -v / | wc -l)"