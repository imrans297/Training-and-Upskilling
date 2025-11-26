#!/usr/bin/env python3
"""
Error Handling Examples
"""

# Example 1: Division with error handling
def safe_divide(a, b):
    try:
        result = a / b
        return result
    except ZeroDivisionError:
        print("Error: Cannot divide by zero")
        return None
    except TypeError:
        print("Error: Invalid input types")
        return None

print("=== Safe Division ===")
print(safe_divide(10, 2))   # 5.0
print(safe_divide(10, 0))   # Error message
print(safe_divide(10, "a")) # Error message

# Example 2: File handling with errors
def read_file_safe(filename):
    try:
        with open(filename, "r") as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: {filename} not found")
        return None
    except PermissionError:
        print(f"Error: No permission to read {filename}")
        return None

print("\n=== File Reading ===")
content = read_file_safe("nonexistent.txt")

# Example 3: Input validation
def get_valid_age():
    while True:
        try:
            age = int(input("Enter your age: "))
            if age < 0 or age > 150:
                raise ValueError("Age must be between 0 and 150")
            return age
        except ValueError as e:
            print(f"Invalid input: {e}")
            print("Please try again.")

# Uncomment to test:
# age = get_valid_age()
# print(f"Your age is: {age}")
