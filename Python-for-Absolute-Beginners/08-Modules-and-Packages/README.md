# 08. Modules and Packages

## What are Modules?
Modules are Python files containing functions, classes, and variables that can be imported and reused.

## Importing Modules

### Import entire module
```python
import math
print(math.sqrt(16))  # 4.0
print(math.pi)        # 3.14159...
```

### Import specific items
```python
from math import sqrt, pi
print(sqrt(16))
print(pi)
```

### Import with alias
```python
import datetime as dt
now = dt.datetime.now()
```

## Standard Library Modules

### os - Operating system
```python
import os
print(os.getcwd())           # Current directory
os.mkdir("new_folder")       # Create directory
files = os.listdir(".")      # List files
```

### datetime - Date and time
```python
from datetime import datetime, timedelta

now = datetime.now()
print(now.strftime("%Y-%m-%d %H:%M:%S"))

tomorrow = now + timedelta(days=1)
```

### random - Random numbers
```python
import random

num = random.randint(1, 10)      # Random int
choice = random.choice([1,2,3])  # Random choice
random.shuffle([1,2,3,4,5])      # Shuffle list
```

### sys - System parameters
```python
import sys
print(sys.version)      # Python version
print(sys.argv)         # Command line args
```

### json - JSON handling
```python
import json
data = {"name": "Imran", "age": 30}
json_str = json.dumps(data)
```

## Creating Your Own Module

Create `mymodule.py`:
```python
def greet(name):
    return f"Hello, {name}!"

def add(a, b):
    return a + b

PI = 3.14159
```

Use it:
```python
import mymodule
print(mymodule.greet("Imran"))
print(mymodule.add(5, 3))
print(mymodule.PI)
```

## Packages
Packages are directories containing multiple modules with an `__init__.py` file.

```
mypackage/
    __init__.py
    module1.py
    module2.py
```

## pip - Package Manager

### Install package
```bash
pip3 install requests
pip3 install boto3
```

### List installed packages
```bash
pip3 list
```

### Install from requirements.txt
```bash
pip3 install -r requirements.txt
```

### Create requirements.txt
```bash
pip3 freeze > requirements.txt
```

## Popular Packages
- `requests` - HTTP requests
- `boto3` - AWS SDK
- `pandas` - Data analysis
- `numpy` - Numerical computing
- `flask` - Web framework

## Exercises
See `exercises.py`
