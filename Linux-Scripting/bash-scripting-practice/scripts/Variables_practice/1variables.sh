#!/bin/bash
# variables Practice Script

echo "=== Variable Practice ==="

# Personal Information
first_name="Imran"
last_name="Shaikh"
full_name="$first_name $last_name"
age=32

echo "Full Name: $full_name"
echo "Age: $age"

#System Information
current_date=$(date +%Y-%m-%d)
current_time=$(date +%H:%M:%S)
hostname=$(hostname)

echo "Date: $current_date"
echo "Time: $current_time"
echo "Hostname: $hostname" 

# Calculation
num1=10
num2=5
sum=$((num1 + num2))
product=$((num1 * num2))

echo "Numbers: $num1 and $num2"
echo "Sum: $sum"
echo "Product: $product"


# String Operations
text="Hello World"
echo "Original: $text"
echo "Length: ${#text}"
echo "Uppercase: ${text^^}"
echo "Lowercase: ${text,,}"