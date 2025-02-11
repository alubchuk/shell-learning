#!/bin/bash

# =============================================================================
# Parallel Processing Examples
# This script demonstrates various techniques for parallel processing in shell scripts,
# including job control, GNU Parallel usage, and process pool implementation.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: demonstrate_job_control
# Purpose: Show basic job control techniques
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_job_control() {
    echo "=== Basic Job Control Example ==="
    
    # Function to simulate work
    do_work() {
        local id=$1
        local duration=$2
        sleep "$duration"
        echo "Job $id completed after $duration seconds"
    }
    
    # BAD: Sequential execution
    echo "Bad practice (sequential execution):"
    local start_time=$SECONDS
    
    for i in {1..5}; do
        do_work "$i" "1"
    done
    
    echo "Time with sequential execution: $((SECONDS - start_time)) seconds"
    
    # GOOD: Parallel execution with job control
    echo -e "\nGood practice (parallel execution):"
    start_time=$SECONDS
    
    # Start jobs in background
    for i in {1..5}; do
        do_work "$i" "1" &
    done
    
    # Wait for all jobs to complete
    wait
    
    echo "Time with parallel execution: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_gnu_parallel
# Purpose: Show GNU Parallel usage examples
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_gnu_parallel() {
    echo -e "\n=== GNU Parallel Example ==="
    
    # Check if GNU Parallel is installed
    if ! command -v parallel &>/dev/null; then
        echo "GNU Parallel not found. Please install it first."
        return 1
    }
    
    # Create test data
    seq 1 20 > /tmp/parallel_input.txt
    
    # Function to process items
    process_item() {
        local item=$1
        sleep 0.5  # Simulate work
        echo "Processed item $item"
    }
    export -f process_item
    
    # BAD: Sequential processing
    echo "Bad practice (sequential processing):"
    local start_time=$SECONDS
    
    while read -r item; do
        process_item "$item"
    done < /tmp/parallel_input.txt
    
    echo "Time with sequential processing: $((SECONDS - start_time)) seconds"
    
    # GOOD: Using GNU Parallel
    echo -e "\nGood practice (GNU Parallel):"
    start_time=$SECONDS
    
    parallel -j 4 process_item :::: /tmp/parallel_input.txt
    
    echo "Time with GNU Parallel: $((SECONDS - start_time)) seconds"
    
    # Clean up
    rm /tmp/parallel_input.txt
}

# -----------------------------------------------------------------------------
# Function: implement_process_pool
# Purpose: Demonstrate a simple process pool implementation
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
implement_process_pool() {
    echo -e "\n=== Process Pool Implementation ==="
    
    # Configuration
    local pool_size=4
    local total_tasks=16
    
    # Create a named pipe for job distribution
    local pipe="/tmp/process_pool_pipe"
    mkfifo "$pipe"
    
    # Start worker processes
    for ((i=1; i<=pool_size; i++)); do
        while read -r task; do
            # Process task
            sleep 0.5  # Simulate work
            echo "Worker $i completed task $task"
        done < "$pipe" &
    done
    
    # Distribute tasks
    for ((task=1; task<=total_tasks; task++)); do
        echo "$task" > "$pipe"
    done
    
    # Signal completion
    for ((i=1; i<=pool_size; i++)); do
        echo "DONE" > "$pipe"
    done
    
    # Wait for all workers to finish
    wait
    
    # Clean up
    rm "$pipe"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_xargs
# Purpose: Show parallel processing with xargs
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_xargs() {
    echo -e "\n=== xargs Parallel Processing ==="
    
    # Create test data
    seq 1 20 > /tmp/xargs_input.txt
    
    # Function to process items
    process_with_xargs() {
        local item=$1
        sleep 0.5  # Simulate work
        echo "Processed item $item"
    }
    export -f process_with_xargs
    
    # BAD: Sequential processing
    echo "Bad practice (sequential processing):"
    local start_time=$SECONDS
    
    while read -r item; do
        process_with_xargs "$item"
    done < /tmp/xargs_input.txt
    
    echo "Time with sequential processing: $((SECONDS - start_time)) seconds"
    
    # GOOD: Parallel processing with xargs
    echo -e "\nGood practice (xargs parallel):"
    start_time=$SECONDS
    
    xargs -P 4 -I {} bash -c 'process_with_xargs "$@"' _ {} < /tmp/xargs_input.txt
    
    echo "Time with xargs parallel: $((SECONDS - start_time)) seconds"
    
    # Clean up
    rm /tmp/xargs_input.txt
}

# -----------------------------------------------------------------------------
# Function: demonstrate_parallel_map
# Purpose: Implement a parallel map function
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_parallel_map() {
    echo -e "\n=== Parallel Map Implementation ==="
    
    # Parallel map function
    parallel_map() {
        local func=$1
        local max_jobs=${2:-4}
        local job_count=0
        
        # Read items from stdin
        while read -r item; do
            # Wait if we've reached max jobs
            if ((job_count >= max_jobs)); then
                wait -n
                ((job_count--))
            fi
            
            # Process item in background
            "$func" "$item" &
            ((job_count++))
        done
        
        # Wait for remaining jobs
        wait
    }
    
    # Test function
    process_item() {
        local item=$1
        sleep 0.5  # Simulate work
        echo "Mapped item $item"
    }
    
    # Generate test data
    seq 1 20 > /tmp/map_input.txt
    
    # BAD: Sequential mapping
    echo "Bad practice (sequential mapping):"
    local start_time=$SECONDS
    
    while read -r item; do
        process_item "$item"
    done < /tmp/map_input.txt
    
    echo "Time with sequential mapping: $((SECONDS - start_time)) seconds"
    
    # GOOD: Parallel mapping
    echo -e "\nGood practice (parallel mapping):"
    start_time=$SECONDS
    
    parallel_map process_item 4 < /tmp/map_input.txt
    
    echo "Time with parallel mapping: $((SECONDS - start_time)) seconds"
    
    # Clean up
    rm /tmp/map_input.txt
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting parallel processing examples..."
    
    # Run all demonstrations
    demonstrate_job_control
    demonstrate_gnu_parallel
    implement_process_pool
    demonstrate_xargs
    demonstrate_parallel_map
    
    echo -e "\nParallel processing examples completed."
}

# Run main function
main
