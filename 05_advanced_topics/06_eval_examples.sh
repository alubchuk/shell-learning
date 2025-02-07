#!/bin/bash

# Examples of using eval command in shell scripting
# WARNING: eval can be dangerous if used with untrusted input
# Always sanitize and validate input before using eval

# Basic eval example
echo "1. Basic eval usage:"
var="hello"
cmd="echo \$var"
echo "Command string: $cmd"
eval "$cmd"
echo

# Dynamic variable names
echo "2. Dynamic variable names:"
prefix="MY_VAR"
for i in {1..3}; do
    varname="${prefix}_${i}"
    eval "$varname='value$i'"
    eval "echo \$$varname"
done
echo

# Command composition
echo "3. Command composition:"
operation="addition"
num1=5
num2=3

case "$operation" in
    "addition")
        cmd="echo \$(($num1 + $num2))"
        ;;
    "multiplication")
        cmd="echo \$(($num1 * $num2))"
        ;;
esac
echo "Performing $operation: "
eval "$cmd"
echo

# Environment variable expansion
echo "4. Environment variable expansion:"
env_var="PATH"
eval "echo Current \$$env_var"
echo

# Function creation
echo "5. Dynamic function creation:"
func_name="dynamic_func"
func_body="echo 'This is a dynamic function'; echo 'Created at runtime'"
eval "function $func_name() { $func_body; }"
$func_name
echo

# Complex command construction
echo "6. Complex command construction:"
files="file1.txt file2.txt file3.txt"
action="ls"
options="-l"
cmd="$action $options $files 2>/dev/null"
echo "Executing: $cmd"
eval "$cmd"
echo

# Indirect reference to arrays
echo "7. Array manipulation:"
declare -a array1=("one" "two" "three")
array_name="array1"
eval "echo \${${array_name}[@]}"
echo

# Dynamic assignment with validation
echo "8. Safe dynamic assignment:"
safe_assign() {
    local var_name="$1"
    local value="$2"
    
    # Validate variable name
    if [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo "Invalid variable name: $var_name"
        return 1
    }
    
    # Validate value (example: only allow alphanumeric)
    if [[ ! "$value" =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "Invalid value: $value"
        return 1
    }
    
    eval "$var_name='$value'"
    echo "Assigned: $var_name = $value"
}

safe_assign "valid_var" "123"
safe_assign "invalid!var" "abc"  # Should fail
safe_assign "valid_var" "invalid;value"  # Should fail
echo

# Command string building
echo "9. Building complex commands:"
build_find_command() {
    local dir="$1"
    local pattern="$2"
    local action="$3"
    
    cmd="find $dir"
    [ -n "$pattern" ] && cmd="$cmd -name '$pattern'"
    [ -n "$action" ] && cmd="$cmd -exec $action {} \\;"
    
    echo "Generated command: $cmd"
    eval "$cmd"
}

build_find_command "." "*.txt" "ls -l"
echo

# WARNING section
echo "10. Security considerations:"
echo "NEVER use eval with untrusted input!"
echo "Bad example (DO NOT USE):"
echo 'eval "echo $user_input"  # Dangerous!'
echo
echo "Instead, use proper parameter expansion and quoting:"
echo 'echo "$user_input"  # Safe'
