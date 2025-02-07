#!/bin/bash

# Process Inspection Tools
# -------------------
# This script demonstrates various tools and techniques
# for inspecting and analyzing process internals.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Process States
# ------------

analyze_process_states() {
    echo "Process States Analysis:"
    echo "---------------------"
    
    # Process states
    echo "1. Current process states:"
    ps aux | head -n 1
    ps aux | awk '{print $8}' | sort | uniq -c | sort -rn
    
    # Specific process state
    echo -e "\n2. State of current process:"
    ps -o stat= -p "$$"
    
    # Process tree
    echo -e "\n3. Process hierarchy:"
    pstree -p "$$"
    
    # Zombie processes
    echo -e "\n4. Checking for zombie processes:"
    ps aux | awk '$8=="Z"'
}

# 2. Scheduling Information
# -------------------

analyze_scheduling() {
    local pid="${1:-$$}"
    
    echo "Process Scheduling:"
    echo "-----------------"
    
    # Process priority
    echo "1. Process priority information:"
    ps -o pid,nice,pri,rtprio,cmd -p "$pid"
    
    # CPU affinity
    echo -e "\n2. CPU affinity:"
    ps -o pid,psr,cmd -p "$pid"
    
    # Scheduling policy
    echo -e "\n3. Scheduling statistics:"
    ps -o pid,cls,pri,rtprio,cmd -p "$pid"
}

# 3. Resource Usage
# ------------

analyze_resources() {
    local pid="${1:-$$}"
    
    echo "Resource Usage Analysis:"
    echo "---------------------"
    
    # CPU usage
    echo "1. CPU usage:"
    ps -o pid,%cpu,cputime,cmd -p "$pid"
    
    # Memory usage
    echo -e "\n2. Memory usage:"
    ps -o pid,rss,vsz,%mem,cmd -p "$pid"
    
    # File descriptors
    echo -e "\n3. Open file descriptors:"
    lsof -p "$pid" | head -n 5
    
    # IO statistics
    echo -e "\n4. IO statistics:"
    iotop -P -p "$pid" -n 1 2>/dev/null || echo "iotop not available"
}

# 4. Context Switches
# --------------

analyze_context_switches() {
    local pid="${1:-$$}"
    
    echo "Context Switch Analysis:"
    echo "---------------------"
    
    # Context switch statistics
    echo "1. Context switch count:"
    ps -o pid,min_flt,maj_flt,cmd -p "$pid"
    
    # System-wide switches
    echo -e "\n2. System-wide context switches:"
    vmstat 1 5 | grep -v "procs"
    
    # Process switches
    echo -e "\n3. Process context switches:"
    pidstat -w -p "$pid" 1 5 2>/dev/null || echo "pidstat not available"
}

# 5. Priority Management
# ----------------

manage_priority() {
    local pid="${1:-$$}"
    local nice_value="${2:-10}"
    
    echo "Priority Management:"
    echo "------------------"
    
    # Current priority
    echo "1. Current priority:"
    ps -o pid,nice,pri,cmd -p "$pid"
    
    # Change priority
    echo -e "\n2. Changing priority:"
    renice "$nice_value" -p "$pid" 2>/dev/null || echo "Permission denied"
    
    # New priority
    echo -e "\n3. New priority:"
    ps -o pid,nice,pri,cmd -p "$pid"
}

# 6. Thread Analysis
# ------------

analyze_threads() {
    local pid="${1:-$$}"
    
    echo "Thread Analysis:"
    echo "---------------"
    
    # Thread list
    echo "1. Thread list:"
    ps -T -p "$pid" 2>/dev/null || ps -M -p "$pid"
    
    # Thread states
    echo -e "\n2. Thread states:"
    ps -T -p "$pid" -o state,cmd 2>/dev/null || ps -M -p "$pid"
    
    # Thread priorities
    echo -e "\n3. Thread priorities:"
    ps -T -p "$pid" -o pri,cmd 2>/dev/null || ps -M -p "$pid"
}

# 7. Practical Examples
# ----------------

# Process state monitor
monitor_process_state() {
    local pid="$1"
    local duration="$2"
    local interval="${3:-1}"
    local log_file="$LOG_DIR/process_state.log"
    
    echo "Process State Monitor:"
    echo "-------------------"
    
    {
        echo "=== Process State Monitor ==="
        echo "PID: $pid"
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Process state
            ps -o pid,state,pcpu,pmem,cmd -p "$pid" 2>/dev/null
            
            # Resource usage
            ps -o pid,utime,stime,etime -p "$pid" 2>/dev/null
            
            sleep "$interval"
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Thread activity monitor
monitor_thread_activity() {
    local pid="$1"
    local duration="$2"
    local log_file="$LOG_DIR/thread_activity.log"
    
    echo "Thread Activity Monitor:"
    echo "---------------------"
    
    {
        echo "=== Thread Activity Monitor ==="
        echo "PID: $pid"
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Thread list
            ps -T -p "$pid" 2>/dev/null || ps -M -p "$pid"
            
            # Thread states
            ps -T -p "$pid" -o state,cmd 2>/dev/null || ps -M -p "$pid"
            
            sleep 1
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Process resource profiler
profile_process_resources() {
    local pid="$1"
    local duration="$2"
    local output_file="$LOG_DIR/process_profile.log"
    
    echo "Process Resource Profiler:"
    echo "----------------------"
    
    {
        echo "=== Process Resource Profile ==="
        echo "PID: $pid"
        echo "Start time: $(date)"
        
        # Initial state
        echo -e "\n1. Initial process state:"
        ps -p "$pid" -o pid,ppid,nice,pri,pcpu,pmem,rss,state,cmd
        
        # Monitor resources
        echo -e "\n2. Resource usage over time:"
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # CPU and memory
            ps -p "$pid" -o pcpu,pmem,rss,vsz
            
            # IO activity
            iotop -P -p "$pid" -n 1 2>/dev/null || true
            
            # Context switches
            pidstat -w -p "$pid" 1 1 2>/dev/null || true
            
            sleep 1
        done
        
        # Final state
        echo -e "\n3. Final process state:"
        ps -p "$pid" -o pid,ppid,nice,pri,pcpu,pmem,rss,state,cmd
        
        echo "End time: $(date)"
    } > "$output_file"
    
    echo "Profiling complete. Check $output_file for details"
}

# Main execution
main() {
    # Start test process
    {
        while true; do
            echo "Working..."
            sleep 1
        done
    } &
    test_pid=$!
    
    # Basic analysis
    analyze_process_states
    echo -e "\n"
    
    analyze_scheduling "$test_pid"
    echo -e "\n"
    
    analyze_resources "$test_pid"
    echo -e "\n"
    
    analyze_context_switches "$test_pid"
    echo -e "\n"
    
    manage_priority "$test_pid" 15
    echo -e "\n"
    
    analyze_threads "$test_pid"
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    monitor_process_state "$test_pid" 10 2
    
    monitor_thread_activity "$test_pid" 10
    
    profile_process_resources "$test_pid" 10
    
    # Cleanup
    kill "$test_pid" 2>/dev/null || true
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
