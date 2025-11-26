# 09. Object-Oriented Programming Basics

## Classes and Objects

### Creating a class
```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def greet(self):
        return f"Hello, I'm {self.name}"

# Create object
person1 = Person("Imran", 30)
print(person1.greet())
print(person1.age)
```

## The __init__ Method
Constructor method that initializes object attributes.

```python
class Car:
    def __init__(self, brand, model, year):
        self.brand = brand
        self.model = model
        self.year = year

car = Car("Toyota", "Camry", 2024)
```

## Instance Methods
```python
class Calculator:
    def add(self, a, b):
        return a + b
    
    def subtract(self, a, b):
        return a - b

calc = Calculator()
print(calc.add(5, 3))
```

## Class Attributes vs Instance Attributes
```python
class Dog:
    # Class attribute (shared by all instances)
    species = "Canis familiaris"
    
    def __init__(self, name, age):
        # Instance attributes (unique to each instance)
        self.name = name
        self.age = age

dog1 = Dog("Buddy", 3)
dog2 = Dog("Max", 5)

print(Dog.species)      # Canis familiaris
print(dog1.name)        # Buddy
print(dog2.name)        # Max
```

## Inheritance
```python
class Animal:
    def __init__(self, name):
        self.name = name
    
    def speak(self):
        pass

class Dog(Animal):
    def speak(self):
        return f"{self.name} says Woof!"

class Cat(Animal):
    def speak(self):
        return f"{self.name} says Meow!"

dog = Dog("Buddy")
cat = Cat("Whiskers")
print(dog.speak())
print(cat.speak())
```

## Encapsulation
```python
class BankAccount:
    def __init__(self, balance):
        self.__balance = balance  # Private attribute
    
    def deposit(self, amount):
        if amount > 0:
            self.__balance += amount
    
    def get_balance(self):
        return self.__balance

account = BankAccount(1000)
account.deposit(500)
print(account.get_balance())  # 1500
```

## Special Methods
```python
class Book:
    def __init__(self, title, author):
        self.title = title
        self.author = author
    
    def __str__(self):
        return f"{self.title} by {self.author}"
    
    def __repr__(self):
        return f"Book('{self.title}', '{self.author}')"

book = Book("Python Basics", "John Doe")
print(book)        # Uses __str__
print(repr(book))  # Uses __repr__
```

## Class Methods and Static Methods
```python
class MathUtils:
    @staticmethod
    def add(a, b):
        return a + b
    
    @classmethod
    def from_string(cls, string):
        # Factory method
        return cls()

result = MathUtils.add(5, 3)
```

## Real-World Example: EC2 Instance
```python
class EC2Instance:
    def __init__(self, instance_id, instance_type, state):
        self.instance_id = instance_id
        self.instance_type = instance_type
        self.state = state
    
    def start(self):
        if self.state == "stopped":
            self.state = "running"
            return f"Starting {self.instance_id}"
        return f"{self.instance_id} already running"
    
    def stop(self):
        if self.state == "running":
            self.state = "stopped"
            return f"Stopping {self.instance_id}"
        return f"{self.instance_id} already stopped"
    
    def __str__(self):
        return f"EC2({self.instance_id}, {self.instance_type}, {self.state})"

instance = EC2Instance("i-1234567", "t3.medium", "stopped")
print(instance.start())
print(instance)
```

## Exercises
See `exercises.py`
