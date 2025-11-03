#!/bin/bash
# Conditional statements

# Simple if statement
age=18
if [ $age -ge 18 ]; then
    echo "You are an adult"
fi

# If-else statement
score=85
if [ $score -ge 90 ]; then
    echo "Grade: A"
else
    echo "Grade: B or lower"
fi

# If-elif-else statement
temperature=25
if [ $temperature -gt 30 ]; then
    echo "It's hot outside"
elif [ $temperature -gt 20 ]; then
    echo "It's warm outside"
elif [ $temperature -gt 10 ]; then
    echo "It's cool outside"
else
    echo "It's cold outside"
fi