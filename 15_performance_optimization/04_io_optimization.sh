#!/bin/bash

# =============================================================================
# I/O Performance Optimization Examples
# This script demonstrates techniques for optimizing I/O operations in shell scripts,
# including efficient file reading, write buffering, and pipeline optimization.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: optimize_file_reading
# Purpose: Demonstrate efficient file reading techniques
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_file_reading() {
    echo "=== File Reading Optimization ==="
    
    # Create a test file
    local test_file="/tmp/test_data.txt"
    seq 1 100000 > "$test_file"
    
    # BAD: Reading line by line with cat
    echo "Bad practice (cat with while read):"
    local start_time=$SECONDS
    
    local count=0
    cat "$test_file" | while read -r line; do
        ((count++))
    done
    
    echo "Time with cat pipe: $((SECONDS - start_time)) seconds"
    
    # GOOD: Direct file redirection
    echo -e "\nGood practice (direct redirection):"
    start_time=$SECONDS
    
    count=0
    while read -r line; do
        ((count++))
    done < "$test_file"
    
    echo "Time with direct redirection: $((SECONDS - start_time)) seconds"
    
    # BETTER: Reading in chunks
    echo -e "\nBetter practice (chunk reading):"
    start_time=$SECONDS
    
    count=0
    while read -r -n 65536 chunk; do
        count=$((count + $(echo "$chunk" | wc -l)))
    done < "$test_file"
    
    echo "Time with chunk reading: $((SECONDS - start_time)) seconds"
    
    # Clean up
    rm "$test_file"
}

# -----------------------------------------------------------------------------
# Function: optimize_write_operations
# Purpose: Show efficient file writing techniques
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_write_operations() {
    echo -e "\n=== Write Operation Optimization ==="
    
    # BAD: Writing line by line
    echo "Bad practice (line by line writing):"
    local start_time=$SECONDS
    
    for i in {1..10000}; do
        echo "$i" >> /tmp/output1.txt
    done
    
    echo "Time with line by line writing: $((SECONDS - start_time)) seconds"
    
    # GOOD: Buffered writing
    echo -e "\nGood practice (buffered writing):"
    start_time=$SECONDS
    
    {
        for i in {1..10000}; do
            echo "$i"
        done
    } > /tmp/output2.txt
    
    echo "Time with buffered writing: $((SECONDS - start_time)) seconds"
    
    # BETTER: Using printf with array
    echo -e "\nBetter practice (printf with array):"
    start_time=$SECONDS
    
    printf '%d\n' {1..10000} > /tmp/output3.txt
    
    echo "Time with printf: $((SECONDS - start_time)) seconds"
    
    # Clean up
    rm /tmp/output{1,2,3}.txt
}

# -----------------------------------------------------------------------------
# Function: optimize_pipeline
# Purpose: Demonstrate pipeline optimization techniques
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_pipeline() {
    echo -e "\n=== Pipeline Optimization ==="
    
    # Create test data
    seq 1 100000 > /tmp/pipeline_data.txt
    
    # BAD: Long pipeline with multiple processes
    echo "Bad practice (long pipeline):"
    local start_time=$SECONDS
    
    cat /tmp/pipeline_data.txt | \
        grep -v '^#' | \
        cut -d' ' -f1 | \
        sort | \
        uniq | \
        wc -l
    
    echo "Time with long pipeline: $((SECONDS - start_time)) seconds"
    
    # GOOD: Minimized pipeline with awk
    echo -e "\nGood practice (minimized pipeline):"
    start_time=$SECONDS
    
    awk '!/^#/ { print $1 }' /tmp/pipeline_data.txt | sort -u | wc -l
    
    echo "Time with optimized pipeline: $((SECONDS - start_time)) seconds"
    
    # Clean up
    rm /tmp/pipeline_data.txt
}

# -----------------------------------------------------------------------------
# Function: optimize_temporary_files
# Purpose: Show efficient temporary file handling
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_temporary_files() {
    echo -e "\n=== Temporary File Optimization ==="
    
    # BAD: Using temporary files
    echo "Bad practice (temporary files):"
    local start_time=$SECONDS
    
    {
        seq 1 10000 > /tmp/temp1.txt
        sort -n /tmp/temp1.txt > /tmp/temp2.txt
        uniq /tmp/temp2.txt > /tmp/temp3.txt
        wc -l /tmp/temp3.txt
        rm /tmp/temp{1,2,3}.txt
    }
    
    echo "Time with temporary files: $((SECONDS - start_time)) seconds"
    
    # GOOD: Using process substitution
    echo -e "\nGood practice (process substitution):"
    start_time=$SECONDS
    
    wc -l < <(uniq < <(sort -n < <(seq 1 10000)))
    
    echo "Time with process substitution: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: optimize_network_io
# Purpose: Demonstrate network I/O optimization
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_network_io() {
    echo -e "\n=== Network I/O Optimization ==="
    
    # Function to simulate a network request
    simulate_request() {
        sleep 0.1  # Simulate network latency
        echo "Response data"
    }
    
    # BAD: Sequential requests
    echo "Bad practice (sequential requests):"
    local start_time=$SECONDS
    
    for i in {1..10}; do
        simulate_request > /dev/null
    done
    
    echo "Time with sequential requests: $((SECONDS - start_time)) seconds"
    
    # GOOD: Parallel requests with max connections
    echo -e "\nGood practice (parallel requests):"
    start_time=$SECONDS
    
    # Maximum concurrent connections
    local max_conn=5
    local conn=0
    
    for i in {1..10}; do
        # Wait if we've reached max connections
        while [ $conn -ge $max_conn ]; do
            wait -n
            conn=$((conn - 1))
        done
        
        # Make request in background
        simulate_request > /dev/null &
        conn=$((conn + 1))
    done
    
    # Wait for remaining requests
    wait
    
    echo "Time with parallel requests: $((SECONDS - start_time)) seconds"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_buffer_sizes
# Purpose: Show the impact of different buffer sizes
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_buffer_sizes() {
    echo -e "\n=== Buffer Size Impact ==="
    
    # Create test data
    dd if=/dev/zero of=/tmp/test_data bs=1M count=100 2>/dev/null
    
    # Test different buffer sizes
    for bs in 512 4K 64K 1M; do
        echo "Testing buffer size: $bs"
        local start_time=$SECONDS
        
        dd if=/tmp/test_data of=/dev/null bs=$bs 2>/dev/null
        
        echo "Time with $bs buffer: $((SECONDS - start_time)) seconds"
    done
    
    # Clean up
    rm /tmp/test_data
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting I/O optimization examples..."
    
    # Run all demonstrations
    optimize_file_reading
    optimize_write_operations
    optimize_pipeline
    optimize_temporary_files
    optimize_network_io
    demonstrate_buffer_sizes
    
    echo -e "\nI/O optimization examples completed."
}

# Run main function
main
