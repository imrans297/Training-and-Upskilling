#!/usr/bin/env python3
"""
File Handling Examples
"""

# Example 1: Read and display file
print("=== Reading File ===")
with open("example_data.txt", "r") as f:
    content = f.read()
    print(content)

# Example 2: Count lines
print("\n=== Counting Lines ===")
with open("example_data.txt", "r") as f:
    lines = f.readlines()
    print(f"Total lines: {len(lines)}")

# Example 3: Write to file
print("\n=== Writing File ===")
with open("output.txt", "w") as f:
    f.write("This is a new file\n")
    f.write("Created by Python\n")
print("File written successfully!")

# Example 4: JSON example
import json

data = {
    "name": "Imran Shaikh",
    "role": "DevOps Engineer",
    "skills": ["AWS", "Docker", "Kubernetes", "Python"]
}

with open("profile.json", "w") as f:
    json.dump(data, f, indent=2)
print("\nJSON file created!")
