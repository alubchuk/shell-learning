#!/bin/bash

# Input and Output Operations
# -------------------------

# Basic output using echo
echo "This is a simple output"

# Output with formatting
echo -e "This is line 1\nThis is line 2"  # -e enables interpretation of backslash escapes

# Output to stderr
echo "This is an error message" >&2

# Reading user input
echo -n "Enter your name: "  # -n prevents newline
read name
echo "Hello, $name!"

# Reading with a prompt
read -p "Enter your age: " age
echo "You are $age years old"

# Reading with a timeout (5 seconds)
read -t 5 -p "Quick! Enter your favorite color: " color
echo -e "\nYour favorite color is: $color"

# Reading silent input (for passwords)
read -s -p "Enter a password: " password
echo -e "\nPassword received!"

# Reading multiple values
echo -n "Enter three fruits (separated by spaces): "
read fruit1 fruit2 fruit3
echo "You entered: $fruit1, $fruit2, and $fruit3"

# Reading into an array
echo -n "Enter several numbers (separated by spaces): "
read -a numbers
echo "First number: ${numbers[0]}"
echo "All numbers: ${numbers[@]}"

# File output
echo "This will be written to a file" > output.txt
echo "This will be appended to the file" >> output.txt

# Reading from a file
echo "Contents of output.txt:"
cat output.txt

# Here document (multi-line input)
cat << EOF > summary.txt
This is a multi-line
text block that will be
written to summary.txt
EOF

echo "Contents of summary.txt:"
cat summary.txt

# Cleanup
rm output.txt summary.txt
