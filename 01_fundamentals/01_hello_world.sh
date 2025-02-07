#!/bin/bash

# This is your first shell script!
# The line above starting with #! is called a "shebang"
# It tells the system which interpreter to use to run this script

# Comments in shell scripts start with #
# They are used to explain what the code does

# Print a simple message to the screen
# echo is a built-in command that outputs its arguments
echo "Hello, World!"

# Print current date and time
# The $(command) syntax is called command substitution
# It runs the command and puts its output in place
echo "Today is $(date)"

# Print current user
echo "Current user is $USER"

# Print current working directory
echo "Current directory is $PWD"

# Exit the script with success status
# 0 means success, any other number means error
exit 0
