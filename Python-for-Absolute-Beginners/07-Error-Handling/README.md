# 07. Error Handling

## Try-Except Blocks

### Basic exception handling
```python
try:
    result = 10 / 0
except ZeroDivisionError:
    print("Cannot divide by zero!")
```

### Multiple exceptions
```python
try:
    num = int(input("Enter number: "))
    result = 10 / num
except ValueError:
    print("Invalid input!")
except ZeroDivisionError:
    print("Cannot divide by zero!")
```

### Catch all exceptions
```python
try:
    # risky code
    result = 10 / 0
except Exception as e:
    print(f"Error occurred: {e}")
```

## Finally Clause
```python
try:
    f = open("file.txt", "r")
    content = f.read()
except FileNotFoundError:
    print("File not found!")
finally:
    # Always executes
    print("Cleanup done")
```

## Else Clause
```python
try:
    num = int(input("Enter number: "))
except ValueError:
    print("Invalid input!")
else:
    # Runs if no exception
    print(f"You entered: {num}")
```

## Raising Exceptions
```python
def validate_age(age):
    if age < 0:
        raise ValueError("Age cannot be negative")
    if age > 150:
        raise ValueError("Age too high")
    return True

try:
    validate_age(-5)
except ValueError as e:
    print(e)
```

## Custom Exceptions
```python
class InvalidEmailError(Exception):
    pass

def validate_email(email):
    if "@" not in email:
        raise InvalidEmailError("Email must contain @")
    return True

try:
    validate_email("invalid-email")
except InvalidEmailError as e:
    print(e)
```

## Common Exceptions
- `ValueError` - Invalid value
- `TypeError` - Wrong type
- `KeyError` - Key not in dictionary
- `IndexError` - Index out of range
- `FileNotFoundError` - File doesn't exist
- `ZeroDivisionError` - Division by zero
- `AttributeError` - Invalid attribute

## Best Practices
1. Catch specific exceptions
2. Don't use bare `except:`
3. Use finally for cleanup
4. Log errors properly
5. Don't suppress errors silently

## Exercises
See `exercises.py`
