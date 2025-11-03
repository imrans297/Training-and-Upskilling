#!/bin/bash
# Comparison operators

num1=10
num2=20
string1="hello"
string2="world"

# Numeric comparisons
echo "=== NUMERIC COMPARISONS ==="
[ $num1 -eq $num2 ] && echo "$num1 equals $num2" || echo "$num1 does not equal $num2"
[ $num1 -ne $num2 ] && echo "$num1 not equals $num2"
[ $num1 -lt $num2 ] && echo "$num1 less than $num2"
[ $num1 -le $num2 ] && echo "$num1 less than or equal $num2"
[ $num1 -gt $num2 ] && echo "$num1 greater than $num2" || echo "$num1 not greater than $num2"
[ $num1 -ge $num2 ] && echo "$num1 greater than or equal $num2" || echo "$num1 not greater than or equal $num2"

# String comparisons
echo "=== STRING COMPARISONS ==="
[ "$string1" = "$string2" ] && echo "Strings are equal" || echo "Strings are not equal"
[ "$string1" != "$string2" ] && echo "Strings are different"
[ -z "$string1" ] && echo "String1 is empty" || echo "String1 is not empty"
[ -n "$string1" ] && echo "String1 is not empty"

# File tests
echo "=== FILE TESTS ==="
filename="test.txt"
touch $filename
[ -f "$filename" ] && echo "$filename is a regular file"
[ -d "$filename" ] && echo "$filename is a directory" || echo "$filename is not a directory"
[ -r "$filename" ] && echo "$filename is readable"
[ -w "$filename" ] && echo "$filename is writable"
[ -x "$filename" ] && echo "$filename is executable" || echo "$filename is not executable"