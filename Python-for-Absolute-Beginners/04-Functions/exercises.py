#!/usr/bin/env python3
"""
Functions - Exercises
"""

# Exercise 1: Calculator functions
# TODO: Create functions for add, subtract, multiply, divide

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        return "Error: Division by zero"
    return a / b

print(f"10 + 5 = {add(10, 5)}")
print(f"10 - 5 = {subtract(10, 5)}")
print(f"10 * 5 = {multiply(10, 5)}")
print(f"10 / 5 = {divide(10, 5)}")

# Exercise 2: Temperature converter
# TODO: Create celsius_to_fahrenheit() and fahrenheit_to_celsius()

def celsius_to_fahrenheit(celsius):
    return celsius * 9/5 + 32

def fahrenheit_to_celsius(fahrenheit):
    return (fahrenheit - 32) * 5/9

print(f"\n25°C = {celsius_to_fahrenheit(25)}°F")
print(f"77°F = {fahrenheit_to_celsius(77)}°C")

# Exercise 3: Check prime number
# TODO: Create is_prime(n) function that returns True/False

def is_prime(n):
    if n < 2:
        return False
    for i in range(2, int(n ** 0.5) + 1):
        if n % i == 0:
            return False
    return True

print(f"\n7 is prime: {is_prime(7)}")
print(f"10 is prime: {is_prime(10)}")

# Exercise 4: List statistics
# TODO: Create function that returns min, max, average of a list

def list_stats(numbers):
    return min(numbers), max(numbers), sum(numbers) / len(numbers)

data = [10, 20, 30, 40, 50]
min_val, max_val, avg = list_stats(data)
print(f"\nList: {data}")
print(f"Min: {min_val}, Max: {max_val}, Average: {avg}")

# Exercise 5: String reverser
# TODO: Create function that reverses a string

def reverse_string(text):
    return text[::-1]

print(f"\nReverse of 'Python': {reverse_string('Python')}")
print(f"Reverse of 'Hello': {reverse_string('Hello')}")
