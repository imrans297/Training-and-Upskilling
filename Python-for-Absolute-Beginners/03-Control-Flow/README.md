# 03. Control Flow

## If Statements
```python
age = 18

if age >= 18:
    print("Adult")
elif age >= 13:
    print("Teenager")
else:
    print("Child")
```

## Comparison Operators
```python
==  # Equal
!=  # Not equal
>   # Greater than
<   # Less than
>=  # Greater than or equal
<=  # Less than or equal
```

## Logical Operators
```python
and  # Both conditions true
or   # At least one condition true
not  # Reverse the condition

# Example
age = 25
has_license = True

if age >= 18 and has_license:
    print("Can drive")
```

## For Loops
```python
# Loop through range
for i in range(5):
    print(i)  # 0, 1, 2, 3, 4

# Loop through list
fruits = ["apple", "banana", "orange"]
for fruit in fruits:
    print(fruit)
```

## While Loops
```python
count = 0
while count < 5:
    print(count)
    count += 1
```

## Break and Continue
```python
# Break - exit loop
for i in range(10):
    if i == 5:
        break
    print(i)

# Continue - skip iteration
for i in range(5):
    if i == 2:
        continue
    print(i)
```

## Exercises
See `exercises.py`
