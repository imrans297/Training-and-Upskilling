#!/usr/bin/env python3
"""
Module Usage Examples
"""

# Example 1: Using standard library modules
import os
import datetime
import random

print("=== OS Module ===")
print(f"Current directory: {os.getcwd()}")
print(f"Files: {os.listdir('.')[:5]}")  # First 5 files

print("\n=== Datetime Module ===")
now = datetime.datetime.now()
print(f"Current time: {now.strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Tomorrow: {(now + datetime.timedelta(days=1)).strftime('%Y-%m-%d')}")

print("\n=== Random Module ===")
print(f"Random number (1-10): {random.randint(1, 10)}")
print(f"Random choice: {random.choice(['Python', 'Java', 'Go'])}")

# Example 2: Using custom module
import mymodule

print("\n=== Custom Module ===")
print(mymodule.greet("Imran"))
print(f"5 + 3 = {mymodule.add(5, 3)}")
print(f"PI = {mymodule.PI}")

# Example 3: Import specific items
from mymodule import greet, multiply

print("\n=== Specific Imports ===")
print(greet("DevOps"))
print(f"4 * 5 = {multiply(4, 5)}")
