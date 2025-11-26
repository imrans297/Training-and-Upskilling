# 05. Data Structures

## Lists
```python
# Create list
fruits = ["apple", "banana", "orange"]

# Access elements
print(fruits[0])  # apple

# Add elements
fruits.append("mango")
fruits.insert(1, "grape")

# Remove elements
fruits.remove("banana")
fruits.pop()  # Remove last

# List operations
len(fruits)
fruits.sort()
fruits.reverse()
```

## Tuples (Immutable)
```python
coordinates = (10, 20)
x, y = coordinates  # Unpacking
```

## Dictionaries
```python
# Create dictionary
user = {
    "name": "Imran",
    "age": 30,
    "city": "Mumbai"
}

# Access values
print(user["name"])
print(user.get("email", "Not found"))

# Add/Update
user["email"] = "imran@example.com"

# Remove
del user["age"]

# Loop through
for key, value in user.items():
    print(f"{key}: {value}")
```

## Sets (Unique values)
```python
numbers = {1, 2, 3, 3, 4}  # {1, 2, 3, 4}
numbers.add(5)
numbers.remove(1)
```

## List Comprehensions
```python
# Traditional way
squares = []
for i in range(10):
    squares.append(i ** 2)

# List comprehension
squares = [i ** 2 for i in range(10)]

# With condition
evens = [i for i in range(10) if i % 2 == 0]
```

## Exercises
See `exercises.py`
