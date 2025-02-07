#!/bin/bash

# Error Handling Examples
# ---------------------

# Enable debug mode with -d or --debug flag
if [[ "$1" == "-d" ]] || [[ "$1" == "--debug" ]]; then
    set -x  # Print each command before executing
fi

# Exit on error by default
set -e

# Exit on undefined variables
set -u

# Pipe failures are also errors
set -o pipefail

# Function to display section headers
print_header() {
    echo -e "\n=== $1 ==="
    echo "----------------"
}

# Error logging function
log_error() {
    local message="$1"
    local line="${2:-unknown}"
    local func="${3:-unknown}"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $func:$line - $message" >&2
}

# Warning logging function
log_warning() {
    local message="$1"
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $message" >&2
}

# Info logging function
log_info() {
    local message="$1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $message"
}

# Debug logging function
log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        local message="$1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $message"
    fi
}

# Error handler function
error_handler() {
    local line_num="$1"
    local command="$2"
    local error_code="${3:-1}"
    log_error "Command '$command' failed with error code $error_code" "$line_num" "${FUNCNAME[1]}"
}

# Set error trap
trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR

# 1. Basic Error Handling
print_header "Basic Error Handling"

# Function demonstrating basic error handling
basic_error_handling() {
    local file="$1"
    
    if [ -z "$file" ]; then
        log_error "File name is required" "${LINENO}" "${FUNCNAME[0]}"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log_error "File '$file' does not exist" "${LINENO}" "${FUNCNAME[0]}"
        return 2
    fi
    
    if [ ! -r "$file" ]; then
        log_error "File '$file' is not readable" "${LINENO}" "${FUNCNAME[0]}"
        return 3
    fi
    
    log_info "File '$file' is valid"
    return 0
}

# Test basic error handling
echo "Testing file validation..."
basic_error_handling ""
basic_error_handling "nonexistent.txt"
touch /tmp/test.txt
chmod 000 /tmp/test.txt
basic_error_handling "/tmp/test.txt"
rm -f /tmp/test.txt

# 2. Command Error Handling
print_header "Command Error Handling"

# Function demonstrating command error handling
command_error_handling() {
    local cmd="$1"
    local output
    
    # Capture both stdout and stderr
    if output=$(eval "$cmd" 2>&1); then
        log_info "Command succeeded: $cmd"
        echo "$output"
        return 0
    else
        local status=$?
        log_error "Command failed with status $status: $cmd" "${LINENO}" "${FUNCNAME[0]}"
        echo "Command output: $output" >&2
        return $status
    fi
}

# Test command error handling
echo "Testing commands..."
command_error_handling "ls /tmp"
command_error_handling "ls /nonexistent"

# 3. Function Result Validation
print_header "Function Result Validation"

# Function demonstrating result validation
validate_number() {
    local num="$1"
    local min="$2"
    local max="$3"
    
    # Validate input
    if [[ ! "$num" =~ ^[0-9]+$ ]]; then
        log_error "Invalid number: $num" "${LINENO}" "${FUNCNAME[0]}"
        return 1
    fi
    
    # Validate range
    if [ "$num" -lt "$min" ] || [ "$num" -gt "$max" ]; then
        log_error "Number $num is outside range [$min-$max]" "${LINENO}" "${FUNCNAME[0]}"
        return 2
    fi
    
    log_info "Number $num is valid"
    return 0
}

# Test number validation
echo "Testing number validation..."
validate_number "abc" 1 100
validate_number "50" 1 100
validate_number "200" 1 100

# 4. Resource Cleanup
print_header "Resource Cleanup"

# Function demonstrating resource cleanup
cleanup() {
    log_info "Performing cleanup..."
    rm -f /tmp/test_*.txt
}

# Set cleanup trap
trap cleanup EXIT

# Function demonstrating resource management
resource_management() {
    local tempfile=$(mktemp /tmp/test_XXXXXX.txt)
    log_info "Created temporary file: $tempfile"
    
    # Ensure tempfile is cleaned up on function exit
    trap 'rm -f "$tempfile"; log_info "Cleaned up: $tempfile"' RETURN
    
    # Use tempfile
    echo "test data" > "$tempfile"
    
    # Simulate error
    if [ "$1" = "fail" ]; then
        log_error "Simulated failure" "${LINENO}" "${FUNCNAME[0]}"
        return 1
    fi
    
    log_info "Resource management successful"
    return 0
}

# Test resource management
echo "Testing resource management..."
resource_management "success"
resource_management "fail"

# 5. Input Validation
print_header "Input Validation"

# Function demonstrating input validation
validate_input() {
    local name="$1"
    local age="$2"
    local email="$3"
    
    # Validate name
    if [[ ! "$name" =~ ^[a-zA-Z]+$ ]]; then
        log_error "Invalid name: $name" "${LINENO}" "${FUNCNAME[0]}"
        return 1
    fi
    
    # Validate age
    if [[ ! "$age" =~ ^[0-9]+$ ]] || [ "$age" -lt 0 ] || [ "$age" -gt 150 ]; then
        log_error "Invalid age: $age" "${LINENO}" "${FUNCNAME[0]}"
        return 2
    fi
    
    # Validate email
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        log_error "Invalid email: $email" "${LINENO}" "${FUNCNAME[0]}"
        return 3
    fi
    
    log_info "Input validation successful"
    return 0
}

# Test input validation
echo "Testing input validation..."
validate_input "John123" "25" "john@example.com"
validate_input "John" "abc" "john@example.com"
validate_input "John" "25" "invalid-email"

# 6. Error Recovery
print_header "Error Recovery"

# Function demonstrating error recovery
error_recovery() {
    local retries=3
    local wait=1
    local try=1
    
    while [ $try -le $retries ]; do
        log_info "Attempt $try of $retries"
        
        if command_error_handling "ls /tmp"; then
            log_info "Operation successful on attempt $try"
            return 0
        fi
        
        log_warning "Attempt $try failed, waiting $wait seconds before retry"
        sleep $wait
        ((try++))
        ((wait*=2))
    done
    
    log_error "Operation failed after $retries attempts" "${LINENO}" "${FUNCNAME[0]}"
    return 1
}

# Test error recovery
echo "Testing error recovery..."
error_recovery

# 7. Debug Information
print_header "Debug Information"

# Function demonstrating debug information
debug_example() {
    log_debug "Function started"
    log_debug "Arguments: $@"
    
    local result=0
    for arg in "$@"; do
        log_debug "Processing argument: $arg"
        result=$((result + arg))
    done
    
    log_debug "Result calculated: $result"
    echo $result
}

# Test debug information
echo "Testing debug information..."
DEBUG=true debug_example 1 2 3 4 5

# Keep script running to demonstrate error handling
echo -e "\nScript completed. Check the error handling examples above."
