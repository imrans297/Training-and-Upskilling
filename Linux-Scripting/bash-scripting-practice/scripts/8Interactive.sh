#!/bin/bash
# Interactive User Information Collector

echo "=== Interactive User Information Collector ==="
echo 

# Collect USer Information
read -p "Enter Your Full Name: " full_name
read -p "Enter Your Email: " email
read -p "Enter Your Age: " age
read -p "Enter Your City: " city

# Collect Preferences
echo
echo "Select Your Favorite Programming Language:"
echo "1) Python"
echo "2) JavaScript"
echo "3) Java"
echo "4) C++"
echo "5) Other"
read -p "Enter choice (1-5): " lang_choice

case $lang_choice in
    1) lang="Python";;
    2) lang="JavaScript";;
    3) lang="Java";;
    4) lang="C++";;
    5) read -p "Enter your favorite language: " lang;;
    *) lang="Unknown";;
esac

# Display Collected Information
echo
echo "=== Collected Information ==="
printf "%-15s: %s\n" "Name" "$full_name"
printf "%-15s: %s\n" "Email" "$email"
printf "%-15s: %s\n" "Age" "$age"
printf "%-15s: %s\n" "City" "$city"
printf "%-15s: %s\n" "Favorite Language" "$lang"
printf "%-15s: %s\n" "Language" "$language"
printf "%-15s: %s\n" "Operating System" "$(uname -o)"

# Save to file
cat > user_profile.txt << EOL
User Profile
============
Name: $full_name
Email: $email
Age: $age
City: $city
Favorite Language: $language
Created: $(date)
EOL

echo
echo "Profile saved to user_profile.txt"