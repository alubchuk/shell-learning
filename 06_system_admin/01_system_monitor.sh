#!/bin/bash

# System Resource Monitor
# ---------------------
# This script monitors various system resources and generates alerts
# when thresholds are exceeded.

# Configuration
MONITOR_INTERVAL=60  # seconds
CONFIG_DIR="${HOME}/.config/sysmon"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
LOG_FILE="${CONFIG_DIR}/sysmon.log"
ALERT_LOG="${CONFIG_DIR}/alerts.log"

# Default thresholds
CPU_THRESHOLD=80    # percentage
MEM_THRESHOLD=90    # percentage
DISK_THRESHOLD=90   # percentage
LOAD_THRESHOLD=4    # load average
INODE_THRESHOLD=90  # percentage

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'  # No Color

# Ensure configuration directory exists
mkdir -p "$CONFIG_DIR"

# Create default configuration if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# System Monitor Configuration

# Resource thresholds (percentage)
CPU_THRESHOLD=$CPU_THRESHOLD
MEM_THRESHOLD=$MEM_THRESHOLD
DISK_THRESHOLD=$DISK_THRESHOLD
LOAD_THRESHOLD=$LOAD_THRESHOLD
INODE_THRESHOLD=$INODE_THRESHOLD

# Monitored directories (space-separated)
MONITOR_DIRS="/ /home"

# Network interfaces to monitor (space-separated)
MONITOR_INTERFACES="en0 en1"

# Alert commands (uncomment and modify as needed)
#ALERT_EMAIL="admin@example.com"
#ALERT_SLACK_WEBHOOK="https://hooks.slack.com/services/..."
EOF
fi

# Source configuration
source "$CONFIG_FILE"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        ERROR)   echo -e "${RED}[$timestamp] [$level] $message${NC}" ;;
        WARNING) echo -e "${YELLOW}[$timestamp] [$level] $message${NC}" ;;
        INFO)    echo -e "${GREEN}[$timestamp] [$level] $message${NC}" ;;
        *)       echo "[$timestamp] [$level] $message" ;;
    esac
}

alert() {
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log alert
    echo "[$timestamp] $message" >> "$ALERT_LOG"
    
    # Email alert if configured
    if [ -n "${ALERT_EMAIL:-}" ]; then
        echo "$message" | mail -s "System Alert: $(hostname)" "$ALERT_EMAIL"
    fi
    
    # Slack alert if configured
    if [ -n "${ALERT_SLACK_WEBHOOK:-}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"System Alert ($(hostname)): $message\"}" \
            "$ALERT_SLACK_WEBHOOK"
    fi
}

# CPU Usage Monitor
check_cpu() {
    local cpu_usage
    
    # Get CPU usage (depends on OS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    else
        # Linux
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    fi
    
    echo "CPU Usage: ${cpu_usage}%"
    
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        alert "High CPU usage: ${cpu_usage}%"
        return 1
    fi
    return 0
}

# Memory Usage Monitor
check_memory() {
    local mem_usage
    
    # Get memory usage (depends on OS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local total_mem=$(sysctl -n hw.memsize)
        local used_mem=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
        used_mem=$((used_mem * 4096))  # Convert pages to bytes
        mem_usage=$(echo "scale=2; $used_mem * 100 / $total_mem" | bc)
    else
        # Linux
        mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100}')
    fi
    
    echo "Memory Usage: ${mem_usage}%"
    
    if (( $(echo "$mem_usage > $MEM_THRESHOLD" | bc -l) )); then
        alert "High memory usage: ${mem_usage}%"
        return 1
    fi
    return 0
}

# Disk Space Monitor
check_disk_space() {
    local has_alert=0
    
    for dir in $MONITOR_DIRS; do
        if [ -d "$dir" ]; then
            local usage
            if [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                usage=$(df -h "$dir" | tail -1 | awk '{print $5}' | tr -d '%')
            else
                # Linux
                usage=$(df -h "$dir" | tail -1 | awk '{print $5}' | tr -d '%')
            fi
            
            echo "Disk Usage ($dir): ${usage}%"
            
            if [ "$usage" -gt "$DISK_THRESHOLD" ]; then
                alert "High disk usage on $dir: ${usage}%"
                has_alert=1
            fi
            
            # Check inode usage on Linux
            if [[ "$OSTYPE" != "darwin"* ]]; then
                local inode_usage=$(df -i "$dir" | tail -1 | awk '{print $5}' | tr -d '%')
                echo "Inode Usage ($dir): ${inode_usage}%"
                
                if [ "$inode_usage" -gt "$INODE_THRESHOLD" ]; then
                    alert "High inode usage on $dir: ${inode_usage}%"
                    has_alert=1
                fi
            fi
        else
            log "WARNING" "Directory $dir does not exist"
        fi
    done
    
    return $has_alert
}

# Load Average Monitor
check_load_average() {
    local load_avg
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        load_avg=$(sysctl -n vm.loadavg | awk '{print $2}')
    else
        # Linux
        load_avg=$(cat /proc/loadavg | awk '{print $1}')
    fi
    
    echo "Load Average (1m): $load_avg"
    
    if (( $(echo "$load_avg > $LOAD_THRESHOLD" | bc -l) )); then
        alert "High system load: $load_avg"
        return 1
    fi
    return 0
}

# Network Statistics Monitor
check_network() {
    local has_alert=0
    
    for interface in $MONITOR_INTERFACES; do
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if ! netstat -I "$interface" 1 1 >/dev/null 2>&1; then
                log "WARNING" "Network interface $interface not found"
                continue
            fi
            
            local stats=$(netstat -I "$interface" 1 1 | tail -1)
            local bytes_in=$(echo "$stats" | awk '{print $7}')
            local bytes_out=$(echo "$stats" | awk '{print $10}')
        else
            # Linux
            if [ ! -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
                log "WARNING" "Network interface $interface not found"
                continue
            fi
            
            local bytes_in=$(cat "/sys/class/net/$interface/statistics/rx_bytes")
            local bytes_out=$(cat "/sys/class/net/$interface/statistics/tx_bytes")
        fi
        
        echo "Network Interface $interface:"
        echo "  Bytes In: $bytes_in"
        echo "  Bytes Out: $bytes_out"
    done
    
    return $has_alert
}

# Process Monitor
check_processes() {
    local top_processes
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        top_processes=$(ps -arcwwwxo command=,pid=,%cpu=,%mem= | head -11 | tail -10)
    else
        # Linux
        top_processes=$(ps aux --sort=-%cpu | head -11 | tail -10)
    fi
    
    echo "Top Processes by CPU Usage:"
    echo "$top_processes"
}

# System Information
show_system_info() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS Version: $(sw_vers -productVersion)"
    else
        echo "Distribution: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    fi
    echo "Uptime: $(uptime)"
}

# Main monitoring function
monitor_system() {
    while true; do
        clear
        show_system_info
        echo
        
        echo "=== Resource Usage ==="
        check_cpu
        check_memory
        check_load_average
        echo
        
        echo "=== Disk Usage ==="
        check_disk_space
        echo
        
        echo "=== Network Statistics ==="
        check_network
        echo
        
        echo "=== Process Information ==="
        check_processes
        
        sleep "$MONITOR_INTERVAL"
    done
}

# Parse command line arguments
case "${1:-}" in
    start)
        log "INFO" "Starting system monitor"
        monitor_system
        ;;
    check)
        log "INFO" "Performing single system check"
        show_system_info
        check_cpu
        check_memory
        check_load_average
        check_disk_space
        check_network
        check_processes
        ;;
    *)
        echo "Usage: $0 {start|check}"
        exit 1
        ;;
esac

exit 0
