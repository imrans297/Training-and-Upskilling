#!/bin/bash

log_random() {
  local num=$1
  local pid=$$
  echo "Random number: $num"
  logger -p user.info -t randomly[$pid] "Random number generated: $num"
}

for i in {1..3}; do
  rand_num=$RANDOM
  log_random "$rand_num"
done


# Modify the previous script so that it uses a logging function. Additionally tag each syslog message with "randomly" and include the process ID. Generate 3 random numbers.