#!/usr/bin/env python3
"""
Log File Analyzer - Starter Code
"""

import re
import sys
from collections import Counter

def parse_log_line(line):
    """Parse a single log line"""
    # TODO: Extract timestamp, level, message using regex
    # Pattern: YYYY-MM-DD HH:MM:SS LEVEL Message
    pass

def analyze_log_file(filename):
    """Analyze log file and return statistics"""
    # TODO: Implement
    # 1. Read file
    # 2. Parse each line
    # 3. Count by level
    # 4. Find common errors
    # 5. Return statistics
    pass

def generate_report(stats):
    """Generate and print analysis report"""
    # TODO: Implement
    pass

def export_to_json(stats, output_file):
    """Export statistics to JSON"""
    # TODO: Implement
    pass

def main():
    """Main function"""
    if len(sys.argv) < 2:
        print("Usage: python3 log_analyzer.py <logfile>")
        return
    
    logfile = sys.argv[1]
    
    # TODO: Implement main logic
    print(f"Analyzing: {logfile}")

if __name__ == "__main__":
    main()
