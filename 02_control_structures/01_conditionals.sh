#!/bin/bash

# Conditional Statements Examples
# -----------------------------

# Basic if statement
echo "Basic if statement example:"
number=10
if [ $number -gt 5 ]; then
    echo "$number is greater than 5"
fi

# if-else statement
echo -e "\nif-else example:"
age=20
if [ $age -ge 18 ]; then
    echo "You are an adult"
else
    echo "You are a minor"
fi

# if-elif-else statement
echo -e "\nif-elif-else example:"
score=75
if [ $score -ge 90 ]; then
    echo "Grade: A"
elif [ $score -ge 80 ]; then
    echo "Grade: B"
elif [ $score -ge 70 ]; then
    echo "Grade: C"
else
    echo "Grade: D"
fi

# String comparisons
echo -e "\nString comparison example:"
name="John"
if [ "$name" = "John" ]; then
    echo "Hello John!"
fi

# File tests
echo -e "\nFile test examples:"
if [ -f "01_conditionals.sh" ]; then
    echo "This script file exists"
fi

if [ -d "../01_fundamentals" ]; then
    echo "Fundamentals directory exists"
fi

# Combining conditions with AND
echo -e "\nAND condition example:"
age=25
has_license=true
if [ $age -ge 18 ] && [ "$has_license" = true ]; then
    echo "You can drive"
fi

# Combining conditions with OR
echo -e "\nOR condition example:"
day="Sunday"
if [ "$day" = "Saturday" ] || [ "$day" = "Sunday" ]; then
    echo "It's the weekend!"
fi

# Case statement
echo -e "\nCase statement example:"
fruit="apple"
case $fruit in
    "apple")
        echo "Selected fruit is an apple"
        ;;
    "banana")
        echo "Selected fruit is a banana"
        ;;
    "orange")
        echo "Selected fruit is an orange"
        ;;
    *)
        echo "Unknown fruit"
        ;;
esac

# Advanced case statement with patterns
echo -e "\nCase statement with patterns:"
read -p "Enter a character: " char
case $char in
    [0-9])
        echo "You entered a digit"
        ;;
    [a-z])
        echo "You entered a lowercase letter"
        ;;
    [A-Z])
        echo "You entered an uppercase letter"
        ;;
    *)
        echo "You entered a special character"
        ;;
esac

# Testing multiple conditions
echo -e "\nTesting multiple conditions:"
file="test.txt"
if [ -f "$file" ] && [ -r "$file" ] && [ -w "$file" ]; then
    echo "$file exists and is readable and writable"
elif [ -f "$file" ]; then
    echo "$file exists but may not have proper permissions"
else
    echo "$file does not exist"
fi
