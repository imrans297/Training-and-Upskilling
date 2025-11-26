# 04. Functions

## Defining Functions
```python
def greet():
    print("Hello!")

greet()  # Call the function
```

## Parameters and Arguments
```python
def greet(name):
    print(f"Hello, {name}!")

greet("Imran")
```

## Return Values
```python
def add(a, b):
    return a + b

result = add(5, 3)
print(result)  # 8
```

## Default Parameters
```python
def greet(name="Guest"):
    print(f"Hello, {name}!")

greet()          # Hello, Guest!
greet("Imran")   # Hello, Imran!
```

## Multiple Return Values
```python
def get_user():
    return "Imran", 30, "Mumbai"

name, age, city = get_user()
```

## Lambda Functions
```python
# Regular function
def square(x):
    return x ** 2

# Lambda (anonymous function)
square = lambda x: x ** 2
print(square(5))  # 25
```

## Exercises
See `exercises.py`
