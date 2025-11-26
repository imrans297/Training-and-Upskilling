#!/usr/bin/env python3
"""
Control Flow - Exercises
"""

# Exercise 1: Grade calculator
# TODO: Write a program that takes a score (0-100) and prints grade
# A: 90-100, B: 80-89, C: 70-79, D: 60-69, F: below 60

score = int(input("Enter score (0-100): "))

if score >= 90:
    print("Grade: A")
elif score >= 80:
    print("Grade: B")
elif score >= 70:
    print("Grade: C")
elif score >= 60:
    print("Grade: D")
else:
    print("Grade: F")

# Exercise 2: Even or Odd
# TODO: Check if a number is even or odd

num = int(input("Enter a number: "))

if num % 2 == 0:
    print(f"{num} is Even")
else:
    print(f"{num} is Odd")

# Exercise 3: Print multiplication table
# TODO: Print multiplication table for number 5 (5x1 to 5x10)

for i in range(1, 11):
    print(f"5 x {i} = {5 * i}")

# Exercise 4: Sum of numbers
# TODO: Calculate sum of numbers from 1 to 100 using loop

total = 0
for i in range(1, 101):
    total += i
print(f"Sum of numbers from 1 to 100: {total}")

# Exercise 5: Password validator
# TODO: Keep asking for password until user enters "python123"

while True:
    password = input("Enter password: ")
    if password == "python123":
        print("Access granted!")
        break
    else:
        print("Incorrect password. Try again.")
