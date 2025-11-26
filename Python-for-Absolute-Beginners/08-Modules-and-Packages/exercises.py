#!/usr/bin/env python3
"""
Modules and Packages - Exercises
"""

# Exercise 1: Use datetime module
# TODO: Print current date and time in format: "2024-01-15 14:30:00"

from datetime import datetime

now = datetime.now()
formatted = now.strftime("%Y-%m-%d %H:%M:%S")
print(f"Current date and time: {formatted}")

# Exercise 2: Random number game
# TODO: Generate random number 1-100, let user guess it

import random

def number_guessing_game():
    number = random.randint(1, 100)
    attempts = 0
    print("\nGuess the number (1-100)!")
    
    while True:
        try:
            guess = int(input("Your guess: "))
            attempts += 1
            
            if guess < number:
                print("Too low!")
            elif guess > number:
                print("Too high!")
            else:
                print(f"Correct! You got it in {attempts} attempts!")
                break
        except ValueError:
            print("Please enter a valid number")

# Uncomment to play:
# number_guessing_game()

# Exercise 3: File operations with os
# TODO: List all .py files in current directory

import os

py_files = [f for f in os.listdir('.') if f.endswith('.py')]
print(f"\nPython files in current directory: {py_files}")

# Exercise 4: Create utility module
# TODO: Create utils.py with functions: is_even(), is_prime(), factorial()
# Import and use them

# Create utils.py
utils_code = '''def is_even(n):
    return n % 2 == 0

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True

def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)
'''

with open('utils.py', 'w') as f:
    f.write(utils_code)

import utils
print(f"\n10 is even: {utils.is_even(10)}")
print(f"7 is prime: {utils.is_prime(7)}")
print(f"5! = {utils.factorial(5)}")

# Exercise 5: JSON data processor
# TODO: Read JSON file, modify data, write back

import json

data = {"users": [{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]}
with open('data.json', 'w') as f:
    json.dump(data, f, indent=2)

with open('data.json', 'r') as f:
    data = json.load(f)
    data['users'].append({"name": "Charlie", "age": 35})

with open('data.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f"\nUpdated JSON data: {data}")
