#!/bin/bash

# Process Management Basics
# ---------------------
# This script demonstrates basic process management concepts
# including creation, monitoring, and control.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Process Information
# -----------------

show_process_info() {
    echo "Process Information:"
    echo "------------------"
    
    # Current process
    echo "1. Current process info:"
    echo "PID: $$"
    echo "Parent PID: $PPID"
    echo "Process name: $0"
    
    # Environment
    echo -e "\n2. Environment variables:"
    env | head -n 5
    
    # Process limits
    echo -e "\n3. Process limits:"
    ulimit -a
    
    # Process tree
    echo -e "\n4. Process tree:"
    pstree -p "$$"
}

# 2. Process Creation
# --------------

create_processes() {
    echo "Process Creation:"
    echo "----------------"
    
    # Fork bomb protection
    ulimit -u 50
    
    # Background process
    echo "1. Creating background process:"
    sleep 10 &
    echo "Background PID: $!"
    
    # Multiple processes
    echo -e "\n2. Creating multiple processes:"
    for i in {1..3}; do
        (echo "Child process $i (PID: $$)") &
    done
    
    # Wait for completion
    wait
    
    # Subshell
    echo -e "\n3. Subshell example:"
    echo "Parent shell PID: $$"
    (echo "Subshell PID: $$")
}

# 3. Process Status
# ------------

check_process_status() {
    local pid="$1"
    
    echo "Process Status Check:"
    echo "-------------------"
    
    # Check if process exists
    if kill -0 "$pid" 2>/dev/null; then
        echo "Process $pid exists"
        
        # Get detailed info
        ps -p "$pid" -o pid,ppid,cmd,%cpu,%mem,state
        
        # Get process state
        local state
        state=$(ps -p "$pid" -o state=)
        case "$state" in
            R) echo "Process is running" ;;
            S) echo "Process is sleeping" ;;
            D) echo "Process is in uninterruptible sleep" ;;
            Z) echo "Process is zombie" ;;
            T) echo "Process is stopped" ;;
            *) echo "Unknown state: $state" ;;
        esac
    else
        echo "Process $pid does not exist"
    fi
}

# 4. Process Termination
# -----------------

terminate_process() {
    local pid="$1"
    local signal="${2:-TERM}"
    
    echo "Process Termination:"
    echo "------------------"
    
    # Check if process exists
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Process $pid does not exist"
        return 1
    fi
    
    # Send signal
    echo "Sending $signal signal to process $pid"
    kill "-$signal" "$pid"
    
    # Wait for termination
    local count=0
    while kill -0 "$pid" 2>/dev/null; do
        sleep 1
        ((count++))
        if ((count >= 5)); then
            echo "Process did not terminate after 5 seconds"
            echo "Sending KILL signal"
            kill -9 "$pid"
            break
        fi
    done
    
    echo "Process terminated"
}

# 5. Process Groups
# ------------

manage_process_group() {
    echo "Process Group Management:"
    echo "----------------------"
    
    # Create process group
    echo "1. Creating process group"
    
    # Start processes in same group
    sleep 10 &
    pid1=$!
    sleep 10 &
    pid2=$!
    sleep 10 &
    pid3=$!
    
    # Show group
    echo -e "\n2. Process group members:"
    ps -o pid,ppid,pgid,cmd -p "$pid1" "$pid2" "$pid3"
    
    # Terminate group
    echo -e "\n3. Terminating process group"
    kill -TERM -"$$"
}

# 6. Exit Handlers
# -----------

cleanup() {
    echo "Cleaning up..."
    # Kill any remaining child processes
    pkill -P $$
    # Remove temporary files
    rm -rf "$OUTPUT_DIR"/*
}

# Register cleanup handler
trap cleanup EXIT

# 7. Practical Examples
# ----------------

# Process monitor
monitor_process() {
    local pid="$1"
    local duration="$2"
    local log_file="$3"
    
    echo "Monitoring process $pid for $duration seconds"
    
    {
        echo "=== Process Monitor Start: $(date) ==="
        echo "PID: $pid"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            if ! kill -0 "$pid" 2>/dev/null; then
                echo "Process terminated at $(date)"
                break
            fi
            
            ps -p "$pid" -o pid,ppid,cmd,%cpu,%mem,state
            sleep 1
        done
        
        echo "=== Process Monitor End: $(date) ==="
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Process spawner
spawn_processes() {
    local count="$1"
    local command="$2"
    local pids=()
    
    echo "Spawning $count processes running: $command"
    
    # Spawn processes
    for ((i=1; i<=count; i++)); do
        eval "$command" &
        pids+=($!)
    done
    
    # Show status
    echo "Spawned processes:"
    ps -o pid,ppid,cmd "${pids[@]}"
    
    # Return PIDs
    echo "${pids[@]}"
}

# Main execution
main() {
    # Process information
    show_process_info
    echo -e "\n"
    
    # Process creation
    create_processes
    echo -e "\n"
    
    # Spawn test process
    echo "Spawning test process..."
    sleep 30 &
    test_pid=$!
    
    # Check status
    check_process_status "$test_pid"
    echo -e "\n"
    
    # Monitor process
    monitor_process "$test_pid" 5 "$LOG_DIR/monitor.log"
    echo -e "\n"
    
    # Terminate process
    terminate_process "$test_pid"
    echo -e "\n"
    
    # Process group management
    manage_process_group
    echo -e "\n"
    
    # Spawn multiple processes
    spawn_processes 3 "sleep 5"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
