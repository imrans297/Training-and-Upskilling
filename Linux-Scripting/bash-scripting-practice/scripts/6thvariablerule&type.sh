#!/bin/bash

user_name="alice"
USER_ID=1001
file2="document.txt"

# Invalid variable names (commented out)
# 2file="invalid"     # Cannot start with number
# user-name="invalid" # Cannot contain hyphens
# user name="invalid" # Cannot contain spaces

# Special variables
echo "Script name: $0"
echo "First argument: $1"
echo "All arguments: $@"
echo "Number of arguments: $#"
echo "Process ID: $$"
echo "Exit status of last command: $?"