#!/bin/bash

# =============================================================================
# CPU Usage Optimization Examples
# This script demonstrates techniques for optimizing CPU usage in shell scripts,
# including loop optimization, command substitution, and process management.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: optimize_loops
# Purpose: Demonstrate loop optimization techniques
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_loops() {
    echo "=== Loop Optimization Example ==="
    
    # BAD: Inefficient loop with multiple commands
    echo "Bad practice (inefficient loop):"
    local start_time=$SECONDS
    
    for i in {1..1000}; do
        echo "$i" > /dev/null
        date > /dev/null
        hostname > /dev/null
    done
    
    echo "Time with inefficient loop: $((SECONDS - start_time)) seconds"
    
    # GOOD: Optimized loop with minimized commands
    echo -e "\nGood practice (optimized loop):"
    start_time=$SECONDS
    
    # Pre-calculate static values
    local host=$(hostname)
    for i in {1..1000}; do
        printf "%d %s\n" "$i" "$host" > /dev/null
    done
    
    echo "Time with optimized loop: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: optimize_command_substitution
# Purpose: Show efficient command substitution techniques
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_command_substitution() {
    echo -e "\n=== Command Substitution Optimization ==="
    
    # BAD: Multiple command substitutions
    echo "Bad practice (multiple substitutions):"
    local start_time=$SECONDS
    
    for i in {1..100}; do
        local date=$(date)
        local time=$(echo "$date" | cut -d' ' -f4)
        local hour=$(echo "$time" | cut -d: -f1)
    done
    
    echo "Time with multiple substitutions: $((SECONDS - start_time)) seconds"
    
    # GOOD: Single command substitution with parameter expansion
    echo -e "\nGood practice (optimized substitution):"
    start_time=$SECONDS
    
    for i in {1..100}; do
        local date=$(date)
        local time=${date##* }
        local hour=${time%%:*}
    done
    
    echo "Time with optimized substitution: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: optimize_process_creation
# Purpose: Demonstrate process creation optimization
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_process_creation() {
    echo -e "\n=== Process Creation Optimization ==="
    
    # BAD: Creating new process for each iteration
    echo "Bad practice (excessive processes):"
    local start_time=$SECONDS
    
    for i in {1..100}; do
        echo "$i" | grep -q "[0-9]"
    done
    
    echo "Time with excessive processes: $((SECONDS - start_time)) seconds"
    
    # GOOD: Using built-in commands and regex
    echo -e "\nGood practice (minimized processes):"
    start_time=$SECONDS
    
    for i in {1..100}; do
        [[ $i =~ ^[0-9]+$ ]]
    done
    
    echo "Time with minimized processes: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: use_builtin_commands
# Purpose: Show the advantage of using shell built-ins
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
use_builtin_commands() {
    echo -e "\n=== Built-in Command Usage ==="
    
    # BAD: Using external commands
    echo "Bad practice (external commands):"
    local start_time=$SECONDS
    
    for i in {1..1000}; do
        echo "$i" | tr -d '\n' > /dev/null
        echo "$i" | cut -c1 > /dev/null
    done
    
    echo "Time with external commands: $((SECONDS - start_time)) seconds"
    
    # GOOD: Using built-in commands
    echo -e "\nGood practice (built-in commands):"
    start_time=$SECONDS
    
    for i in {1..1000}; do
        printf "%d" "$i" > /dev/null
        echo "${i:0:1}" > /dev/null
    done
    
    echo "Time with built-in commands: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: optimize_arithmetic
# Purpose: Demonstrate arithmetic operation optimization
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_arithmetic() {
    echo -e "\n=== Arithmetic Optimization ==="
    
    # BAD: Using expr or external commands
    echo "Bad practice (external arithmetic):"
    local start_time=$SECONDS
    
    for i in {1..1000}; do
        result=$(expr $i + 5)
        result=$(echo "$i * 2" | bc)
    done
    
    echo "Time with external arithmetic: $((SECONDS - start_time)) seconds"
    
    # GOOD: Using shell arithmetic
    echo -e "\nGood practice (shell arithmetic):"
    start_time=$SECONDS
    
    for i in {1..1000}; do
        result=$((i + 5))
        result=$((i * 2))
    done
    
    echo "Time with shell arithmetic: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: parallel_processing
# Purpose: Show how to use parallel processing effectively
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
parallel_processing() {
    echo -e "\n=== Parallel Processing Example ==="
    
    # Function to process a single item
    process_item() {
        local item=$1
        sleep 0.1  # Simulate work
        echo "Processed $item"
    }
    
    # BAD: Sequential processing
    echo "Bad practice (sequential processing):"
    local start_time=$SECONDS
    
    for i in {1..10}; do
        process_item "$i"
    done
    
    echo "Time with sequential processing: $((SECONDS - start_time)) seconds"
    
    # GOOD: Parallel processing with job control
    echo -e "\nGood practice (parallel processing):"
    start_time=$SECONDS
    
    for i in {1..10}; do
        process_item "$i" &
    done
    wait  # Wait for all background jobs to complete
    
    echo "Time with parallel processing: $((SECONDS - start_time)) seconds"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting CPU optimization examples..."
    
    # Run all demonstrations
    optimize_loops
    optimize_command_substitution
    optimize_process_creation
    use_builtin_commands
    optimize_arithmetic
    parallel_processing
    
    echo -e "\nCPU optimization examples completed."
}

# Run main function
main
