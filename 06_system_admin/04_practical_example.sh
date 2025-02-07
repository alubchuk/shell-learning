#!/bin/bash

# System Administration Dashboard
# ----------------------------
# This script provides a comprehensive system administration dashboard
# combining monitoring, backup management, and system maintenance.

# Configuration
CONFIG_DIR="${HOME}/.config/sysadmin"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
LOG_FILE="${CONFIG_DIR}/dashboard.log"
BACKUP_DIR="${HOME}/backups"
STATUS_FILE="/tmp/dashboard_status"
REFRESH_INTERVAL=60

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'  # No Color

# Ensure required directories exist
mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"

# Create default configuration if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# System Administration Dashboard Configuration

# Monitoring settings
MONITOR_INTERVAL=60
CPU_THRESHOLD=80
MEM_THRESHOLD=90
DISK_THRESHOLD=90
MONITOR_DIRS="/ /home"
MONITOR_INTERFACES="en0 en1"

# Backup settings
BACKUP_SCHEDULE="daily"
BACKUP_TYPE="incremental"
COMPRESSION="gzip"
MAX_BACKUPS=7

# Maintenance settings
AUTO_UPDATE=true
UPDATE_SCHEDULE="weekly"
SECURITY_SCAN=true
CLEANUP_AGE=7

# Alert settings
ALERT_EMAIL=""
SLACK_WEBHOOK=""
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
        DEBUG)   echo -e "${BLUE}[$timestamp] [$level] $message${NC}" ;;
    esac
}

# System Information Functions
# --------------------------

get_system_info() {
    {
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
    } > "$STATUS_FILE"
}

# Resource Monitoring Functions
# ---------------------------

get_cpu_usage() {
    local cpu_usage
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    fi
    
    echo "$cpu_usage"
}

get_memory_usage() {
    local mem_usage
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local total_mem=$(sysctl -n hw.memsize)
        local used_mem=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
        used_mem=$((used_mem * 4096))
        mem_usage=$(echo "scale=2; $used_mem * 100 / $total_mem" | bc)
    else
        mem_usage=$(free | grep Mem | awk '{print $3/$2 * 100}')
    fi
    
    echo "$mem_usage"
}

get_disk_usage() {
    {
        echo "=== Disk Usage ==="
        df -h | awk 'NR==1 || $5 > 80'
    } >> "$STATUS_FILE"
}

get_network_stats() {
    {
        echo "=== Network Statistics ==="
        for interface in $MONITOR_INTERFACES; do
            if [[ "$OSTYPE" == "darwin"* ]]; then
                netstat -I "$interface" 1 1 2>/dev/null
            else
                if [ -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
                    echo "Interface: $interface"
                    echo "RX: $(cat /sys/class/net/$interface/statistics/rx_bytes)"
                    echo "TX: $(cat /sys/class/net/$interface/statistics/tx_bytes)"
                fi
            fi
        done
    } >> "$STATUS_FILE"
}

# Backup Status Functions
# ---------------------

get_backup_status() {
    {
        echo "=== Backup Status ==="
        echo "Last backup:"
        ls -lt "$BACKUP_DIR" | head -2
        
        echo "Backup space usage:"
        du -sh "$BACKUP_DIR"
        
        echo "Next scheduled backup:"
        case "$BACKUP_SCHEDULE" in
            daily)   next=$(date -v+1d +"%Y-%m-%d 00:00:00") ;;
            weekly)  next=$(date -v+1w +"%Y-%m-%d 00:00:00") ;;
            monthly) next=$(date -v+1m +"%Y-%m-%d 00:00:00") ;;
        esac
        echo "$next"
    } >> "$STATUS_FILE"
}

# System Maintenance Functions
# -------------------------

check_updates() {
    {
        echo "=== System Updates ==="
        if [[ "$OSTYPE" == "darwin"* ]]; then
            softwareupdate -l
            if command -v brew >/dev/null; then
                echo "Homebrew updates available:"
                brew outdated
            fi
        else
            if command -v apt-get >/dev/null; then
                apt-get -s upgrade | grep -i "upgraded"
            elif command -v dnf >/dev/null; then
                dnf check-update
            fi
        fi
    } >> "$STATUS_FILE"
}

check_security() {
    {
        echo "=== Security Status ==="
        
        # Check firewall status
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Firewall status:"
            /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
            
            echo "System Integrity Protection:"
            csrutil status
        else
            if command -v ufw >/dev/null; then
                echo "Firewall status:"
                ufw status
            fi
        fi
        
        # Check for world-writable files in sensitive directories
        echo "World-writable files in sensitive directories:"
        find /etc /usr/bin -type f -perm -0002 -ls 2>/dev/null
        
        # Check failed login attempts
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Recent failed login attempts:"
            log show --predicate 'eventMessage contains "authentication failed"' --last 1h
        else
            echo "Recent failed login attempts:"
            grep "Failed password" /var/log/auth.log 2>/dev/null | tail -5
        fi
    } >> "$STATUS_FILE"
}

# Dashboard Display Functions
# ------------------------

display_status_bar() {
    local value=$1
    local max=$2
    local width=50
    local filled=$(echo "scale=0; $width * $value / $max" | bc)
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d%%\n" "$value"
}

display_dashboard() {
    clear
    cat "$STATUS_FILE"
    
    # Display real-time resource usage
    echo "=== Resource Usage ==="
    local cpu=$(get_cpu_usage)
    local mem=$(get_memory_usage)
    
    echo -n "CPU Usage:    "
    display_status_bar "$cpu" 100
    
    echo -n "Memory Usage: "
    display_status_bar "$mem" 100
    
    # Check thresholds and display warnings
    if [ "${cpu%.*}" -gt "$CPU_THRESHOLD" ]; then
        echo -e "${RED}WARNING: High CPU usage${NC}"
    fi
    if [ "${mem%.*}" -gt "$MEM_THRESHOLD" ]; then
        echo -e "${RED}WARNING: High memory usage${NC}"
    fi
}

# Alert Functions
# -------------

send_alert() {
    local message="$1"
    local level="$2"
    
    log "$level" "$message"
    
    # Email alert
    if [ -n "$ALERT_EMAIL" ]; then
        echo "$message" | mail -s "System Alert: $level" "$ALERT_EMAIL"
    fi
    
    # Slack alert
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"[$level] $message\"}" \
            "$SLACK_WEBHOOK"
    fi
}

# Main Dashboard Loop
# -----------------

run_dashboard() {
    log "INFO" "Starting system administration dashboard"
    
    while true; do
        # Collect system information
        get_system_info
        get_disk_usage
        get_network_stats
        get_backup_status
        
        if [ "$AUTO_UPDATE" = true ]; then
            check_updates
        fi
        
        if [ "$SECURITY_SCAN" = true ]; then
            check_security
        fi
        
        # Display dashboard
        display_dashboard
        
        # Check for critical conditions
        cpu=$(get_cpu_usage)
        mem=$(get_memory_usage)
        
        if [ "${cpu%.*}" -gt "$CPU_THRESHOLD" ]; then
            send_alert "High CPU usage: $cpu%" "WARNING"
        fi
        
        if [ "${mem%.*}" -gt "$MEM_THRESHOLD" ]; then
            send_alert "High memory usage: $mem%" "WARNING"
        fi
        
        sleep "$REFRESH_INTERVAL"
    done
}

# Command-line Interface
# --------------------

show_help() {
    cat << EOF
System Administration Dashboard
Usage: $0 <command> [options]

Commands:
    start              Start the dashboard
    status            Show current system status
    backup            Perform backup
    update            Check for updates
    security          Run security scan
    help              Show this help message

Options:
    -i, --interval    Refresh interval in seconds
    -q, --quiet       Suppress output
    --no-color        Disable colored output

Example:
    $0 start
    $0 start -i 30
    $0 status
EOF
}

# Parse command line arguments
case "${1:-}" in
    start)
        shift
        while [ $# -gt 0 ]; do
            case "$1" in
                -i|--interval)
                    REFRESH_INTERVAL="$2"
                    shift 2
                    ;;
                -q|--quiet)
                    exec 1>/dev/null
                    shift
                    ;;
                --no-color)
                    RED=''
                    GREEN=''
                    YELLOW=''
                    BLUE=''
                    NC=''
                    shift
                    ;;
                *)
                    echo "Unknown option: $1"
                    show_help
                    exit 1
                    ;;
            esac
        done
        run_dashboard
        ;;
    status)
        get_system_info
        get_disk_usage
        get_network_stats
        get_backup_status
        display_dashboard
        ;;
    backup)
        # Call backup script
        if [ -f "./02_backup_tool.sh" ]; then
            ./02_backup_tool.sh create
        else
            log "ERROR" "Backup tool not found"
            exit 1
        fi
        ;;
    update)
        check_updates
        cat "$STATUS_FILE"
        ;;
    security)
        check_security
        cat "$STATUS_FILE"
        ;;
    help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
