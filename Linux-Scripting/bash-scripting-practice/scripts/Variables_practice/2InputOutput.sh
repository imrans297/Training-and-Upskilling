#!/bin/bash
#Input Methods

# Simple Input
echo "what is your name?"
read name
echo "Hello, $name!"

#Input with Promt
read -p "Enter Your age: " age
echo "You are $age years Old"

#Silent Input (for Passwords)
read -s -p "Enter Password: " password
echo
echo "Password entered (hidden)"

# Multiple Inputs
read -p "Enter First and Last name: " first last
echo "First: $first, Last: $last"

#Input with timeout
if read -t 5 -p "Enter something (5 seconds): " input; then
    echo "You entered: $input"
else
    echo "Timeout: No input received within 5 seconds."
fi

