#!/bin/bash

# Variables in shell scripts
# ------------------------

# Variable Assignment
# - No spaces around = sign
# - No $ when assigning values
name="John"
age=25
current_date=$(date)

# Printing variables
# Use $ to reference a variable's value
echo "Name: $name"
echo "Age: $age"
echo "Current date: $current_date"

# String variables
greeting="Hello"
world="World"

# String concatenation
# Method 1: Adjacent strings
complete_greeting="$greeting $world"
echo $complete_greeting

# Method 2: Using double quotes
echo "${greeting} ${world}!"

# Arithmetic operations
# Use $(( )) for arithmetic
x=5
y=3
sum=$((x + y))
product=$((x * y))
echo "Sum of $x and $y is: $sum"
echo "Product of $x and $y is: $product"

# Environment variables
echo "Home directory: $HOME"
echo "Current user: $USER"
echo "Shell being used: $SHELL"

# Array variables
# Declare an array
fruits=("apple" "banana" "orange")

# Access array elements
echo "First fruit: ${fruits[0]}"
echo "All fruits: ${fruits[@]}"
echo "Number of fruits: ${#fruits[@]}"

# Readonly variables
readonly PI=3.14159
echo "PI is: $PI"
# PI=3.14  # This would cause an error

# Unsetting variables
temp_var="I will be deleted"
echo $temp_var
unset temp_var
echo "temp_var after unset: $temp_var"
