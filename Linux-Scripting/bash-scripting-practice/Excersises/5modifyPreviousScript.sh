#!/bin/bash

file_count() {
  local dir=$1
  local count=$(ls -1A "$dir" 2>/dev/null | wc -l)
  echo "$dir:"
  echo "$count"
}

# Call the function three times with different directories
file_count /etc
file_count /var
file_count /usr/bin



#Modify the script from the previous exercise. Make the "file_count" function accept a directory as an argument. Next have the function display the name of the directory followed by a colon. Finally, display the number of files to the screen on the next line. Call the function three times. First, on the "/etc" directory, next on the "/var" directory and finally on the "/usr/bin" directory.

