#!/bin/bash

# Kernel Information and Management
# ---------------------------
# This script demonstrates various commands and techniques
# for gathering kernel information and managing kernel modules.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Basic Kernel Information
# ---------------------

show_kernel_info() {
    echo "Kernel Information:"
    echo "------------------"
    
    # Kernel version
    echo "1. Kernel version:"
    uname -a
    
    # OS information
    echo -e "\n2. OS information:"
    sw_vers
    
    # Kernel parameters
    echo -e "\n3. Kernel parameters:"
    sysctl -a | head -n 10
    
    # Boot arguments
    echo -e "\n4. Boot arguments:"
    nvram boot-args 2>/dev/null || echo "No boot arguments set"
    
    # System hardware
    echo -e "\n5. Hardware information:"
    system_profiler SPHardwareDataType
}

# 2. System Call Information
# --------------------

analyze_syscalls() {
    local pid="${1:-$$}"
    
    echo "System Call Analysis:"
    echo "-------------------"
    
    # Current process syscalls
    echo "1. Tracing system calls for PID $pid:"
    {
        dtruss -p "$pid" 2>&1 &
        dtruss_pid=$!
        sleep 2
        kill "$dtruss_pid" 2>/dev/null || true
    } | head -n 10
    
    # System call statistics
    echo -e "\n2. System call statistics:"
    {
        dtruss -c ls /tmp 2>&1
    } | grep -v "^dtrace:"
}

# 3. Kernel Extensions
# ---------------

list_kernel_extensions() {
    echo "Kernel Extensions:"
    echo "----------------"
    
    # List loaded kexts
    echo "1. Loaded kernel extensions:"
    kextstat | head -n 5
    
    # Kext information
    echo -e "\n2. Detailed kext information:"
    kextfind -bundle-id -substring "com.apple" | head -n 5
}

# 4. Hardware Information
# ------------------

analyze_hardware() {
    echo "Hardware Analysis:"
    echo "-----------------"
    
    # CPU information
    echo "1. CPU information:"
    sysctl -n machdep.cpu.brand_string
    echo "Cores: $(sysctl -n hw.ncpu)"
    
    # Memory information
    echo -e "\n2. Memory information:"
    vm_stat
    
    # PCI devices
    echo -e "\n3. PCI devices:"
    system_profiler SPPCIDataType
    
    # USB devices
    echo -e "\n4. USB devices:"
    system_profiler SPUSBDataType
}

# 5. System Parameters
# ---------------

manage_sysctl() {
    echo "System Parameters:"
    echo "-----------------"
    
    # Memory parameters
    echo "1. Memory parameters:"
    sysctl -a | grep "vm\." | head -n 5
    
    # Network parameters
    echo -e "\n2. Network parameters:"
    sysctl -a | grep "net\." | head -n 5
    
    # Kernel parameters
    echo -e "\n3. Kernel parameters:"
    sysctl -a | grep "kern\." | head -n 5
}

# 6. Boot Process Analysis
# -------------------

analyze_boot() {
    echo "Boot Process Analysis:"
    echo "--------------------"
    
    # Boot log
    echo "1. Boot log messages:"
    log show --predicate 'eventMessage contains "boot"' --last 1h | head -n 10
    
    # System startup
    echo -e "\n2. System startup items:"
    ls -l /Library/StartupItems /System/Library/StartupItems 2>/dev/null || echo "No startup items found"
    
    # Launch daemons
    echo -e "\n3. Launch daemons:"
    ls -l /Library/LaunchDaemons | head -n 5
}

# 7. Practical Examples
# ----------------

# System profiler
generate_system_profile() {
    local output_file="$LOG_DIR/system_profile.txt"
    
    echo "Generating System Profile:"
    echo "-----------------------"
    
    {
        echo "=== System Profile Report ==="
        echo "Generated: $(date)"
        
        echo -e "\n1. System Overview:"
        system_profiler SPSoftwareDataType SPHardwareDataType
        
        echo -e "\n2. Kernel Information:"
        uname -a
        
        echo -e "\n3. Hardware Details:"
        system_profiler SPDisplaysDataType SPMemoryDataType SPStorageDataType
        
        echo -e "\n4. Network Configuration:"
        system_profiler SPNetworkDataType
        
    } > "$output_file"
    
    echo "Profile generated: $output_file"
}

# Kernel parameter monitor
monitor_kernel_params() {
    local duration="$1"
    local interval="${2:-5}"
    local log_file="$LOG_DIR/kernel_params.log"
    
    echo "Kernel Parameter Monitor:"
    echo "----------------------"
    
    {
        echo "=== Kernel Parameter Monitor ==="
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Memory stats
            vm_stat
            
            # Load average
            sysctl -n vm.loadavg
            
            # Process count
            ps ax | wc -l
            
            sleep "$interval"
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Hardware event monitor
monitor_hardware_events() {
    local duration="$1"
    local log_file="$LOG_DIR/hardware_events.log"
    
    echo "Hardware Event Monitor:"
    echo "--------------------"
    
    {
        echo "=== Hardware Event Monitor ==="
        echo "Start time: $(date)"
        
        # Monitor system events
        log stream --predicate 'eventMessage contains "hardware" or eventMessage contains "device"' &
        logger_pid=$!
        
        sleep "$duration"
        
        kill "$logger_pid" 2>/dev/null || true
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Main execution
main() {
    # Basic information
    show_kernel_info
    echo -e "\n"
    
    analyze_syscalls
    echo -e "\n"
    
    list_kernel_extensions
    echo -e "\n"
    
    analyze_hardware
    echo -e "\n"
    
    manage_sysctl
    echo -e "\n"
    
    analyze_boot
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    generate_system_profile
    
    monitor_kernel_params 10 2
    
    monitor_hardware_events 10
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
