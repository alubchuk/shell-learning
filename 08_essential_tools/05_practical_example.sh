#!/bin/bash

# Log Analysis and Network Monitoring Tool
# -------------------------------------
# A practical example combining find, tr, cut, and networking commands
# to create a comprehensive log analysis and network monitoring tool.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_DIR="/var/log"
readonly REPORT_DIR="$SCRIPT_DIR/reports"
readonly TEMP_DIR="/tmp/log_analysis_$$"
readonly CONFIG_FILE="$SCRIPT_DIR/config.ini"
readonly MAX_AGE_DAYS=7
readonly MONITORED_HOSTS=("example.com" "google.com" "github.com")
readonly MONITORED_PORTS=(80 443 22)

# Ensure directories exist
mkdir -p "$REPORT_DIR" "$TEMP_DIR"

# 1. Log File Management
# -------------------

find_log_files() {
    echo "Finding log files..."
    
    find "$LOG_DIR" \
        -type f \
        -name "*.log" \
        -mtime -"$MAX_AGE_DAYS" \
        -exec ls -lh {} \;
}

compress_old_logs() {
    echo "Compressing old logs..."
    
    find "$LOG_DIR" \
        -type f \
        -name "*.log" \
        -mtime +"$MAX_AGE_DAYS" \
        -exec gzip {} \;
}

# 2. Log Analysis Functions
# ----------------------

analyze_apache_logs() {
    local log_file="$1"
    echo "Analyzing Apache logs: $log_file"
    
    # Extract IP addresses and count occurrences
    echo "Top 10 IP addresses:"
    cut -d' ' -f1 "$log_file" | sort | uniq -c | sort -rn | head -10
    
    # Extract HTTP status codes
    echo -e "\nHTTP status code distribution:"
    cut -d' ' -f9 "$log_file" | sort | uniq -c | sort -rn
    
    # Extract requested URLs
    echo -e "\nTop 10 requested URLs:"
    cut -d' ' -f7 "$log_file" | sort | uniq -c | sort -rn | head -10
}

analyze_auth_logs() {
    local log_file="$1"
    echo "Analyzing auth logs: $log_file"
    
    # Failed login attempts
    echo "Failed login attempts:"
    grep "Failed password" "$log_file" | cut -d' ' -f9- | sort | uniq -c | sort -rn
    
    # Successful logins
    echo -e "\nSuccessful logins:"
    grep "Accepted password" "$log_file" | cut -d' ' -f9- | sort | uniq -c | sort -rn
}

analyze_system_logs() {
    local log_file="$1"
    echo "Analyzing system logs: $log_file"
    
    # Error messages
    echo "Error messages:"
    grep -i "error" "$log_file" | cut -d: -f2- | sort | uniq -c | sort -rn | head -10
    
    # Warning messages
    echo -e "\nWarning messages:"
    grep -i "warning" "$log_file" | cut -d: -f2- | sort | uniq -c | sort -rn | head -10
}

# 3. Network Monitoring
# ------------------

check_host_availability() {
    local host="$1"
    echo "Checking host: $host"
    
    # Ping test
    if ping -c 3 -W 2 "$host" >/dev/null 2>&1; then
        echo "$host is reachable"
        return 0
    else
        echo "$host is unreachable"
        return 1
    fi
}

check_port_availability() {
    local host="$1"
    local port="$2"
    
    if nc -z -w2 "$host" "$port" 2>/dev/null; then
        echo "Port $port on $host is open"
        return 0
    else
        echo "Port $port on $host is closed"
        return 1
    fi
}

monitor_network_latency() {
    local host="$1"
    echo "Monitoring latency to $host"
    
    ping -c 5 "$host" | tail -1 | cut -d'/' -f5
}

# 4. Traffic Analysis
# ----------------

analyze_network_traffic() {
    echo "Analyzing network traffic (30 seconds sample)..."
    
    # Capture traffic summary
    timeout 30 tcpdump -i any -nn -q > "$TEMP_DIR/traffic.cap"
    
    # Analyze protocols
    echo "Protocol distribution:"
    cat "$TEMP_DIR/traffic.cap" | \
        tr '[:upper:]' '[:lower:]' | \
        cut -d' ' -f5 | \
        sort | \
        uniq -c | \
        sort -rn
    
    # Analyze destinations
    echo -e "\nTop destinations:"
    cat "$TEMP_DIR/traffic.cap" | \
        grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
        sort | \
        uniq -c | \
        sort -rn | \
        head -10
}

# 5. Report Generation
# -----------------

generate_report() {
    local report_file="$REPORT_DIR/report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "System Analysis Report"
        echo "====================="
        echo "Generated: $(date)"
        echo
        
        echo "1. Log Analysis"
        echo "--------------"
        find_log_files
        echo
        
        echo "2. Network Status"
        echo "----------------"
        for host in "${MONITORED_HOSTS[@]}"; do
            check_host_availability "$host"
            for port in "${MONITORED_PORTS[@]}"; do
                check_port_availability "$host" "$port"
            done
            monitor_network_latency "$host"
            echo
        done
        
        echo "3. Traffic Analysis"
        echo "-----------------"
        analyze_network_traffic
        
    } | tee "$report_file"
    
    echo -e "\nReport saved to: $report_file"
}

# 6. Monitoring Functions
# -------------------

monitor_realtime() {
    echo "Starting real-time monitoring..."
    echo "Press Ctrl+C to stop"
    
    while true; do
        clear
        echo "=== Real-time System Monitor ==="
        echo "Time: $(date)"
        echo
        
        # System load
        echo "System Load:"
        uptime
        echo
        
        # Network connections
        echo "Network Connections:"
        netstat -ant | wc -l
        echo
        
        # Monitored hosts
        echo "Host Status:"
        for host in "${MONITORED_HOSTS[@]}"; do
            printf "%-20s: " "$host"
            if ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
                echo "UP"
            else
                echo "DOWN"
            fi
        done
        
        sleep 5
    done
}

# 7. Command Line Interface
# ----------------------

show_help() {
    cat << EOF
Log Analysis and Network Monitoring Tool

Usage: $0 [options] <command>

Commands:
    analyze     Analyze log files
    monitor     Start real-time monitoring
    report      Generate comprehensive report
    compress    Compress old log files
    help        Show this help message

Options:
    -d, --dir DIR    Specify log directory (default: /var/log)
    -a, --age DAYS   Specify max age for logs (default: 7 days)
    -h, --help       Show this help message
EOF
}

# Main execution
main() {
    case "${1:-}" in
        analyze)
            find_log_files
            ;;
        monitor)
            monitor_realtime
            ;;
        report)
            generate_report
            ;;
        compress)
            compress_old_logs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Cleanup function
cleanup() {
    rm -rf "$TEMP_DIR"
}

# Set cleanup trap
trap cleanup EXIT

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
