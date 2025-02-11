#!/bin/bash

# =============================================================================
# Shell Script Error Handling Examples
# This script demonstrates comprehensive error handling techniques for shell
# scripts, including error trapping, cleanup, and recovery strategies.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Error Handling Setup
# -----------------------------------------------------------------------------

# Error message function
error() {
    local message=$1
    local code=${2:-1}
    local line=${3:-$BASH_LINENO[0]}
    echo "ERROR: $message (line $line)" >&2
    exit "$code"
}

# Warning message function
warn() {
    local message=$1
    echo "WARNING: $message" >&2
}

# Debug message function
debug() {
    if [ "${DEBUG:-0}" = "1" ]; then
        local message=$1
        echo "DEBUG: $message" >&2
    fi
}

# Set up error trap
trap 'error "Command failed" $? $LINENO' ERR

# Set up exit trap for cleanup
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Cleanup Functions
# -----------------------------------------------------------------------------

# Initialize cleanup array
declare -a CLEANUP_FUNCTIONS=()

# Add cleanup function
add_cleanup() {
    local func=$1
    CLEANUP_FUNCTIONS+=("$func")
}

# Run cleanup functions
cleanup() {
    local exit_code=$?
    
    # Run cleanup functions in reverse order
    for ((i=${#CLEANUP_FUNCTIONS[@]}-1; i>=0; i--)); do
        ${CLEANUP_FUNCTIONS[i]} || true
    done
    
    exit "$exit_code"
}

# Example cleanup function for temporary files
cleanup_temp_files() {
    debug "Cleaning up temporary files"
    rm -f /tmp/example.*
}

# Example cleanup function for temporary directories
cleanup_temp_dirs() {
    debug "Cleaning up temporary directories"
    rm -rf /tmp/example/
}

# Example cleanup function for background processes
cleanup_processes() {
    debug "Cleaning up background processes"
    jobs -p | xargs kill -9 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Error Recovery Strategies
# -----------------------------------------------------------------------------

# Retry function with exponential backoff
retry() {
    local tries=$1
    local cmd=${*:2}
    local try=1
    local wait=1
    
    until "$cmd"; do
        exit_code=$?
        
        if ((try >= tries)); then
            error "Command failed after $tries attempts: $cmd" "$exit_code"
        fi
        
        warn "Attempt $try failed. Retrying in $wait seconds..."
        sleep "$wait"
        
        ((try++))
        ((wait *= 2))
    done
}

# Fallback function
fallback() {
    local primary_cmd=$1
    local fallback_cmd=$2
    
    if ! eval "$primary_cmd"; then
        warn "Primary command failed, trying fallback"
        eval "$fallback_cmd"
    fi
}

# Safe command execution with timeout
safe_exec() {
    local timeout=$1
    local cmd=${*:2}
    
    # Create temporary files for output and exit code
    local output_file
    output_file=$(mktemp)
    add_cleanup "rm -f $output_file"
    
    local exit_code_file
    exit_code_file=$(mktemp)
    add_cleanup "rm -f $exit_code_file"
    
    # Run command with timeout
    (
        "$cmd" > "$output_file" 2>&1
        echo $? > "$exit_code_file"
    ) & pid=$!
    
    # Wait for command with timeout
    if ! wait_pid "$pid" "$timeout"; then
        kill -9 "$pid" 2>/dev/null || true
        error "Command timed out after $timeout seconds: $cmd"
    fi
    
    # Check exit code
    local exit_code
    exit_code=$(<"$exit_code_file")
    
    if [ "$exit_code" -ne 0 ]; then
        error "Command failed with exit code $exit_code: $cmd"
    fi
    
    cat "$output_file"
}

# Wait for process with timeout
wait_pid() {
    local pid=$1
    local timeout=$2
    local count=0
    
    while kill -0 "$pid" 2>/dev/null; do
        if [ "$count" -ge "$timeout" ]; then
            return 1
        fi
        sleep 1
        ((count++))
    done
    
    return 0
}

# -----------------------------------------------------------------------------
# Input Validation
# -----------------------------------------------------------------------------

# Validate integer
validate_int() {
    local value=$1
    local min=${2:-}
    local max=${3:-}
    
    if ! [[ $value =~ ^[0-9]+$ ]]; then
        error "Invalid integer: $value"
    fi
    
    if [ -n "$min" ] && [ "$value" -lt "$min" ]; then
        error "Value $value is less than minimum $min"
    fi
    
    if [ -n "$max" ] && [ "$value" -gt "$max" ]; then
        error "Value $value is greater than maximum $max"
    fi
}

# Validate string
validate_string() {
    local value=$1
    local pattern=${2:-}
    local min_length=${3:-}
    local max_length=${4:-}
    
    if [ -z "$value" ]; then
        error "Empty string not allowed"
    fi
    
    if [ -n "$pattern" ] && ! [[ $value =~ $pattern ]]; then
        error "String does not match pattern: $pattern"
    fi
    
    local length=${#value}
    
    if [ -n "$min_length" ] && [ "$length" -lt "$min_length" ]; then
        error "String length $length is less than minimum $min_length"
    fi
    
    if [ -n "$max_length" ] && [ "$length" -gt "$max_length" ]; then
        error "String length $length is greater than maximum $max_length"
    fi
}

# Validate file
validate_file() {
    local file=$1
    local size_limit=${2:-}
    local mime_type=${3:-}
    
    if [ ! -f "$file" ]; then
        error "File not found: $file"
    fi
    
    if [ ! -r "$file" ]; then
        error "File not readable: $file"
    fi
    
    if [ -n "$size_limit" ]; then
        local size
        size=$(stat -f %z "$file")
        
        if [ "$size" -gt "$size_limit" ]; then
            error "File size $size exceeds limit $size_limit"
        fi
    fi
    
    if [ -n "$mime_type" ] && command -v file >/dev/null 2>&1; then
        local actual_type
        actual_type=$(file --mime-type -b "$file")
        
        if [ "$actual_type" != "$mime_type" ]; then
            error "Invalid file type: $actual_type (expected $mime_type)"
        fi
    fi
}

# -----------------------------------------------------------------------------
# Error Recovery Examples
# -----------------------------------------------------------------------------

# Example: File operations with recovery
safe_file_operation() {
    local source=$1
    local dest=$2
    
    # Validate inputs
    validate_file "$source"
    
    # Create backup
    local backup
    backup="${dest}.bak"
    
    # Cleanup function
    cleanup_file_op() {
        if [ -f "$backup" ]; then
            debug "Restoring backup: $backup"
            mv "$backup" "$dest"
        fi
    }
    add_cleanup cleanup_file_op
    
    # Perform operation with recovery
    if [ -f "$dest" ]; then
        cp "$dest" "$backup"
    fi
    
    if ! cp "$source" "$dest"; then
        error "Failed to copy $source to $dest"
    fi
}

# Example: Network operation with retry
safe_network_operation() {
    local url=$1
    local output=$2
    
    # Validate URL format
    validate_string "$url" "^https?://"
    
    # Try curl first, fall back to wget
    fallback \
        "curl -sSL '$url' -o '$output'" \
        "wget -q '$url' -O '$output'"
}

# Example: Database operation with transaction
safe_db_operation() {
    local db=$1
    local sql=$2
    
    # Start transaction
    echo "BEGIN;" > /tmp/transaction.sql
    echo "$sql" >> /tmp/transaction.sql
    echo "COMMIT;" >> /tmp/transaction.sql
    
    # Execute with retry
    retry 3 sqlite3 "$db" < /tmp/transaction.sql
    
    # Cleanup
    rm -f /tmp/transaction.sql
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    echo "Starting error handling demonstration..."
    
    # Set up cleanup
    add_cleanup cleanup_temp_files
    add_cleanup cleanup_temp_dirs
    add_cleanup cleanup_processes
    
    # Example 1: Input validation
    echo -e "\n1. Input validation example:"
    validate_int "42" 0 100
    validate_string "example@email.com" "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    
    # Example 2: Safe file operation
    echo -e "\n2. Safe file operation example:"
    echo "test content" > /tmp/example.txt
    safe_file_operation /tmp/example.txt /tmp/example.out
    
    # Example 3: Network operation with retry
    echo -e "\n3. Network operation example:"
    safe_network_operation "https://example.com" "/tmp/example.html"
    
    # Example 4: Command execution with timeout
    echo -e "\n4. Safe command execution example:"
    safe_exec 5 "sleep 3 && echo 'Command completed'"
    
    # Example 5: Database operation with transaction
    echo -e "\n5. Database operation example:"
    sqlite3 /tmp/example.db "CREATE TABLE IF NOT EXISTS test (id INTEGER PRIMARY KEY)"
    safe_db_operation /tmp/example.db "INSERT INTO test VALUES (1)"
    
    echo -e "\nError handling demonstration completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
