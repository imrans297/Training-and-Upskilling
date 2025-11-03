#!/bin/bash
# Conditional statements

# Simple if statement
num=10
if [ $num -lt 20 ]; then
    echo "$num is less than 20"
fi

# If-else statement
day="Sunday"
if [ "$day" == "Saturday" ] || [ "$day" == "Sunday" ]; then
    echo "It's the weekend!"
else
    echo "It's a weekday."
fi

# If-elif-else statement
marks=75
if [ $marks -ge 90 ]; then
    echo "Excellent!"
elif [ $marks -ge 70 ]; then
    echo "Good job!"
elif [ $marks -ge 50 ]; then
    echo "You passed."
else
    echo "Better luck next time."
fi