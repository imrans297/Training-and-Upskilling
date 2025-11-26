# 06. File Handling

## Reading Files

### Read entire file
```python
with open("file.txt", "r") as f:
    content = f.read()
    print(content)
```

### Read line by line
```python
with open("file.txt", "r") as f:
    for line in f:
        print(line.strip())
```

### Read all lines into list
```python
with open("file.txt", "r") as f:
    lines = f.readlines()
```

## Writing Files

### Write (overwrite)
```python
with open("output.txt", "w") as f:
    f.write("Hello, World!\n")
    f.write("Second line\n")
```

### Append
```python
with open("output.txt", "a") as f:
    f.write("Appended line\n")
```

## Working with CSV

```python
import csv

# Read CSV
with open("data.csv", "r") as f:
    reader = csv.reader(f)
    for row in reader:
        print(row)

# Write CSV
data = [["Name", "Age"], ["Imran", "30"], ["John", "25"]]
with open("output.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerows(data)
```

## Working with JSON

```python
import json

# Read JSON
with open("data.json", "r") as f:
    data = json.load(f)

# Write JSON
data = {"name": "Imran", "age": 30, "city": "Mumbai"}
with open("output.json", "w") as f:
    json.dump(data, f, indent=2)
```

## File Operations

```python
import os

# Check if file exists
if os.path.exists("file.txt"):
    print("File exists")

# Delete file
os.remove("file.txt")

# Rename file
os.rename("old.txt", "new.txt")

# Get file size
size = os.path.getsize("file.txt")
```

## Exercises
See `exercises.py`
