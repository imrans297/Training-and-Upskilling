#!/usr/bin/env python3
"""
OOP Examples
"""

# Example 1: Basic class
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age
    
    def introduce(self):
        return f"Hi, I'm {self.name} and I'm {self.age} years old"

print("=== Person Class ===")
person = Person("Imran", 30)
print(person.introduce())

# Example 2: Inheritance
class Employee(Person):
    def __init__(self, name, age, employee_id, department):
        super().__init__(name, age)
        self.employee_id = employee_id
        self.department = department
    
    def introduce(self):
        return f"{super().introduce()}. I work in {self.department}"

print("\n=== Employee Class (Inheritance) ===")
emp = Employee("Imran", 30, "E001", "DevOps")
print(emp.introduce())

# Example 3: Encapsulation
class BankAccount:
    def __init__(self, owner, balance=0):
        self.owner = owner
        self.__balance = balance  # Private
    
    def deposit(self, amount):
        if amount > 0:
            self.__balance += amount
            return f"Deposited {amount}. New balance: {self.__balance}"
        return "Invalid amount"
    
    def withdraw(self, amount):
        if 0 < amount <= self.__balance:
            self.__balance -= amount
            return f"Withdrew {amount}. New balance: {self.__balance}"
        return "Insufficient funds"
    
    def get_balance(self):
        return self.__balance

print("\n=== Bank Account (Encapsulation) ===")
account = BankAccount("Imran", 1000)
print(account.deposit(500))
print(account.withdraw(200))
print(f"Balance: {account.get_balance()}")

# Example 4: Real-world - Task Manager
class Task:
    def __init__(self, title, description):
        self.title = title
        self.description = description
        self.completed = False
    
    def mark_complete(self):
        self.completed = True
    
    def __str__(self):
        status = "✓" if self.completed else "✗"
        return f"[{status}] {self.title}"

class TaskManager:
    def __init__(self):
        self.tasks = []
    
    def add_task(self, task):
        self.tasks.append(task)
    
    def list_tasks(self):
        return [str(task) for task in self.tasks]
    
    def complete_task(self, index):
        if 0 <= index < len(self.tasks):
            self.tasks[index].mark_complete()

print("\n=== Task Manager ===")
manager = TaskManager()
manager.add_task(Task("Learn Python", "Complete Python course"))
manager.add_task(Task("Practice AWS", "Deploy EKS cluster"))
print("Tasks:")
for task in manager.list_tasks():
    print(f"  {task}")
manager.complete_task(0)
print("\nAfter completing first task:")
for task in manager.list_tasks():
    print(f"  {task}")
