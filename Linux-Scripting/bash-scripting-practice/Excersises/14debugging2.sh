#!/bin/bash
set -x  # Display commands with expansions, but do NOT exit on error

ls /           # expected to succeed
ls /no-such-dir # expected to fail, but script continues
ls /home       # will execute despite previous failure



# Modify the previous exercise so that script continues, even if an error occurs. This time all three ls commands will execute.