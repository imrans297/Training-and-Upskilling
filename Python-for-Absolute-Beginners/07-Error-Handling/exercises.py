#!/usr/bin/env python3
"""
Error Handling - Exercises
"""

# Exercise 1: Safe division
# TODO: Create function that divides two numbers with error handling

def safe_divide(a, b):
    try:
        return a / b
    except ZeroDivisionError:
        return "Error: Cannot divide by zero"
    except TypeError:
        return "Error: Invalid input types"

print(safe_divide(10, 2))   # 5.0
print(safe_divide(10, 0))   # Error message

# Exercise 2: File reader with error handling
# TODO: Read file, handle FileNotFoundError and other errors

def read_file_safe(filename):
    try:
        with open(filename, "r") as f:
            return f.read()
    except FileNotFoundError:
        return f"Error: {filename} not found"
    except PermissionError:
        return f"Error: No permission to read {filename}"

print(f"\n{read_file_safe('nonexistent.txt')}")

# Exercise 3: User input validator
# TODO: Get integer input from user, handle ValueError, keep asking until valid

def get_valid_integer():
    while True:
        try:
            num = int(input("Enter an integer: "))
            return num
        except ValueError:
            print("Invalid input! Please enter a valid integer.")

# Uncomment to test:
# number = get_valid_integer()
# print(f"You entered: {number}")

# Exercise 4: List access
# TODO: Access list element by index, handle IndexError

def get_list_element(lst, index):
    try:
        return lst[index]
    except IndexError:
        return "Error: Index out of range"

my_list = [10, 20, 30]
print(f"\nElement at index 1: {get_list_element(my_list, 1)}")
print(f"Element at index 10: {get_list_element(my_list, 10)}")

# Exercise 5: Custom exception
# TODO: Create PasswordTooShortError, validate password length

class PasswordTooShortError(Exception):
    pass

def validate_password(password):
    if len(password) < 8:
        raise PasswordTooShortError("Password must be at least 8 characters")
    return True

try:
    validate_password("abc")
except PasswordTooShortError as e:
    print(f"\n{e}")

try:
    validate_password("securepass123")
    print("Password is valid!")
except PasswordTooShortError as e:
    print(e)
