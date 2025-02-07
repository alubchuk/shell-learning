#!/bin/bash

# Kernel Tracing Tools
# ---------------
# This script demonstrates various tools and techniques
# for tracing and debugging kernel operations.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. System Call Tracing
# -----------------

trace_syscalls() {
    local pid="${1:-$$}"
    local duration="$2"
    
    echo "System Call Tracing:"
    echo "------------------"
    
    # Trace system calls
    echo "1. System call trace (PID: $pid):"
    {
        dtruss -p "$pid" 2>&1 &
        dtruss_pid=$!
        sleep "$duration"
        kill "$dtruss_pid" 2>/dev/null || true
    } | head -n 10
    
    # System call statistics
    echo -e "\n2. System call statistics:"
    {
        dtruss -c ls /tmp 2>&1
    } | grep -v "^dtrace:"
}

# 2. Kernel Events
# -----------

trace_kernel_events() {
    echo "Kernel Event Tracing:"
    echo "------------------"
    
    # Kernel messages
    echo "1. Kernel messages:"
    log show --predicate 'process == "kernel"' --last 5m | head -n 10
    
    # System events
    echo -e "\n2. System events:"
    log show --predicate 'eventMessage contains "system"' --last 5m | head -n 10
    
    # Hardware events
    echo -e "\n3. Hardware events:"
    log show --predicate 'eventMessage contains "hardware"' --last 5m | head -n 10
}

# 3. Process Tracing
# -------------

trace_processes() {
    local pid="${1:-$$}"
    
    echo "Process Tracing:"
    echo "---------------"
    
    # Process events
    echo "1. Process events:"
    {
        sudo dtrace -n '
            syscall::exec*:return { 
                printf("%s %s", execname, curpsinfo->pr_psargs);
            }
        ' 2>/dev/null &
        dtrace_pid=$!
        sleep 5
        kill "$dtrace_pid" 2>/dev/null || true
    } || echo "dtrace not available"
    
    # Process syscalls
    echo -e "\n2. Process system calls:"
    dtruss -p "$pid" 2>&1 | head -n 5
    
    # Process stack
    echo -e "\n3. Process stack:"
    sample "$pid" 5 2>/dev/null || echo "sample command not available"
}

# 4. Memory Tracing
# ------------

trace_memory() {
    echo "Memory Tracing:"
    echo "--------------"
    
    # Memory allocations
    echo "1. Memory allocations:"
    {
        sudo dtrace -n '
            pid$target::malloc:entry { 
                printf("malloc(%d)", arg0);
            }
        ' -p $$ 2>/dev/null &
        dtrace_pid=$!
        sleep 5
        kill "$dtrace_pid" 2>/dev/null || true
    } || echo "dtrace not available"
    
    # Page faults
    echo -e "\n2. Page faults:"
    vm_stat 1 5
    
    # Memory pressure
    echo -e "\n3. Memory pressure events:"
    log show --predicate 'eventMessage contains "memory"' --last 5m | head -n 5
}

# 5. IO Tracing
# --------

trace_io() {
    echo "IO Tracing:"
    echo "-----------"
    
    # File operations
    echo "1. File operations:"
    fs_usage -f filesys | head -n 5
    
    # Disk IO
    echo -e "\n2. Disk IO:"
    iostat 1 5
    
    # Network IO
    echo -e "\n3. Network IO:"
    nettop -P -n -l 1 2>/dev/null || echo "nettop not available"
}

# 6. Interrupt Tracing
# ---------------

trace_interrupts() {
    echo "Interrupt Tracing:"
    echo "-----------------"
    
    # Interrupt statistics
    echo "1. Interrupt statistics:"
    {
        sudo dtrace -n '
            interrupt:entry { 
                @[probefunc] = count();
            }
        ' 2>/dev/null &
        dtrace_pid=$!
        sleep 5
        kill "$dtrace_pid" 2>/dev/null || true
    } || echo "dtrace not available"
    
    # CPU interrupts
    echo -e "\n2. CPU interrupts:"
    vmstat 1 5
    
    # Device interrupts
    echo -e "\n3. Device interrupts:"
    system_profiler SPHardwareDataType
}

# 7. Practical Examples
# ----------------

# Kernel event monitor
monitor_kernel_events() {
    local duration="$1"
    local log_file="$LOG_DIR/kernel_events.log"
    
    echo "Kernel Event Monitor:"
    echo "------------------"
    
    {
        echo "=== Kernel Event Monitor ==="
        echo "Start time: $(date)"
        
        # Monitor kernel events
        log stream --predicate 'process == "kernel"' &
        logger_pid=$!
        
        sleep "$duration"
        
        kill "$logger_pid" 2>/dev/null || true
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# System call profiler
profile_syscalls() {
    local pid="$1"
    local duration="$2"
    local log_file="$LOG_DIR/syscall_profile.log"
    
    echo "System Call Profiler:"
    echo "------------------"
    
    {
        echo "=== System Call Profile ==="
        echo "PID: $pid"
        echo "Start time: $(date)"
        
        # Profile system calls
        dtruss -c -p "$pid" 2>&1 &
        dtruss_pid=$!
        
        sleep "$duration"
        
        kill "$dtruss_pid" 2>/dev/null || true
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Profiling complete. Check $log_file for details"
}

# Kernel stack tracer
trace_kernel_stack() {
    local duration="$1"
    local log_file="$LOG_DIR/kernel_stack.log"
    
    echo "Kernel Stack Tracer:"
    echo "-----------------"
    
    {
        echo "=== Kernel Stack Trace ==="
        echo "Start time: $(date)"
        
        # Trace kernel stack
        {
            sudo dtrace -n '
                profile-997 /arg0/ {
                    @[stack()] = count();
                }
            ' 2>/dev/null &
            dtrace_pid=$!
            
            sleep "$duration"
            
            kill "$dtrace_pid" 2>/dev/null || true
        } || echo "dtrace not available"
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Tracing complete. Check $log_file for details"
}

# Performance event tracer
trace_performance_events() {
    local duration="$1"
    local log_file="$LOG_DIR/performance_events.log"
    
    echo "Performance Event Tracer:"
    echo "----------------------"
    
    {
        echo "=== Performance Event Trace ==="
        echo "Start time: $(date)"
        
        # CPU performance
        echo -e "\n1. CPU Performance:"
        powermetrics -s cpu_power -i 1000 -n 5 2>/dev/null || echo "powermetrics not available"
        
        # Memory performance
        echo -e "\n2. Memory Performance:"
        vm_stat 1 5
        
        # Disk performance
        echo -e "\n3. Disk Performance:"
        iostat 1 5
        
        # Network performance
        echo -e "\n4. Network Performance:"
        netstat -i 1 5
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Tracing complete. Check $log_file for details"
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
    
    # Basic tracing
    trace_syscalls "$test_pid" 5
    echo -e "\n"
    
    trace_kernel_events
    echo -e "\n"
    
    trace_processes "$test_pid"
    echo -e "\n"
    
    trace_memory
    echo -e "\n"
    
    trace_io
    echo -e "\n"
    
    trace_interrupts
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    monitor_kernel_events 10
    
    profile_syscalls "$test_pid" 10
    
    trace_kernel_stack 10
    
    trace_performance_events 10
    
    # Cleanup
    kill "$test_pid" 2>/dev/null || true
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
