#!/bin/bash
# Case statement example

echo "Enter a day of the week (1-7):"
read day

case $day in
    1)
        echo "Monday - Start of work week"
        ;;
    2)
        echo "Tuesday - Getting into the groove"
        ;;
    3)
        echo "Wednesday - Hump day"
        ;;
    4)
        echo "Thursday - Almost there"
        ;;
    5)
        echo "Friday - TGIF!"
        ;;
    6|7)
        echo "Weekend - Time to relax"
        ;;
    *)
        echo "Invalid day. Please enter 1-7"
        ;;
esac