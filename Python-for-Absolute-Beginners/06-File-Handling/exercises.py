#!/usr/bin/env python3
"""
File Handling - Exercises
"""

# Exercise 1: Text file reader
# TODO: Read a text file and count number of lines, words, and characters

with open("example_data.txt", "r") as f:
    content = f.read()
    lines = content.split('\n')
    words = content.split()
    chars = len(content)
    print(f"Lines: {len(lines)}, Words: {len(words)}, Characters: {chars}")

# Exercise 2: Log file filter
# TODO: Read a log file and extract only ERROR lines to new file

with open("sample.log", "w") as f:
    f.write("INFO: Application started\n")
    f.write("ERROR: Database connection failed\n")
    f.write("WARNING: Low memory\n")
    f.write("ERROR: File not found\n")

with open("sample.log", "r") as f:
    errors = [line for line in f if "ERROR" in line]

with open("errors.log", "w") as f:
    f.writelines(errors)
print(f"\nExtracted {len(errors)} error lines to errors.log")

# Exercise 3: CSV processor
# TODO: Read CSV with student names and scores, calculate average

import csv

students_data = [["Name", "Score"], ["Alice", "85"], ["Bob", "92"], ["Charlie", "78"]]
with open("students.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerows(students_data)

with open("students.csv", "r") as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    scores = [int(row[1]) for row in reader]
    print(f"\nAverage score: {sum(scores) / len(scores)}")

# Exercise 4: JSON config manager
# TODO: Create a config.json file with app settings, read and modify it

import json

config = {"app_name": "MyApp", "version": "1.0", "debug": True}
with open("config.json", "w") as f:
    json.dump(config, f, indent=2)

with open("config.json", "r") as f:
    config = json.load(f)
    config["version"] = "1.1"

with open("config.json", "w") as f:
    json.dump(config, f, indent=2)
print(f"\nConfig updated: {config}")

# Exercise 5: File backup
# TODO: Create a function that backs up a file with timestamp

from datetime import datetime
import shutil

def backup_file(filename):
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_name = f"{filename}.backup_{timestamp}"
    shutil.copy(filename, backup_name)
    return backup_name

backup = backup_file("example_data.txt")
print(f"\nBackup created: {backup}")
