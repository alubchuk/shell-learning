#!/bin/bash

# Function Examples
# ---------------

# Basic function
echo "Basic function example:"
hello() {
    echo "Hello, World!"
}

# Call the function
hello

# Function with parameters
echo -e "\nFunction with parameters:"
greet() {
    echo "Hello, $1! How are you $2?"
}

# Call function with parameters
greet "John" "today"

# Function with return value
echo -e "\nFunction with return value:"
is_even() {
    if [ $((${1} % 2)) -eq 0 ]; then
        return 0  # true in shell
    else
        return 1  # false in shell
    fi
}

# Use the function
number=4
if is_even $number; then
    echo "$number is even"
else
    echo "$number is odd"
fi

# Function with local variables
echo -e "\nFunction with local variables:"
demonstrate_scope() {
    local local_var="I am local"
    global_var="I am global"
    echo "Inside function: $local_var"
    echo "Inside function: $global_var"
}

demonstrate_scope
echo "Outside function: $global_var"
echo "Outside function: $local_var (should be empty)"

# Function that outputs a value
echo -e "\nFunction that outputs a value:"
get_square() {
    local num=$1
    echo $((num * num))
}

# Capture function output
result=$(get_square 5)
echo "Square of 5 is $result"

# Function with default parameter
echo -e "\nFunction with default parameter:"
greet_user() {
    local name=${1:-"Guest"}  # Default to "Guest" if no parameter
    echo "Welcome, $name!"
}

greet_user
greet_user "Alice"

# Function with variable number of arguments
echo -e "\nFunction with variable arguments:"
print_args() {
    echo "Number of arguments: $#"
    echo "All arguments: $@"
    for arg in "$@"; do
        echo "Argument: $arg"
    done
}

print_args apple banana orange

# Function with error handling
echo -e "\nFunction with error handling:"
divide() {
    if [ $2 -eq 0 ]; then
        echo "Error: Division by zero!" >&2
        return 1
    fi
    echo $((${1} / ${2}))
    return 0
}

# Test the divide function
if result=$(divide 10 2); then
    echo "10 divided by 2 is $result"
fi

if ! result=$(divide 10 0); then
    echo "Division failed"
fi

# Recursive function
echo -e "\nRecursive function example:"
factorial() {
    if [ $1 -le 1 ]; then
        echo 1
    else
        local temp=$(factorial $(($1 - 1)))
        echo $(($1 * $temp))
    fi
}

echo "Factorial of 5 is $(factorial 5)"

# Function that modifies an array
echo -e "\nFunction modifying an array:"
modify_array() {
    local -n arr=$1  # Reference to the array
    arr[0]="modified"
}

my_array=("original" "value")
echo "Before: ${my_array[0]}"
modify_array my_array
echo "After: ${my_array[0]}"
