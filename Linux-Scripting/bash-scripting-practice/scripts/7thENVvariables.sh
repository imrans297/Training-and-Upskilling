#!/bin/bash
# Working with environment variables

echo "=== ENVIRONMENT VARIABLES ==="
echo "PATH: $PATH"
echo "HOME: $HOME"
echo "USER: $USER"
echo "SHELL: $SHELL"
echo "PWD: $PWD"

# Setting custom environment variables
export MY_VAR="Custom Value"
echo "Custom variable: $MY_VAR"

# Reading environment variables
echo "Enter your favorite color:"
read favorite_color
export FAVORITE_COLOR=$favorite_color
echo "Your favorite color is: $FAVORITE_COLOR"