# Project 5: Log File Analyzer

## Objective
Parse and analyze log files to extract useful information.

## Features

### 1. Parse Log Files
- Read log files line by line
- Extract timestamp, level, message
- Support common log formats

### 2. Count by Level
- Count ERROR, WARNING, INFO, DEBUG messages
- Calculate percentages

### 3. Find Common Errors
- Identify most frequent error messages
- Group similar errors

### 4. Time-based Analysis
- Errors per hour/day
- Peak error times
- Timeline visualization

### 5. Generate Report
- Summary statistics
- Top 10 errors
- Export to JSON/CSV

## Sample Log Format
```
2024-01-15 10:30:45 INFO Application started
2024-01-15 10:31:12 ERROR Database connection failed
2024-01-15 10:31:15 WARNING Retry attempt 1
2024-01-15 10:31:20 ERROR Database connection failed
2024-01-15 10:32:00 INFO User logged in
```

## Usage
```bash
python3 log_analyzer.py app.log
python3 log_analyzer.py app.log --level ERROR
python3 log_analyzer.py app.log --export report.json
python3 log_analyzer.py app.log --top 10
```

## Output Example
```
=== Log Analysis Report ===
Total Lines: 1000
ERROR: 45 (4.5%)
WARNING: 120 (12%)
INFO: 835 (83.5%)

Top 5 Errors:
1. Database connection failed (23 times)
2. Timeout exception (12 times)
3. Invalid credentials (10 times)
```

## Bonus Features
- Real-time log monitoring
- Alert on error threshold
- Pattern matching
- Multi-file analysis
- Web dashboard

## Learning Outcomes
- File parsing
- Regular expressions
- Data analysis
- Report generation
