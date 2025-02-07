#!/bin/bash

# Resource Limits
# ------------
# This script demonstrates various resource limiting
# techniques and monitoring.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. System Resource Limits
# -------------------

show_system_limits() {
    echo "System Resource Limits:"
    echo "---------------------"
    
    # Show all limits
    echo "1. Current resource limits:"
    ulimit -a
    
    # Show specific limits
    echo -e "\n2. Specific limits:"
    echo "Max file size: $(ulimit -f) KB"
    echo "Max processes: $(ulimit -u)"
    echo "Max open files: $(ulimit -n)"
    echo "Max stack size: $(ulimit -s) KB"
    echo "Max virtual memory: $(ulimit -v) KB"
}

# 2. Process Limits
# ------------

set_process_limits() {
    echo "Setting Process Limits:"
    echo "---------------------"
    
    # Backup current limits
    local old_file_limit
    old_file_limit=$(ulimit -n)
    
    # Set new limits
    echo "1. Setting new limits:"
    ulimit -n 1024
    ulimit -u 100
    
    # Show new limits
    echo -e "\n2. New limits:"
    echo "Max open files: $(ulimit -n)"
    echo "Max processes: $(ulimit -u)"
    
    # Restore original limits
    ulimit -n "$old_file_limit"
}

# 3. Memory Limits
# -----------

test_memory_limits() {
    echo "Memory Limits Test:"
    echo "-----------------"
    
    # Set memory limit (50MB)
    ulimit -v $((50 * 1024))
    
    echo "1. Memory-intensive process:"
    # Try to allocate memory
    perl -e '
        my @data;
        for (1..1000000) {
            push @data, "x" x 1000;
            if ($_ % 1000 == 0) {
                print "Allocated ", $_ * 1000, " bytes\n";
            }
        }
    ' 2>&1 || echo "Memory limit reached"
}

# 4. CPU Limits
# --------

test_cpu_limits() {
    echo "CPU Limits Test:"
    echo "--------------"
    
    # Set CPU time limit (1 second)
    ulimit -t 1
    
    echo "1. CPU-intensive process:"
    # Try to consume CPU
    perl -e '
        $start = time;
        while (1) {
            $x = rand() ** rand();
            if (time - $start > 5) {
                last;
            }
        }
    ' 2>&1 || echo "CPU limit reached"
}

# 5. File Limits
# ---------

test_file_limits() {
    echo "File Limits Test:"
    echo "---------------"
    
    # Set file size limit (1MB)
    ulimit -f 1024
    
    echo "1. File creation test:"
    # Try to create large file
    {
        dd if=/dev/zero of="$OUTPUT_DIR/test.dat" bs=1M count=10 2>&1
    } || echo "File size limit reached"
    
    # Cleanup
    rm -f "$OUTPUT_DIR/test.dat"
}

# 6. Resource Monitoring
# -----------------

monitor_resources() {
    local pid="$1"
    local duration="$2"
    local log_file="$3"
    
    echo "Resource Monitoring:"
    echo "------------------"
    
    {
        echo "=== Resource Monitor Start: $(date) ==="
        echo "PID: $pid"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Process stats
            ps -o pid,ppid,%cpu,%mem,vsz,rss,state,time -p "$pid" 2>/dev/null
            
            # File descriptors
            echo "Open files:"
            lsof -p "$pid" 2>/dev/null | head -n 5
            
            sleep 1
        done
        
        echo "=== Resource Monitor End: $(date) ==="
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# 7. Practical Examples
# ----------------

# Resource-limited container
run_in_container() {
    local command="$1"
    local mem_limit="${2:-50}"  # MB
    local cpu_limit="${3:-1}"   # seconds
    local file_limit="${4:-10}" # MB
    
    echo "Running in Resource Container:"
    echo "--------------------------"
    
    # Create subshell with limits
    (
        # Set limits
        ulimit -v $((mem_limit * 1024))
        ulimit -t "$cpu_limit"
        ulimit -f $((file_limit * 1024))
        
        # Run command
        echo "Running command with limits:"
        echo "Memory: ${mem_limit}MB"
        echo "CPU: ${cpu_limit}s"
        echo "File size: ${file_limit}MB"
        
        # Execute
        eval "$command"
    )
}

# Resource usage tracker
track_resource_usage() {
    local command="$1"
    local log_file="$2"
    
    echo "Resource Usage Tracking:"
    echo "---------------------"
    
    # Start time
    local start_time
    start_time=$(date +%s)
    
    # Run command and capture stats
    {
        echo "=== Resource Usage Report ==="
        echo "Command: $command"
        echo "Start time: $(date)"
        
        # Run with time command
        /usr/bin/time -p eval "$command" 2>&1
        
        # End time and duration
        local end_time
        end_time=$(date +%s)
        echo "End time: $(date)"
        echo "Duration: $((end_time - start_time)) seconds"
        
    } > "$log_file"
    
    echo "Resource tracking complete. Check $log_file for details"
}

# Resource limit enforcer
enforce_limits() {
    local pid="$1"
    local max_cpu="${2:-50}"  # CPU percentage
    local max_mem="${3:-100}" # Memory percentage
    
    echo "Resource Limit Enforcer:"
    echo "---------------------"
    
    while kill -0 "$pid" 2>/dev/null; do
        # Get current usage
        local cpu_usage
        cpu_usage=$(ps -p "$pid" -o %cpu= 2>/dev/null || echo 0)
        local mem_usage
        mem_usage=$(ps -p "$pid" -o %mem= 2>/dev/null || echo 0)
        
        echo "CPU: ${cpu_usage}%, Memory: ${mem_usage}%"
        
        # Check limits
        if (( $(echo "$cpu_usage > $max_cpu" | bc -l) )); then
            echo "CPU limit exceeded, sending STOP"
            kill -STOP "$pid"
            sleep 1
            kill -CONT "$pid"
        fi
        
        if (( $(echo "$mem_usage > $max_mem" | bc -l) )); then
            echo "Memory limit exceeded, terminating"
            kill -TERM "$pid"
            break
        fi
        
        sleep 1
    done
}

# Main execution
main() {
    # Show current limits
    show_system_limits
    echo -e "\n"
    
    # Test process limits
    set_process_limits
    echo -e "\n"
    
    # Test memory limits
    test_memory_limits
    echo -e "\n"
    
    # Test CPU limits
    test_cpu_limits
    echo -e "\n"
    
    # Test file limits
    test_file_limits
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Run CPU-intensive task in container
    run_in_container "perl -e 'for(1..1000000){$x=rand()**rand()}'" 50 1 10
    
    # Track resource usage
    track_resource_usage "sleep 2" "$LOG_DIR/resource_usage.log"
    
    # Start test process and enforce limits
    {
        while true; do
            echo "Working..."
            sleep 1
        done
    } &
    test_pid=$!
    
    # Monitor and enforce limits
    enforce_limits "$test_pid" 10 10 &
    enforce_pid=$!
    
    # Monitor resources
    monitor_resources "$test_pid" 10 "$LOG_DIR/monitor.log"
    
    # Cleanup
    kill "$test_pid" 2>/dev/null || true
    kill "$enforce_pid" 2>/dev/null || true
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
