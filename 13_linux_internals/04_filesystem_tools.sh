#!/bin/bash

# Filesystem Tools
# ------------
# This script demonstrates various tools and techniques
# for analyzing and managing filesystem operations.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"
readonly TEST_DIR="$OUTPUT_DIR/test"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$TEST_DIR"

# 1. Filesystem Information
# -------------------

show_filesystem_info() {
    echo "Filesystem Information:"
    echo "---------------------"
    
    # Mount points
    echo "1. Mount points:"
    mount | head -n 5
    
    # Disk usage
    echo -e "\n2. Disk usage:"
    df -h
    
    # File system types
    echo -e "\n3. Filesystem types:"
    mount | awk '{print $5}' | sort | uniq -c
    
    # Disk information
    echo -e "\n4. Disk information:"
    diskutil list
}

# 2. Inode Management
# --------------

analyze_inodes() {
    echo "Inode Analysis:"
    echo "--------------"
    
    # Inode usage
    echo "1. Inode usage:"
    df -i
    
    # File inode information
    echo -e "\n2. File inode details:"
    ls -i "$0"
    
    # Directory inode information
    echo -e "\n3. Directory inode details:"
    ls -id "$SCRIPT_DIR"
    
    # Find files by inode
    echo -e "\n4. Finding files by inode:"
    find "$SCRIPT_DIR" -inum "$(ls -i "$0" | awk '{print $1}')"
}

# 3. Mount Operations
# --------------

demonstrate_mounts() {
    echo "Mount Operations:"
    echo "----------------"
    
    # List mounted filesystems
    echo "1. Mounted filesystems:"
    mount | grep -E "^/dev"
    
    # Mount points
    echo -e "\n2. Mount points:"
    ls -l /Volumes
    
    # Mount options
    echo -e "\n3. Mount options:"
    mount | awk '{print $1, $3, $6}' | head -n 5
}

# 4. Disk I/O Analysis
# ---------------

analyze_disk_io() {
    echo "Disk I/O Analysis:"
    echo "-----------------"
    
    # IO statistics
    echo "1. IO statistics:"
    iostat 1 5
    
    # Disk activity
    echo -e "\n2. Disk activity:"
    fs_usage -f filesys | head -n 10
    
    # IO operations
    echo -e "\n3. IO operations:"
    iotop -P 2>/dev/null || echo "iotop not available"
}

# 5. File System Operations
# -------------------

demonstrate_fs_ops() {
    local test_file="$TEST_DIR/test.txt"
    
    echo "Filesystem Operations:"
    echo "--------------------"
    
    # Create test file
    echo "1. Creating test file:"
    echo "Test content" > "$test_file"
    ls -l "$test_file"
    
    # File attributes
    echo -e "\n2. File attributes:"
    ls -l@ "$test_file"
    
    # File operations
    echo -e "\n3. File operations:"
    cp "$test_file" "${test_file}.bak"
    mv "${test_file}.bak" "${test_file}.moved"
    rm "${test_file}.moved"
    
    # Directory operations
    echo -e "\n4. Directory operations:"
    mkdir -p "$TEST_DIR/subdir"
    rmdir "$TEST_DIR/subdir"
}

# 6. File System Debugging
# ------------------

debug_filesystem() {
    echo "Filesystem Debugging:"
    echo "-------------------"
    
    # System calls
    echo "1. Filesystem system calls:"
    fs_usage -f filesys | head -n 5
    
    # File access patterns
    echo -e "\n2. File access patterns:"
    lsof | head -n 5
    
    # IO wait
    echo -e "\n3. IO wait statistics:"
    iostat -c 2 5
}

# 7. Practical Examples
# ----------------

# Filesystem monitor
monitor_filesystem() {
    local directory="$1"
    local duration="$2"
    local log_file="$LOG_DIR/filesystem_monitor.log"
    
    echo "Filesystem Monitor:"
    echo "-----------------"
    
    {
        echo "=== Filesystem Monitor ==="
        echo "Directory: $directory"
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Directory changes
            ls -laR "$directory"
            
            # IO activity
            fs_usage -f filesys | head -n 5
            
            sleep 1
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# IO activity profiler
profile_io_activity() {
    local duration="$1"
    local output_file="$LOG_DIR/io_profile.log"
    
    echo "IO Activity Profiler:"
    echo "------------------"
    
    {
        echo "=== IO Activity Profile ==="
        echo "Start time: $(date)"
        
        # Monitor IO activity
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Disk statistics
            iostat
            
            # Process IO
            iotop -P -n 1 2>/dev/null || true
            
            sleep 1
        done
        
        echo "End time: $(date)"
    } > "$output_file"
    
    echo "Profiling complete. Check $output_file for details"
}

# Filesystem stress test
stress_test_filesystem() {
    local directory="$1"
    local file_count="${2:-100}"
    local size="${3:-1024}"  # KB
    
    echo "Filesystem Stress Test:"
    echo "--------------------"
    
    # Create test directory
    local test_dir="$directory/stress_test"
    mkdir -p "$test_dir"
    
    echo "1. Creating $file_count files of ${size}KB each"
    for i in $(seq 1 "$file_count"); do
        dd if=/dev/zero of="$test_dir/file$i" bs=1024 count="$size" 2>/dev/null
        echo -n "."
        if ((i % 10 == 0)); then
            echo " $i"
        fi
    done
    
    echo -e "\n2. File creation complete"
    du -sh "$test_dir"
    
    echo -e "\n3. Reading files"
    find "$test_dir" -type f -exec cat {} \; >/dev/null
    
    echo -e "\n4. Cleanup"
    rm -rf "$test_dir"
}

# Main execution
main() {
    # Basic analysis
    show_filesystem_info
    echo -e "\n"
    
    analyze_inodes
    echo -e "\n"
    
    demonstrate_mounts
    echo -e "\n"
    
    analyze_disk_io
    echo -e "\n"
    
    demonstrate_fs_ops
    echo -e "\n"
    
    debug_filesystem
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    monitor_filesystem "$TEST_DIR" 10
    
    profile_io_activity 10
    
    stress_test_filesystem "$TEST_DIR" 10 1
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
