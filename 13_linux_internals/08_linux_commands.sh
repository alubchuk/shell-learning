#!/bin/bash

# Linux Essential Commands
# ---------------------
# This script demonstrates various essential Linux commands
# and their common use cases for system administration.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. System Information Commands
# --------------------------

show_system_info() {
    echo "System Information Commands:"
    echo "-------------------------"
    
    # Basic system info
    echo "1. System and kernel information:"
    uname -a
    
    # OS release info
    echo -e "\n2. OS release information:"
    sw_vers || echo "Not on macOS"
    
    # CPU info
    echo -e "\n3. CPU information:"
    sysctl -n machdep.cpu.brand_string
    
    # Memory info
    echo -e "\n4. Memory information:"
    vm_stat
    
    # Disk usage
    echo -e "\n5. Disk usage:"
    df -h
}

# 2. Process Management
# ------------------

manage_processes() {
    echo "Process Management Commands:"
    echo "-------------------------"
    
    # Process listing
    echo "1. Process listing (top 5 by CPU):"
    ps aux | sort -nr -k 3 | head -5
    
    # Process tree
    echo -e "\n2. Process hierarchy:"
    pstree -g 2 || ps -ejH | head -5
    
    # Process priorities
    echo -e "\n3. Process priorities:"
    ps -el | head -5
    
    # Background jobs
    echo -e "\n4. Background jobs:"
    jobs
}

# 3. File System Operations
# ----------------------

demonstrate_file_ops() {
    echo "File System Operations:"
    echo "---------------------"
    
    # Create test directory
    local test_dir="$OUTPUT_DIR/file_ops_test"
    mkdir -p "$test_dir"
    
    # File creation and manipulation
    echo "1. File operations:"
    {
        # Create files
        echo "Creating test files..."
        touch "$test_dir/file1.txt"
        echo "Hello World" > "$test_dir/file2.txt"
        
        # File permissions
        echo -e "\nChanging permissions..."
        chmod 644 "$test_dir/file1.txt"
        ls -l "$test_dir/file1.txt"
        
        # File ownership
        echo -e "\nFile ownership:"
        ls -ln "$test_dir/file2.txt"
        
        # Find files
        echo -e "\nFinding files:"
        find "$test_dir" -type f -name "*.txt"
    }
    
    # Cleanup
    rm -rf "$test_dir"
}

# 4. Network Commands
# ----------------

show_network_info() {
    echo "Network Commands:"
    echo "---------------"
    
    # Network interfaces
    echo "1. Network interfaces:"
    ifconfig | head -10
    
    # Network connections
    echo -e "\n2. Network connections:"
    netstat -an | head -5
    
    # DNS lookup
    echo -e "\n3. DNS lookup:"
    dig google.com +short || nslookup google.com
    
    # Network routing
    echo -e "\n4. Routing table:"
    netstat -nr | head -5
}

# 5. User Management
# ---------------

demonstrate_user_mgmt() {
    echo "User Management Commands:"
    echo "----------------------"
    
    # Current user info
    echo "1. Current user information:"
    id
    
    # User list
    echo -e "\n2. User list:"
    dscl . -list /Users | grep -v '^_' | head -5
    
    # Group info
    echo -e "\n3. Group information:"
    groups
    
    # Login history
    echo -e "\n4. Login history:"
    last | head -5
}

# 6. System Maintenance
# -----------------

show_maintenance_tools() {
    echo "System Maintenance Commands:"
    echo "-------------------------"
    
    # Disk usage by directory
    echo "1. Directory sizes:"
    du -sh /* 2>/dev/null | sort -hr | head -5
    
    # Open files
    echo -e "\n2. Open files:"
    lsof | head -5
    
    # System logs
    echo -e "\n3. System logs:"
    log show --last 5m | head -5
    
    # Service status
    echo -e "\n4. Service status:"
    launchctl list | head -5
}

# 7. Performance Analysis
# -------------------

analyze_performance() {
    echo "Performance Analysis Commands:"
    echo "---------------------------"
    
    # CPU load
    echo "1. CPU load averages:"
    uptime
    
    # Memory usage
    echo -e "\n2. Memory usage:"
    vm_stat 1 2
    
    # Disk I/O
    echo -e "\n3. Disk I/O:"
    iostat 1 2
    
    # Network I/O
    echo -e "\n4. Network I/O:"
    netstat -ib | head -5
}

# 8. Security Tools
# -------------

show_security_tools() {
    echo "Security Commands:"
    echo "----------------"
    
    # File permissions
    echo "1. Special permissions:"
    find / -type f -perm +6000 2>/dev/null | head -5
    
    # Network security
    echo -e "\n2. Listening ports:"
    netstat -an | grep LISTEN | head -5
    
    # Process owners
    echo -e "\n3. Process ownership:"
    ps aux | head -5
    
    # System integrity
    echo -e "\n4. System integrity status:"
    csrutil status || echo "System Integrity Protection status not available"
}

# Main execution
main() {
    # System information
    show_system_info
    echo -e "\n"
    
    # Process management
    manage_processes
    echo -e "\n"
    
    # File operations
    demonstrate_file_ops
    echo -e "\n"
    
    # Network information
    show_network_info
    echo -e "\n"
    
    # User management
    demonstrate_user_mgmt
    echo -e "\n"
    
    # System maintenance
    show_maintenance_tools
    echo -e "\n"
    
    # Performance analysis
    analyze_performance
    echo -e "\n"
    
    # Security tools
    show_security_tools
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
