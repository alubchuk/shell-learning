#!/bin/bash

# =============================================================================
# Memory Optimization Examples
# This script demonstrates techniques for optimizing memory usage in shell scripts,
# including variable scope management, array optimization, and resource cleanup.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: demonstrate_variable_scope
# Purpose: Show the impact of variable scope on memory usage
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_variable_scope() {
    echo "=== Variable Scope Example ==="
    
    # BAD: Global variable persists in memory
    echo "Bad practice (global variables):"
    GLOBAL_DATA=""
    for i in {1..1000}; do
        GLOBAL_DATA+="some data "
    done
    echo "Global variable size: $(echo -n "$GLOBAL_DATA" | wc -c) bytes"
    
    # GOOD: Local variable is cleaned up after function exits
    echo -e "\nGood practice (local variables):"
    local_scope_example() {
        local local_data=""
        for i in {1..1000}; do
            local_data+="some data "
        done
        echo "Local variable size: $(echo -n "$local_data" | wc -c) bytes"
    }
    local_scope_example
    # local_data is not accessible here, memory is freed
}

# -----------------------------------------------------------------------------
# Function: optimize_array_operations
# Purpose: Demonstrate memory-efficient array operations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_array_operations() {
    echo -e "\n=== Array Optimization Example ==="
    
    # BAD: Creating unnecessary copies
    echo "Bad practice (array copying):"
    local -a original=({1..1000})
    local start_mem=$(ps -o rss= -p $$)
    
    local -a copy1=("${original[@]}")  # Creates full copy
    local -a copy2=("${copy1[@]}")     # Creates another copy
    
    local end_mem=$(ps -o rss= -p $$)
    echo "Memory usage with copies: $((end_mem - start_mem)) KB"
    
    # GOOD: Using references and slices
    echo -e "\nGood practice (references and slices):"
    start_mem=$(ps -o rss= -p $$)
    
    # Use slices instead of full copies
    local -a slice1=("${original[@]:0:500}")
    local -a slice2=("${original[@]:500}")
    
    end_mem=$(ps -o rss= -p $$)
    echo "Memory usage with slices: $((end_mem - start_mem)) KB"
}

# -----------------------------------------------------------------------------
# Function: manage_file_descriptors
# Purpose: Show proper file descriptor management
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
manage_file_descriptors() {
    echo -e "\n=== File Descriptor Management Example ==="
    
    # BAD: Leaving file descriptors open
    echo "Bad practice (unclosed file descriptors):"
    exec 3< <(seq 1 1000)
    # File descriptor 3 remains open
    
    # GOOD: Properly closing file descriptors
    echo -e "\nGood practice (proper cleanup):"
    {
        exec 4< <(seq 1 1000)
        # Process data
        while read -r line <&4; do
            : # Process line
        done
    } 4<&-  # Close FD 4
}

# -----------------------------------------------------------------------------
# Function: optimize_subshell_usage
# Purpose: Demonstrate efficient subshell usage
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_subshell_usage() {
    echo -e "\n=== Subshell Optimization Example ==="
    
    # BAD: Excessive subshells
    echo "Bad practice (multiple subshells):"
    local start_time=$SECONDS
    
    for i in {1..100}; do
        result=$(echo "Processing $i" | grep "Processing" | cut -d' ' -f2)
    done
    
    echo "Time with multiple subshells: $((SECONDS - start_time)) seconds"
    
    # GOOD: Minimized subshells
    echo -e "\nGood practice (minimized subshells):"
    start_time=$SECONDS
    
    for i in {1..100}; do
        # Use parameter expansion instead of multiple subshells
        result=${i}
    done
    
    echo "Time with optimized code: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: cleanup_resources
# Purpose: Demonstrate proper resource cleanup
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
cleanup_resources() {
    echo -e "\n=== Resource Cleanup Example ==="
    
    # Set up cleanup trap
    cleanup() {
        echo "Cleaning up resources..."
        # Close any remaining file descriptors
        for fd in {3..10}; do
            exec {fd}>&- 2>/dev/null || true
        done
        # Remove temporary files
        rm -f /tmp/test_*.tmp
    }
    trap cleanup EXIT
    
    # Create some temporary resources
    echo "Creating temporary resources..."
    echo "test data" > /tmp/test_1.tmp
    echo "more data" > /tmp/test_2.tmp
    
    # Resources will be automatically cleaned up when script exits
}

# -----------------------------------------------------------------------------
# Function: monitor_memory_usage
# Purpose: Monitor memory usage of different operations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
monitor_memory_usage() {
    echo -e "\n=== Memory Usage Monitoring ==="
    
    monitor_operation() {
        local operation="$1"
        local start_mem=$(ps -o rss= -p $$)
        
        eval "$operation"
        
        local end_mem=$(ps -o rss= -p $$)
        echo "Memory delta for '$operation': $((end_mem - start_mem)) KB"
    }
    
    # Monitor different operations
    monitor_operation 'local -a arr=({1..10000})'
    monitor_operation 'local data=$(yes "test" | head -n 10000)'
    monitor_operation 'local str=""; for i in {1..10000}; do str+="a"; done'
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting memory optimization examples..."
    
    # Run all demonstrations
    demonstrate_variable_scope
    optimize_array_operations
    manage_file_descriptors
    optimize_subshell_usage
    cleanup_resources
    monitor_memory_usage
    
    echo -e "\nMemory optimization examples completed."
}

# Run main function
main
