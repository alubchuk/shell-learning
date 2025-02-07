#!/bin/bash

# Resource Monitoring Tools
# --------------------
# This script demonstrates various tools and techniques
# for monitoring system resources and performance.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. CPU Monitoring
# ------------

monitor_cpu() {
    echo "CPU Monitoring:"
    echo "--------------"
    
    # CPU info
    echo "1. CPU information:"
    sysctl -n machdep.cpu.brand_string
    
    # CPU load
    echo -e "\n2. CPU load:"
    uptime
    
    # Process CPU usage
    echo -e "\n3. Process CPU usage:"
    ps -eo pid,pcpu,command | sort -k2 -r | head -n 5
    
    # CPU temperature
    echo -e "\n4. CPU temperature:"
    sudo powermetrics --samplers smc -i1 -n1 2>/dev/null || echo "powermetrics not available"
}

# 2. Memory Monitoring
# --------------

monitor_memory() {
    echo "Memory Monitoring:"
    echo "-----------------"
    
    # Memory info
    echo "1. Memory information:"
    vm_stat
    
    # Memory usage by process
    echo -e "\n2. Process memory usage:"
    ps -eo pid,pmem,rss,command | sort -k2 -r | head -n 5
    
    # Swap usage
    echo -e "\n3. Swap usage:"
    sysctl vm.swapusage
    
    # Memory pressure
    echo -e "\n4. Memory pressure:"
    memory_pressure
}

# 3. Disk Monitoring
# ------------

monitor_disk() {
    echo "Disk Monitoring:"
    echo "---------------"
    
    # Disk space
    echo "1. Disk space usage:"
    df -h
    
    # Disk IO
    echo -e "\n2. Disk IO:"
    iostat 1 5
    
    # File system usage
    echo -e "\n3. File system usage:"
    du -sh /* 2>/dev/null | sort -hr | head -n 5
    
    # Disk activity
    echo -e "\n4. Disk activity:"
    fs_usage -f filesys | head -n 5
}

# 4. Network Monitoring
# --------------

monitor_network() {
    echo "Network Monitoring:"
    echo "-----------------"
    
    # Network interfaces
    echo "1. Network interfaces:"
    netstat -i
    
    # Network connections
    echo -e "\n2. Network connections:"
    netstat -an | grep ESTABLISHED | head -n 5
    
    # Network traffic
    echo -e "\n3. Network traffic:"
    nettop -P -n -l 1 2>/dev/null || echo "nettop not available"
    
    # Network errors
    echo -e "\n4. Network errors:"
    netstat -s | grep -i error | head -n 5
}

# 5. Process Monitoring
# --------------

monitor_processes() {
    echo "Process Monitoring:"
    echo "-----------------"
    
    # Process list
    echo "1. Top processes:"
    ps -eo pid,pcpu,pmem,command | sort -k2 -r | head -n 5
    
    # Process tree
    echo -e "\n2. Process tree:"
    pstree | head -n 5
    
    # Zombie processes
    echo -e "\n3. Zombie processes:"
    ps aux | awk '$8=="Z"'
    
    # Process states
    echo -e "\n4. Process states:"
    ps -eo state | sort | uniq -c
}

# 6. System Load
# ---------

monitor_system_load() {
    echo "System Load Monitoring:"
    echo "--------------------"
    
    # Load average
    echo "1. Load average:"
    sysctl vm.loadavg
    
    # CPU load
    echo -e "\n2. CPU load:"
    top -l 1 -n 0
    
    # IO wait
    echo -e "\n3. IO wait:"
    iostat 1 5
    
    # System uptime
    echo -e "\n4. System uptime:"
    uptime
}

# 7. Practical Examples
# ----------------

# System resource monitor
monitor_system_resources() {
    local duration="$1"
    local interval="${2:-5}"
    local log_file="$LOG_DIR/system_resources.log"
    
    echo "System Resource Monitor:"
    echo "---------------------"
    
    {
        echo "=== System Resource Monitor ==="
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # CPU usage
            echo "CPU Usage:"
            ps -eo pcpu,pid,command | sort -k1 -r | head -n 5
            
            # Memory usage
            echo -e "\nMemory Usage:"
            vm_stat
            
            # Disk usage
            echo -e "\nDisk Usage:"
            df -h
            
            # Network usage
            echo -e "\nNetwork Usage:"
            netstat -i
            
            sleep "$interval"
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Performance bottleneck detector
detect_bottlenecks() {
    local duration="$1"
    local log_file="$LOG_DIR/bottleneck_analysis.log"
    
    echo "Performance Bottleneck Detection:"
    echo "-----------------------------"
    
    {
        echo "=== Performance Bottleneck Analysis ==="
        echo "Start time: $(date)"
        
        # CPU bottlenecks
        echo -e "\n1. CPU Bottlenecks:"
        ps -eo pid,pcpu,command | sort -k2 -r | head -n 5
        
        # Memory bottlenecks
        echo -e "\n2. Memory Bottlenecks:"
        ps -eo pid,pmem,command | sort -k2 -r | head -n 5
        
        # Disk bottlenecks
        echo -e "\n3. Disk Bottlenecks:"
        iostat
        
        # Network bottlenecks
        echo -e "\n4. Network Bottlenecks:"
        netstat -i
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Analysis complete. Check $log_file for details"
}

# Resource usage profiler
profile_resource_usage() {
    local pid="$1"
    local duration="$2"
    local log_file="$LOG_DIR/resource_profile.log"
    
    echo "Resource Usage Profiler:"
    echo "---------------------"
    
    {
        echo "=== Resource Usage Profile ==="
        echo "PID: $pid"
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Process info
            ps -p "$pid" -o pid,pcpu,pmem,rss,vsz,state,command
            
            # File descriptors
            echo -e "\nOpen files:"
            lsof -p "$pid" | head -n 5
            
            # Network connections
            echo -e "\nNetwork connections:"
            lsof -i -a -p "$pid"
            
            sleep 1
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Profiling complete. Check $log_file for details"
}

# Resource threshold monitor
monitor_thresholds() {
    local cpu_threshold="${1:-90}"    # CPU usage threshold (%)
    local mem_threshold="${2:-90}"    # Memory usage threshold (%)
    local disk_threshold="${3:-90}"   # Disk usage threshold (%)
    local duration="$4"
    local log_file="$LOG_DIR/threshold_alerts.log"
    
    echo "Resource Threshold Monitor:"
    echo "-----------------------"
    
    {
        echo "=== Resource Threshold Monitor ==="
        echo "Thresholds: CPU=${cpu_threshold}%, MEM=${mem_threshold}%, DISK=${disk_threshold}%"
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Check CPU
            local cpu_usage
            cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {print s}')
            if (( $(echo "$cpu_usage > $cpu_threshold" | bc -l) )); then
                echo "WARNING: CPU usage at ${cpu_usage}%"
                ps -eo pid,pcpu,command | sort -k2 -r | head -n 5
            fi
            
            # Check memory
            local mem_usage
            mem_usage=$(vm_stat | awk '/Pages active/ {print $3}' | sed 's/\.//')
            if (( mem_usage > mem_threshold )); then
                echo "WARNING: Memory usage high"
                ps -eo pid,pmem,command | sort -k2 -r | head -n 5
            fi
            
            # Check disk
            df -h | awk -v threshold="$disk_threshold" '
                NR > 1 {
                    usage=$(NF-1)
                    sub(/%/, "", usage)
                    if (usage > threshold) {
                        print "WARNING: Disk usage at " usage "% for " $NF
                    }
                }
            '
            
            sleep 5
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Main execution
main() {
    # Basic monitoring
    monitor_cpu
    echo -e "\n"
    
    monitor_memory
    echo -e "\n"
    
    monitor_disk
    echo -e "\n"
    
    monitor_network
    echo -e "\n"
    
    monitor_processes
    echo -e "\n"
    
    monitor_system_load
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    monitor_system_resources 10 2
    
    detect_bottlenecks 10
    
    # Start test process
    {
        while true; do
            echo "Working..."
            sleep 1
        done
    } &
    test_pid=$!
    
    profile_resource_usage "$test_pid" 10
    
    monitor_thresholds 90 90 90 10
    
    # Cleanup
    kill "$test_pid" 2>/dev/null || true
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
