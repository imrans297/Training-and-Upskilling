#!/bin/bash

# Generate a random number using $RANDOM
random_number=$RANDOM

# Display the random number on the screen
echo "Random number: $random_number"

# Generate a syslog message with the random number using user facility and info level
logger -p user.info "Random number generated: $random_number"

#Write a shell script that displays one random number to the screen and also generates a syslog message with that random number. Use the "user" facility and the "info" facility for your messages.