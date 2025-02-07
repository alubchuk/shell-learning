#!/bin/bash

# Process Monitoring
# --------------
# This script demonstrates various process monitoring
# techniques and tools.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Basic Process Information
# ----------------------

show_process_info() {
    local pid="${1:-$$}"
    
    echo "Process Information:"
    echo "------------------"
    
    # Basic info
    echo "1. Basic process info (PID: $pid):"
    ps -p "$pid" -o pid,ppid,user,%cpu,%mem,state,start,time,command
    
    # Detailed info
    echo -e "\n2. Detailed process info:"
    ps aux | grep -v grep | grep "$pid"
    
    # Process tree
    echo -e "\n3. Process tree:"
    pstree -p "$pid"
    
    # Open files
    echo -e "\n4. Open files:"
    lsof -p "$pid" 2>/dev/null | head -n 5
}

# 2. System Load Monitoring
# -------------------

monitor_system_load() {
    echo "System Load Monitoring:"
    echo "--------------------"
    
    # CPU info
    echo "1. CPU information:"
    top -l 1 | head -n 10
    
    # Memory info
    echo -e "\n2. Memory information:"
    vm_stat
    
    # Disk usage
    echo -e "\n3. Disk usage:"
    df -h
    
    # IO stats
    echo -e "\n4. IO statistics:"
    iostat 1 5
}

# 3. Process Resource Usage
# -------------------

monitor_process_resources() {
    local pid="$1"
    local duration="$2"
    local interval="${3:-1}"
    
    echo "Process Resource Monitoring:"
    echo "-------------------------"
    
    local end=$((SECONDS + duration))
    while ((SECONDS < end)); do
        echo "=== $(date) ==="
        
        # CPU and memory
        ps -p "$pid" -o pid,ppid,%cpu,%mem,vsz,rss,state,time
        
        # IO activity
        lsof -p "$pid" 2>/dev/null | wc -l | xargs echo "Open files:"
        
        sleep "$interval"
    done
}

# 4. Process Network Activity
# ---------------------

monitor_network_activity() {
    local pid="$1"
    local duration="$2"
    
    echo "Network Activity Monitoring:"
    echo "-------------------------"
    
    # Show network connections
    echo "1. Network connections:"
    lsof -i -P -n -p "$pid"
    
    # Monitor network traffic
    echo -e "\n2. Network traffic (${duration}s):"
    netstat -p tcp -b
}

# 5. Process Event Monitoring
# ---------------------

monitor_process_events() {
    local pid="$1"
    local duration="$2"
    local log_file="$3"
    
    echo "Process Event Monitoring:"
    echo "----------------------"
    
    {
        echo "=== Process Event Log Start: $(date) ==="
        echo "PID: $pid"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            # Process status changes
            ps -p "$pid" -o pid,state,time 2>/dev/null
            
            # Check for children
            pgrep -P "$pid" 2>/dev/null
            
            # Check for signals
            kill -0 "$pid" 2>/dev/null && echo "Process active" || echo "Process terminated"
            
            sleep 1
        done
        
        echo "=== Process Event Log End: $(date) ==="
    } > "$log_file"
    
    echo "Event monitoring complete. Check $log_file for details"
}

# 6. Performance Profiling
# ------------------

profile_process() {
    local command="$1"
    local output_file="$2"
    
    echo "Process Profiling:"
    echo "----------------"
    
    # Run with time command
    echo "1. Time analysis:"
    /usr/bin/time -p "$command" 2>&1
    
    # Run with performance monitoring
    echo -e "\n2. Performance analysis:"
    {
        echo "=== Performance Profile: $(date) ==="
        echo "Command: $command"
        
        # Start time
        local start_time
        start_time=$(date +%s)
        
        # Run command and monitor
        eval "$command" &
        local cmd_pid=$!
        
        # Monitor resources
        while kill -0 "$cmd_pid" 2>/dev/null; do
            ps -p "$cmd_pid" -o pid,%cpu,%mem,state,time
            sleep 1
        done
        
        # End time
        local end_time
        end_time=$(date +%s)
        echo "Duration: $((end_time - start_time)) seconds"
    } > "$output_file"
    
    echo "Profiling complete. Check $output_file for details"
}

# 7. Practical Examples
# ----------------

# Process health checker
check_process_health() {
    local pid="$1"
    local cpu_threshold="${2:-50}"
    local mem_threshold="${3:-50}"
    
    echo "Process Health Check:"
    echo "------------------"
    
    # Get process stats
    local stats
    stats=$(ps -p "$pid" -o %cpu,%mem 2>/dev/null)
    if [[ -z "$stats" ]]; then
        echo "Process $pid not found"
        return 1
    fi
    
    # Parse stats
    local cpu_usage
    local mem_usage
    read -r cpu_usage mem_usage <<< "$(echo "$stats" | tail -n1)"
    
    # Check thresholds
    echo "CPU Usage: ${cpu_usage}%"
    echo "Memory Usage: ${mem_usage}%"
    
    local health_issues=()
    
    if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then
        health_issues+=("High CPU usage")
    fi
    
    if (( $(echo "$mem_usage > $mem_threshold" | bc -l) )); then
        health_issues+=("High memory usage")
    fi
    
    # Report status
    if ((${#health_issues[@]} > 0)); then
        echo "Health issues detected:"
        printf '%s\n' "${health_issues[@]}"
        return 1
    else
        echo "Process is healthy"
        return 0
    fi
}

# Resource usage reporter
generate_resource_report() {
    local pid="$1"
    local report_file="$2"
    
    echo "Generating Resource Report:"
    echo "------------------------"
    
    {
        echo "=== Process Resource Report ==="
        echo "Generated: $(date)"
        echo "PID: $pid"
        
        # Process info
        echo -e "\n1. Process Information:"
        ps -p "$pid" -o pid,ppid,user,state,start,time,command
        
        # Resource usage
        echo -e "\n2. Resource Usage:"
        ps -p "$pid" -o %cpu,%mem,vsz,rss
        
        # File descriptors
        echo -e "\n3. Open Files:"
        lsof -p "$pid" 2>/dev/null | head -n 10
        
        # Network connections
        echo -e "\n4. Network Connections:"
        lsof -i -P -n -p "$pid" 2>/dev/null
        
        # Process tree
        echo -e "\n5. Process Tree:"
        pstree -p "$pid"
        
    } > "$report_file"
    
    echo "Report generated: $report_file"
}

# Process monitor daemon
run_monitor_daemon() {
    local pid="$1"
    local interval="${2:-5}"
    local log_file="$3"
    
    echo "Starting Monitor Daemon:"
    echo "---------------------"
    
    # Monitor process
    {
        while kill -0 "$pid" 2>/dev/null; do
            echo "=== $(date) ==="
            
            # Process status
            ps -p "$pid" -o pid,ppid,%cpu,%mem,state,time
            
            # Resource usage
            local stats
            stats=$(ps -p "$pid" -o %cpu,%mem 2>/dev/null | tail -n1)
            if [[ -n "$stats" ]]; then
                read -r cpu_usage mem_usage <<< "$stats"
                echo "CPU: ${cpu_usage}%, Memory: ${mem_usage}%"
            fi
            
            # Health check
            check_process_health "$pid" 80 80
            
            sleep "$interval"
        done
        
        echo "Process $pid terminated at $(date)"
    } > "$log_file" &
    
    echo "Monitor daemon started. Check $log_file for updates"
    echo "Daemon PID: $!"
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
    
    # Basic monitoring
    show_process_info "$test_pid"
    echo -e "\n"
    
    monitor_system_load
    echo -e "\n"
    
    monitor_process_resources "$test_pid" 5
    echo -e "\n"
    
    monitor_network_activity "$test_pid" 5
    echo -e "\n"
    
    monitor_process_events "$test_pid" 5 "$LOG_DIR/events.log"
    echo -e "\n"
    
    # Profile test command
    profile_process "sleep 2" "$LOG_DIR/profile.log"
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    check_process_health "$test_pid" 50 50
    echo -e "\n"
    
    generate_resource_report "$test_pid" "$LOG_DIR/report.txt"
    echo -e "\n"
    
    run_monitor_daemon "$test_pid" 2 "$LOG_DIR/monitor.log"
    sleep 5
    
    # Cleanup
    kill "$test_pid" 2>/dev/null || true
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
