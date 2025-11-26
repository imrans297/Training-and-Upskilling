#!/usr/bin/env python3
"""
Custom Module Example
"""

def greet(name):
    """Greet a person"""
    return f"Hello, {name}!"

def add(a, b):
    """Add two numbers"""
    return a + b

def subtract(a, b):
    """Subtract two numbers"""
    return a - b

def multiply(a, b):
    """Multiply two numbers"""
    return a * b

# Constants
PI = 3.14159
VERSION = "1.0.0"

if __name__ == "__main__":
    # Test the module
    print(greet("Imran"))
    print(f"5 + 3 = {add(5, 3)}")
    print(f"PI = {PI}")
