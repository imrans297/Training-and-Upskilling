
#Write a shell script that accepts a file or directory name as an argument. Have the script report if it is a regular file, a directory, or other type of file. If it is a regular file, exit with a 0 exit status. If it is a directory, exit with a 1 exit status. If it is some other type of file, exit with a 2 exit status.


#!/bin/bash

if [ "$1" == "" ]; then
  echo "Please provide a file or directory name."
  exit 3
fi

if [ -f "$1" ]; then
  echo "$1 is a regular file."
  exit 0
elif [ -d "$1" ]; then
  echo "$1 is a directory."
  exit 1
else
  echo "$1 is some other type of file."
  exit 2
fi
