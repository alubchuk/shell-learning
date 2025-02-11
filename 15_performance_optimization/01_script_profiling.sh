#!/bin/bash

# =============================================================================
# Script Profiling Examples
# This script demonstrates various techniques for profiling shell scripts,
# including timing, resource usage monitoring, and performance analysis.
# =============================================================================

# Enable debugging and error handling
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: time_execution
# Purpose: Measure execution time of a command using different methods
# Arguments:
#   $1 - Command to execute
# Returns: None
# -----------------------------------------------------------------------------
time_execution() {
    local cmd="$1"
    
    echo "Profiling command: $cmd"
    
    # Method 1: Using 'time' built-in
    echo -e "\nMethod 1: time built-in"
    time eval "$cmd"
    
    # Method 2: Using TIMEFORMAT for custom output
    echo -e "\nMethod 2: TIMEFORMAT custom output"
    TIMEFORMAT='Real: %R seconds, User: %U seconds, System: %S seconds'
    time eval "$cmd"
    
    # Method 3: Manual timing with date
    echo -e "\nMethod 3: Manual timing"
    local start end
    start=$(date +%s.%N)
    eval "$cmd"
    end=$(date +%s.%N)
    printf "Execution time: %.3f seconds\n" "$(echo "$end - $start" | bc)"
}

# -----------------------------------------------------------------------------
# Function: profile_memory
# Purpose: Monitor memory usage of a command
# Arguments:
#   $1 - Command to execute
#   $2 - Sampling interval in seconds (default: 0.1)
# Returns: None
# -----------------------------------------------------------------------------
profile_memory() {
    local cmd="$1"
    local interval="${2:-0.1}"
    local pid
    
    echo "Monitoring memory usage for: $cmd"
    
    # Start command in background
    eval "$cmd" &
    pid=$!
    
    # Monitor memory usage
    local max_mem=0
    while kill -0 $pid 2>/dev/null; do
        local mem
        mem=$(ps -o rss= -p $pid)
        if [[ -n "$mem" && "$mem" -gt "$max_mem" ]]; then
            max_mem=$mem
        fi
        sleep "$interval"
    done
    
    echo "Peak memory usage: $((max_mem / 1024)) MB"
}

# -----------------------------------------------------------------------------
# Function: profile_io
# Purpose: Monitor I/O operations of a command
# Arguments:
#   $1 - Command to execute
# Returns: None
# -----------------------------------------------------------------------------
profile_io() {
    local cmd="$1"
    
    echo "Monitoring I/O for: $cmd"
    
    # Using iostat to monitor I/O before command
    iostat 1 1
    
    # Execute command
    eval "$cmd"
    
    # Monitor I/O after command
    iostat 1 1
}

# -----------------------------------------------------------------------------
# Function: profile_cpu
# Purpose: Monitor CPU usage of a command
# Arguments:
#   $1 - Command to execute
#   $2 - Duration in seconds
# Returns: None
# -----------------------------------------------------------------------------
profile_cpu() {
    local cmd="$1"
    local duration="${2:-5}"
    
    echo "Monitoring CPU usage for: $cmd"
    
    # Start command in background
    eval "$cmd" &
    local pid=$!
    
    # Monitor CPU usage using top
    top -pid $pid -stats cpu,mem -l $duration 2>/dev/null
    
    # Ensure process is terminated
    kill $pid 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Function: generate_load
# Purpose: Generate different types of load for testing
# Arguments:
#   $1 - Type of load (cpu|memory|io)
#   $2 - Duration in seconds
# Returns: None
# -----------------------------------------------------------------------------
generate_load() {
    local type="$1"
    local duration="${2:-5}"
    
    case "$type" in
        cpu)
            # Generate CPU load using bc
            echo "Generating CPU load for $duration seconds..."
            for ((i=0; i<duration; i++)); do
                echo "scale=5000; 4*a(1)" | bc -l &>/dev/null
            done
            ;;
            
        memory)
            # Generate memory load using an array
            echo "Generating memory load for $duration seconds..."
            local -a array
            for ((i=0; i<100000; i++)); do
                array+=("$i")
                if ((i % 10000 == 0)); then
                    echo "Allocated $i elements"
                fi
            done
            sleep "$duration"
            ;;
            
        io)
            # Generate I/O load using dd
            echo "Generating I/O load for $duration seconds..."
            local temp_file
            temp_file=$(mktemp)
            dd if=/dev/zero of="$temp_file" bs=1M count=1000 &>/dev/null
            rm "$temp_file"
            ;;
            
        *)
            echo "Unknown load type: $type"
            return 1
            ;;
    esac
}

# =============================================================================
# Main Script
# =============================================================================

# Example 1: Time execution profiling
echo "=== Example 1: Time Execution Profiling ==="
time_execution "sleep 1"

# Example 2: Memory profiling
echo -e "\n=== Example 2: Memory Profiling ==="
profile_memory "generate_load memory 3"

# Example 3: I/O profiling
echo -e "\n=== Example 3: I/O Profiling ==="
profile_io "generate_load io 3"

# Example 4: CPU profiling
echo -e "\n=== Example 4: CPU Profiling ==="
profile_cpu "generate_load cpu 3"

# Example 5: Combined profiling
echo -e "\n=== Example 5: Combined Profiling ==="
{
    time_execution "generate_load cpu 2"
    profile_memory "generate_load memory 2"
    profile_io "generate_load io 2"
} 2>&1 | tee profile_report.txt

echo -e "\nProfiling complete. Check profile_report.txt for details."
