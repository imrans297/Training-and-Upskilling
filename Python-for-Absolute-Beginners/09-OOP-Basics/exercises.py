#!/usr/bin/env python3
"""
OOP Basics - Exercises
"""

# Exercise 1: Create Student class
# TODO: Create class with name, age, grades (list)
# Add method to calculate average grade

class Student:
    def __init__(self, name, age, grades):
        self.name = name
        self.age = age
        self.grades = grades
    
    def average_grade(self):
        return sum(self.grades) / len(self.grades) if self.grades else 0
    
    def __str__(self):
        return f"{self.name} (Age: {self.age}, Average: {self.average_grade():.2f})"

student = Student("Alice", 20, [85, 90, 78, 92])
print(student)

# Exercise 2: Bank Account
# TODO: Create BankAccount class with deposit, withdraw, get_balance methods
# Handle insufficient funds

class BankAccount:
    def __init__(self, owner, balance=0):
        self.owner = owner
        self.__balance = balance
    
    def deposit(self, amount):
        if amount > 0:
            self.__balance += amount
            return f"Deposited ${amount}. New balance: ${self.__balance}"
        return "Invalid amount"
    
    def withdraw(self, amount):
        if amount > self.__balance:
            return "Insufficient funds"
        if amount > 0:
            self.__balance -= amount
            return f"Withdrew ${amount}. New balance: ${self.__balance}"
        return "Invalid amount"
    
    def get_balance(self):
        return self.__balance

account = BankAccount("John", 1000)
print(f"\n{account.deposit(500)}")
print(account.withdraw(200))
print(account.withdraw(2000))

# Exercise 3: Inheritance - Vehicles
# TODO: Create Vehicle base class, then Car and Motorcycle subclasses
# Each with specific attributes and methods

class Vehicle:
    def __init__(self, brand, model, year):
        self.brand = brand
        self.model = model
        self.year = year
    
    def info(self):
        return f"{self.year} {self.brand} {self.model}"

class Car(Vehicle):
    def __init__(self, brand, model, year, doors):
        super().__init__(brand, model, year)
        self.doors = doors
    
    def info(self):
        return f"{super().info()} - {self.doors} doors"

class Motorcycle(Vehicle):
    def __init__(self, brand, model, year, engine_cc):
        super().__init__(brand, model, year)
        self.engine_cc = engine_cc
    
    def info(self):
        return f"{super().info()} - {self.engine_cc}cc"

car = Car("Toyota", "Camry", 2024, 4)
moto = Motorcycle("Harley", "Sportster", 2024, 1200)
print(f"\n{car.info()}")
print(moto.info())

# Exercise 4: Library System
# TODO: Create Book and Library classes
# Library should manage collection of books (add, remove, search)

class Book:
    def __init__(self, title, author, isbn):
        self.title = title
        self.author = author
        self.isbn = isbn
    
    def __str__(self):
        return f"{self.title} by {self.author}"

class Library:
    def __init__(self):
        self.books = []
    
    def add_book(self, book):
        self.books.append(book)
        return f"Added: {book}"
    
    def remove_book(self, isbn):
        for book in self.books:
            if book.isbn == isbn:
                self.books.remove(book)
                return f"Removed: {book}"
        return "Book not found"
    
    def search(self, title):
        results = [book for book in self.books if title.lower() in book.title.lower()]
        return results if results else "No books found"

library = Library()
print(f"\n{library.add_book(Book('Python Basics', 'John Doe', '123'))}")
print(library.add_book(Book('AWS Guide', 'Jane Smith', '456')))
print(f"Search results: {library.search('Python')}")

# Exercise 5: AWS Resource Manager
# TODO: Create AWSResource base class
# Create EC2Instance and S3Bucket subclasses with specific methods

class AWSResource:
    def __init__(self, resource_id, region):
        self.resource_id = resource_id
        self.region = region
    
    def info(self):
        return f"{self.resource_id} in {self.region}"

class EC2Instance(AWSResource):
    def __init__(self, resource_id, region, instance_type, state):
        super().__init__(resource_id, region)
        self.instance_type = instance_type
        self.state = state
    
    def start(self):
        if self.state == "stopped":
            self.state = "running"
            return f"Started {self.resource_id}"
        return f"{self.resource_id} already running"
    
    def stop(self):
        if self.state == "running":
            self.state = "stopped"
            return f"Stopped {self.resource_id}"
        return f"{self.resource_id} already stopped"

class S3Bucket(AWSResource):
    def __init__(self, resource_id, region, size_gb):
        super().__init__(resource_id, region)
        self.size_gb = size_gb
    
    def upload(self, file_size):
        self.size_gb += file_size
        return f"Uploaded {file_size}GB. Total: {self.size_gb}GB"

ec2 = EC2Instance("i-123456", "us-east-1", "t3.medium", "stopped")
s3 = S3Bucket("my-bucket", "us-east-1", 10)
print(f"\n{ec2.start()}")
print(s3.upload(5))
