#!/usr/bin/env python3
"""
Data Structures - Exercises
"""

# Exercise 1: Shopping list manager
# TODO: Create list, add items, remove items, display all

shopping_list = ["milk", "bread", "eggs"]
print(f"Initial list: {shopping_list}")
shopping_list.append("butter")
print(f"After adding butter: {shopping_list}")
shopping_list.remove("bread")
print(f"After removing bread: {shopping_list}")

# Exercise 2: Student grades
# TODO: Create dictionary with student names and grades
# Calculate average grade

students = {
    "Alice": 85,
    "Bob": 92,
    "Charlie": 78,
    "Diana": 95
}
average = sum(students.values()) / len(students)
print(f"\nStudent grades: {students}")
print(f"Average grade: {average}")

# Exercise 3: Remove duplicates
# TODO: Given list [1,2,2,3,4,4,5], remove duplicates using set

numbers = [1, 2, 2, 3, 4, 4, 5]
unique_numbers = list(set(numbers))
print(f"\nOriginal: {numbers}")
print(f"Unique: {sorted(unique_numbers)}")

# Exercise 4: Word frequency counter
# TODO: Count frequency of each word in a sentence

sentence = "python is great and python is fun"
words = sentence.split()
word_count = {}
for word in words:
    word_count[word] = word_count.get(word, 0) + 1
print(f"\nSentence: {sentence}")
print(f"Word frequency: {word_count}")

# Exercise 5: List comprehension practice
# TODO: Create list of squares of even numbers from 1-20

even_squares = [i**2 for i in range(1, 21) if i % 2 == 0]
print(f"\nSquares of even numbers (1-20): {even_squares}")
