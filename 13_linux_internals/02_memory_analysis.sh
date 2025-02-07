#!/bin/bash

# Memory Analysis Tools
# ----------------
# This script demonstrates various tools and techniques
# for analyzing system memory usage and management.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Memory Statistics
# ---------------

show_memory_stats() {
    echo "Memory Statistics:"
    echo "-----------------"
    
    # Basic memory info
    echo "1. Basic memory information:"
    vm_stat
    
    # Memory pressure
    echo -e "\n2. Memory pressure:"
    memory_pressure
    
    # Virtual memory stats
    echo -e "\n3. Virtual memory statistics:"
    vmmap -summary $$ | head -n 10
    
    # Process memory
    echo -e "\n4. Process memory usage:"
    ps -m | head -n 5
}

# 2. Swap Analysis
# -----------

analyze_swap() {
    echo "Swap Analysis:"
    echo "-------------"
    
    # Swap usage
    echo "1. Swap usage:"
    sysctl vm.swapusage
    
    # Swap files
    echo -e "\n2. Swap files:"
    ls -l /private/var/vm/
    
    # Swap statistics
    echo -e "\n3. Swap statistics:"
    vm_stat | grep "swap"
}

# 3. Page Cache Analysis
# -----------------

analyze_page_cache() {
    echo "Page Cache Analysis:"
    echo "------------------"
    
    # Cache statistics
    echo "1. Cache statistics:"
    vm_stat | grep "cache"
    
    # File system cache
    echo -e "\n2. File system cache:"
    fs_usage -f filesys | head -n 5
    
    # Buffer cache
    echo -e "\n3. Buffer cache:"
    system_profiler SPHardwareDataType | grep "L2\|L3"
}

# 4. Memory Mapping
# ------------

analyze_memory_mapping() {
    local pid="${1:-$$}"
    
    echo "Memory Mapping Analysis:"
    echo "---------------------"
    
    # Process mappings
    echo "1. Process memory mappings (PID: $pid):"
    vmmap "$pid" | head -n 20
    
    # Shared libraries
    echo -e "\n2. Shared libraries:"
    otool -L "$(which bash)" | head -n 5
    
    # Memory regions
    echo -e "\n3. Memory regions:"
    vmmap -summary "$pid" | grep -A 5 "REGION TYPE"
}

# 5. OOM Analysis
# ----------

analyze_oom() {
    echo "OOM Analysis:"
    echo "------------"
    
    # Memory pressure
    echo "1. Memory pressure level:"
    memory_pressure
    
    # Process memory usage
    echo -e "\n2. Top memory consumers:"
    ps -axo pid,rss,command | sort -rn -k2 | head -n 5
    
    # System diagnostics
    echo -e "\n3. System memory diagnostics:"
    vm_stat | grep "page"
}

# 6. Memory Pressure
# -------------

monitor_memory_pressure() {
    echo "Memory Pressure Monitor:"
    echo "---------------------"
    
    # Current pressure
    echo "1. Current memory pressure:"
    memory_pressure
    
    # Memory stats
    echo -e "\n2. Memory statistics:"
    vm_stat 1 5
    
    # Process impact
    echo -e "\n3. Process memory impact:"
    ps -axo pid,rss,command | sort -rn -k2 | head -n 5
}

# 7. Practical Examples
# ----------------

# Memory usage tracker
track_memory_usage() {
    local duration="$1"
    local interval="${2:-5}"
    local log_file="$LOG_DIR/memory_usage.log"
    
    echo "Memory Usage Tracking:"
    echo "-------------------"
    
    {
        echo "=== Memory Usage Log ==="
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Memory stats
            vm_stat
            
            # Top processes
            ps -axo pid,rss,command | sort -rn -k2 | head -n 5
            
            sleep "$interval"
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Tracking complete. Check $log_file for details"
}

# Memory leak detector
detect_memory_leaks() {
    local pid="$1"
    local duration="$2"
    local interval="${3:-5}"
    local log_file="$LOG_DIR/memory_leaks.log"
    
    echo "Memory Leak Detection:"
    echo "-------------------"
    
    {
        echo "=== Memory Leak Analysis ==="
        echo "PID: $pid"
        echo "Start time: $(date)"
        
        local prev_rss=0
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Get current RSS
            local current_rss
            current_rss=$(ps -o rss= -p "$pid")
            
            # Compare with previous
            if ((current_rss > prev_rss)); then
                echo "Memory increased: $((current_rss - prev_rss)) KB"
                vmmap "$pid" | grep -A 5 "REGION TYPE"
            fi
            
            prev_rss=$current_rss
            sleep "$interval"
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Analysis complete. Check $log_file for details"
}

# Memory pressure simulator
simulate_memory_pressure() {
    echo "Memory Pressure Simulation:"
    echo "------------------------"
    
    # Start memory consumer
    {
        # Allocate memory gradually
        perl -e '
            for (1..10) {
                my @data;
                for (1..100000) {
                    push @data, "x" x 1000;
                }
                print "Allocated ", $_ * 100, "MB\n";
                sleep 1;
            }
        ' &
    } 2>/dev/null
    
    consumer_pid=$!
    
    # Monitor system
    echo "Monitoring system under pressure..."
    for _ in {1..5}; do
        memory_pressure
        vm_stat | grep "free\|active\|inactive"
        sleep 2
    done
    
    # Cleanup
    kill "$consumer_pid" 2>/dev/null || true
}

# Main execution
main() {
    # Basic analysis
    show_memory_stats
    echo -e "\n"
    
    analyze_swap
    echo -e "\n"
    
    analyze_page_cache
    echo -e "\n"
    
    analyze_memory_mapping "$$"
    echo -e "\n"
    
    analyze_oom
    echo -e "\n"
    
    monitor_memory_pressure
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    track_memory_usage 10 2
    
    # Start test process
    sleep 100 &
    test_pid=$!
    
    detect_memory_leaks "$test_pid" 10 2
    
    simulate_memory_pressure
    
    # Cleanup
    kill "$test_pid" 2>/dev/null || true
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
