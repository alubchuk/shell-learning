#!/bin/bash

# Trap Examples
# ----------
# This script demonstrates various uses of the trap command
# for signal handling and cleanup operations.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEMP_DIR="$OUTPUT_DIR/temp"
readonly LOG_FILE="$OUTPUT_DIR/trap.log"

# 1. Basic Signal Trapping
# -------------------

basic_trap_example() {
    echo "Basic Signal Trapping:"
    echo "-------------------"
    
    # Setup trap for Ctrl+C (SIGINT)
    trap 'echo "Ctrl+C pressed - ignoring"' INT
    
    echo "Try pressing Ctrl+C..."
    for i in {1..5}; do
        echo "Counting: $i"
        sleep 1
    done
    
    # Remove the trap
    trap - INT
    echo "Trap removed - Ctrl+C will now terminate the script"
}

# 2. Cleanup Operations
# ----------------

cleanup_example() {
    echo "Cleanup Operations:"
    echo "-----------------"
    
    # Create temporary files
    mkdir -p "$TEMP_DIR"
    local temp_file1="$TEMP_DIR/temp1.txt"
    local temp_file2="$TEMP_DIR/temp2.txt"
    
    echo "Data 1" > "$temp_file1"
    echo "Data 2" > "$temp_file2"
    
    # Setup cleanup trap
    trap 'echo "Cleaning up..."; rm -rf "$TEMP_DIR"' EXIT
    
    echo "Created temporary files:"
    ls -l "$TEMP_DIR"
    
    echo "Script will clean up on exit..."
    sleep 2
}

# 3. Multiple Signal Handlers
# ---------------------

multiple_handlers() {
    echo "Multiple Signal Handlers:"
    echo "----------------------"
    
    # Setup multiple traps
    trap 'echo "INT signal received"' INT
    trap 'echo "TERM signal received"; exit 1' TERM
    trap 'echo "USR1 signal received"' USR1
    trap 'echo "USR2 signal received"' USR2
    
    echo "Process ID: $$"
    echo "Try sending different signals:"
    echo "kill -USR1 $$"
    echo "kill -USR2 $$"
    echo "kill -TERM $$"
    
    while true; do
        sleep 1
    done
}

# 4. Nested Traps
# ----------

nested_traps() {
    echo "Nested Traps:"
    echo "------------"
    
    # Outer trap
    trap 'echo "Outer trap: Cleaning up..."' EXIT
    
    # Inner function with its own trap
    inner_function() {
        trap 'echo "Inner trap: Cleaning up..."' EXIT
        echo "Inner function running..."
        exit 0
    }
    
    echo "Calling inner function..."
    inner_function
    echo "This won't be reached"
}

# 5. Trap Debugging
# -----------

debug_trap() {
    echo "Trap Debugging:"
    echo "--------------"
    
    # Setup DEBUG trap
    trap 'echo "Executing line: $BASH_COMMAND"' DEBUG
    
    # Some commands to debug
    echo "Command 1"
    ls -l
    echo "Command 3"
    
    # Remove DEBUG trap
    trap - DEBUG
}

# 6. Error Handling
# -----------

error_handling() {
    echo "Error Handling:"
    echo "--------------"
    
    # Setup error trap
    trap 'echo "Error on line $LINENO. Exit code: $?"' ERR
    
    # Some commands that might fail
    echo "Testing error handling..."
    ls /nonexistent/directory 2>/dev/null
    cat /nonexistent/file 2>/dev/null
    
    echo "Continuing after errors..."
}

# 7. Practical Examples
# ----------------

# Temporary file manager
manage_temp_files() {
    echo "Temporary File Management:"
    echo "-----------------------"
    
    # Array to track temporary files
    declare -a temp_files=()
    
    # Cleanup function
    cleanup() {
        echo "Cleaning up temporary files..."
        for file in "${temp_files[@]}"; do
            echo "Removing: $file"
            rm -f "$file"
        done
    }
    
    # Setup cleanup trap
    trap cleanup EXIT
    
    # Create some temporary files
    for i in {1..3}; do
        temp_file="$(mktemp)"
        temp_files+=("$temp_file")
        echo "Created: $temp_file"
        echo "Data $i" > "$temp_file"
    done
    
    echo "Working with temporary files..."
    sleep 2
}

# Process supervisor with graceful shutdown
supervise_process() {
    echo "Process Supervisor:"
    echo "-----------------"
    
    # Cleanup function
    cleanup() {
        echo "Shutting down supervised processes..."
        pkill -P $$
        wait
    }
    
    # Setup cleanup trap
    trap cleanup EXIT INT TERM
    
    # Start some background processes
    echo "Starting background processes..."
    sleep 100 &
    sleep 100 &
    sleep 100 &
    
    echo "Processes started. Process tree:"
    pstree -p $$
    
    echo "Waiting for processes (will clean up on exit)..."
    sleep 5
}

# Resource lock manager
manage_locks() {
    echo "Resource Lock Management:"
    echo "----------------------"
    
    local lock_file="$TEMP_DIR/resource.lock"
    mkdir -p "$TEMP_DIR"
    
    # Cleanup function
    cleanup() {
        echo "Removing lock file..."
        rm -f "$lock_file"
    }
    
    # Setup cleanup trap
    trap cleanup EXIT
    
    # Create lock
    echo "$$" > "$lock_file"
    echo "Lock acquired: $lock_file"
    
    echo "Working with locked resource..."
    sleep 2
}

# Main execution
main() {
    # Ensure log directory exists
    mkdir -p "$OUTPUT_DIR"
    
    # Basic examples
    basic_trap_example
    echo -e "\n"
    
    cleanup_example
    echo -e "\n"
    
    # Debug example
    debug_trap
    echo -e "\n"
    
    # Error handling
    error_handling
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    manage_temp_files
    echo -e "\n"
    
    manage_locks
    echo -e "\n"
    
    # Note: These examples run indefinitely until interrupted
    echo "Running supervisors (Ctrl+C to stop)..."
    supervise_process
    
    multiple_handlers
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
