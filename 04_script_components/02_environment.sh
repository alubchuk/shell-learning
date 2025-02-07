#!/bin/bash

# Environment Variables Examples
# ---------------------------

# Function to display section headers
print_header() {
    echo -e "\n=== $1 ==="
    echo "----------------"
}

# 1. System Environment Variables
print_header "System Environment Variables"

echo "User Information:"
echo "Username: $USER"
echo "Home Directory: $HOME"
echo "Current Shell: $SHELL"
echo "User ID: $UID"

echo -e "\nSystem Paths:"
echo "Current Directory: $PWD"
echo "Previous Directory: $OLDPWD"
echo "Path: $PATH"

echo -e "\nSystem Information:"
echo "Hostname: $HOSTNAME"
echo "Terminal: $TERM"
echo "System Language: $LANG"

# 2. Process Information
print_header "Process Information"

echo "Script PID: $$"
echo "Parent PID: $PPID"
echo "Last Background PID: $!"
echo "Last Exit Code: $?"

# 3. Shell Variables
print_header "Shell Variables"

echo "Random number: $RANDOM"
echo "Number of seconds since shell started: $SECONDS"
echo "Shell options: $-"
echo "Shell version: $BASH_VERSION"

# 4. Custom Environment Variables
print_header "Custom Environment Variables"

# Set a local variable
MY_LOCAL_VAR="local value"
echo "Local variable: $MY_LOCAL_VAR"

# Export a variable to make it available to child processes
export MY_EXPORTED_VAR="exported value"
echo "Exported variable: $MY_EXPORTED_VAR"

# 5. Variable Scope Demonstration
print_header "Variable Scope Demonstration"

# Function to demonstrate variable scope
demo_scope() {
    local LOCAL_VAR="local to function"
    GLOBAL_VAR="global variable"
    echo "Inside function:"
    echo "  LOCAL_VAR: $LOCAL_VAR"
    echo "  GLOBAL_VAR: $GLOBAL_VAR"
    echo "  MY_LOCAL_VAR: $MY_LOCAL_VAR"
    echo "  MY_EXPORTED_VAR: $MY_EXPORTED_VAR"
}

demo_scope
echo -e "\nOutside function:"
echo "  LOCAL_VAR: $LOCAL_VAR (should be empty)"
echo "  GLOBAL_VAR: $GLOBAL_VAR"
echo "  MY_LOCAL_VAR: $MY_LOCAL_VAR"
echo "  MY_EXPORTED_VAR: $MY_EXPORTED_VAR"

# 6. Subshell Environment
print_header "Subshell Environment"

echo "Current shell PID: $$"
echo "Running subshell..."
(
    echo "Subshell PID: $$"
    echo "Parent PID: $PPID"
    echo "Inherited MY_EXPORTED_VAR: $MY_EXPORTED_VAR"
)

# 7. Environment Variable Operations
print_header "Environment Variable Operations"

# Check if variable exists
if [ -z "${UNDEFINED_VAR+x}" ]; then
    echo "UNDEFINED_VAR is not set"
else
    echo "UNDEFINED_VAR is set to: $UNDEFINED_VAR"
fi

# Variable with default value
echo "DEFAULT_VAR is: ${DEFAULT_VAR:-default value}"

# Assign default value if variable is unset
echo "ASSIGN_DEFAULT is: ${ASSIGN_DEFAULT:=new value}"
echo "ASSIGN_DEFAULT is now permanently set to: $ASSIGN_DEFAULT"

# Error if variable is unset
echo "Testing error on unset variable..."
# Commented out to avoid script termination
# echo "REQUIRED_VAR is: ${REQUIRED_VAR:?must be set}"

# 8. Path Manipulation
print_header "Path Manipulation"

# Add directory to PATH
NEW_PATH="/usr/local/new-bin"
echo "Original PATH segments:"
echo "$PATH" | tr ':' '\n'

echo -e "\nAdding $NEW_PATH to PATH..."
PATH="$NEW_PATH:$PATH"

echo -e "\nNew PATH segments:"
echo "$PATH" | tr ':' '\n'

# 9. Temporary Environment Changes
print_header "Temporary Environment Changes"

echo "Running command with temporary environment variables..."
CUSTOM_VAR="temporary" bash -c 'echo "CUSTOM_VAR inside command: $CUSTOM_VAR"'
echo "CUSTOM_VAR after command: $CUSTOM_VAR"

# 10. Environment Variable Best Practices
print_header "Environment Variable Best Practices"

# Use uppercase for environment variables
CONFIGURATION_FILE="/etc/myapp.conf"
echo "Configuration file: $CONFIGURATION_FILE"

# Quote variables to handle spaces and special characters
GREETING="Hello, World!"
echo "$GREETING"

# Use braces when concatenating
NAME="John"
echo "${NAME}'s script"

# Handle missing variables safely
echo "Missing variable with default: ${MISSING_VAR:-default}"

# 11. Current Environment Summary
print_header "Current Environment Summary"

echo "Number of environment variables: $(env | wc -l)"
echo -e "\nFirst 5 environment variables:"
env | sort | head -n 5
