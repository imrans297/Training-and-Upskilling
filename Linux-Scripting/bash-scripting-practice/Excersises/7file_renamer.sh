#!/bin/bash

today=$(date +%F)

read -p "Enter file extension: " ext
read -p "Enter prefix (Enter for $today): " prefix

# Use date if no prefix provided
prefix=${prefix:-$today}

for file in *."$ext"; do
  [ -e "$file" ] || continue
  echo "Renaming $file to ${prefix}-$file"
  mv "$file" "${prefix}-$file"
done

#Write a script that renames files based on the file extension. The script should prompt the user for a file extension. Next, it should ask the user what prefix to prepend to the file name(s). By default the prefix should be the current date in YYYY­MM­DD format. So, if the user simply presses enter the date will be used. Otherwise, whatever the user entered will be used as the prefix. Next, it should display the original file name and the new name of the file. Finally, it should rename the file.
#The script you described, which renames files based on user-input file extensions and prefixes (defaulting to the current date), can be named in a descriptive and clear way such as: