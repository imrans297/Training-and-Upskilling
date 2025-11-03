#!/bin/bash
set -ex  # Exit on error and display commands with expansions

ls /           # expected to succeed
ls /no-such-dir # expected to fail
ls /home       # should not execute due to failure in previous command


# Write a shell script that exit on error and displays commands as they will execute, including all expansions and substitutions. Use 3 ls commands in your script. Make the first one succeed, the second one fail, and the third one succeed. If you are using the proper options, the third ls command will not be executed.