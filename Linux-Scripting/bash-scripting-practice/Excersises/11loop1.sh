#!/bin/bash

lineno=1
while IFS= read -r line; do
  echo "${lineno}: $line"
  ((lineno++))
done < /etc/passwd


# Exercise 1:

# Write a shell script that loops through the /etc/passwd file one line at a time. Prepend each line with a line number followed by a colon and then a space.