#!/bin/bash

# Loop Structures Examples
# ----------------------

# Basic for loop with numbers
echo "For loop with numbers:"
for i in 1 2 3 4 5; do
    echo "Number: $i"
done

# For loop with sequence
echo -e "\nFor loop with sequence:"
for i in $(seq 1 3); do
    echo "Sequence number: $i"
done

# For loop with array
echo -e "\nFor loop with array:"
fruits=("apple" "banana" "orange" "grape")
for fruit in "${fruits[@]}"; do
    echo "Fruit: $fruit"
done

# C-style for loop
echo -e "\nC-style for loop:"
for ((i=0; i<5; i++)); do
    echo "Counter: $i"
done

# For loop with glob (files)
echo -e "\nFor loop with files:"
for file in *.sh; do
    echo "Script file: $file"
done

# While loop with counter
echo -e "\nWhile loop with counter:"
counter=1
while [ $counter -le 5 ]; do
    echo "While counter: $counter"
    ((counter++))
done

# While loop reading file line by line
echo -e "\nWhile loop reading file:"
echo -e "Line 1\nLine 2\nLine 3" > temp.txt
while IFS= read -r line; do
    echo "Read line: $line"
done < temp.txt
rm temp.txt

# While loop with user input
echo -e "\nWhile loop with user input:"
while true; do
    read -p "Enter a number (0 to exit): " num
    if [ "$num" = "0" ]; then
        echo "Exiting..."
        break
    fi
    echo "You entered: $num"
done

# Until loop example
echo -e "\nUntil loop example:"
num=1
until [ $num -gt 5 ]; do
    echo "Until number: $num"
    ((num++))
done

# Nested loops
echo -e "\nNested loops example:"
for ((i=1; i<=3; i++)); do
    for ((j=1; j<=3; j++)); do
        echo -n "($i,$j) "
    done
    echo    # New line
done

# Loop control statements
echo -e "\nLoop control statements:"
for num in {1..10}; do
    # Skip even numbers
    if [ $((num % 2)) -eq 0 ]; then
        continue
    fi
    # Stop at 7
    if [ $num -eq 7 ]; then
        break
    fi
    echo "Odd number: $num"
done

# While loop with select
echo -e "\nSelect menu example:"
select choice in "Option 1" "Option 2" "Quit"; do
    case $choice in
        "Option 1")
            echo "You selected Option 1"
            ;;
        "Option 2")
            echo "You selected Option 2"
            ;;
        "Quit")
            echo "Exiting..."
            break
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done
