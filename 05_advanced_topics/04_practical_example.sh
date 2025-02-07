#!/bin/bash

# Process Monitor and Control Tool
# ------------------------------
# This script demonstrates a practical application of advanced shell scripting concepts
# including process management, signal handling, and error handling.

# Global configuration
CONFIG_DIR="${HOME}/.config/procmon"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
LOG_FILE="${CONFIG_DIR}/procmon.log"
PID_FILE="${CONFIG_DIR}/procmon.pid"
MONITOR_INTERVAL=5
DEBUG=${DEBUG:-false}

# Global state
declare -A MONITORED_PROCESSES
SHUTDOWN_REQUESTED=false

# Logging functions
log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_warning() {
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
    echo "[WARNING] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_debug() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1"
        echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    fi
}

# Cleanup function
cleanup() {
    log_info "Performing cleanup..."
    rm -f "$PID_FILE"
    
    # Terminate any child processes
    jobs -p | xargs -r kill 2>/dev/null
    
    log_info "Cleanup completed"
}

# Signal handlers
handle_shutdown() {
    log_info "Shutdown signal received"
    SHUTDOWN_REQUESTED=true
}

handle_reload() {
    log_info "Reload signal received"
    load_config
}

# Error handler
error_handler() {
    local line_num="$1"
    local command="$2"
    local error_code="${3:-1}"
    log_error "Command '$command' failed with error code $error_code at line $line_num"
}

# Initialize environment
initialize() {
    # Create configuration directory if needed
    if [ ! -d "$CONFIG_DIR" ]; then
        mkdir -p "$CONFIG_DIR" || {
            log_error "Failed to create config directory: $CONFIG_DIR"
            exit 1
        }
    fi
    
    # Create default config if needed
    if [ ! -f "$CONFIG_FILE" ]; then
        cat > "$CONFIG_FILE" << EOF
# Process Monitor Configuration

# Format: process_name=max_cpu,max_mem,restart_on_crash,max_restarts
# Example:
nginx=50,500,true,3
mysql=70,1000,true,5
EOF
        log_info "Created default configuration file"
    fi
    
    # Check if already running
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_error "Process monitor is already running with PID $pid"
            exit 1
        fi
        rm -f "$PID_FILE"
    fi
    
    # Save current PID
    echo $$ > "$PID_FILE"
    
    # Set up signal handlers
    trap 'handle_shutdown' SIGTERM SIGINT
    trap 'handle_reload' SIGHUP
    trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR
    trap 'cleanup' EXIT
    
    # Load initial configuration
    load_config
    
    log_info "Initialization completed"
}

# Load configuration
load_config() {
    log_info "Loading configuration from $CONFIG_FILE"
    
    # Clear current configuration
    MONITORED_PROCESSES=()
    
    # Read configuration file
    while IFS='=' read -r process_name limits; do
        # Skip comments and empty lines
        [[ "$process_name" =~ ^#.*$ ]] && continue
        [ -z "$process_name" ] && continue
        
        # Parse limits
        IFS=',' read -r max_cpu max_mem restart_on_crash max_restarts <<< "$limits"
        
        # Validate and store configuration
        if [[ "$max_cpu" =~ ^[0-9]+$ ]] && \
           [[ "$max_mem" =~ ^[0-9]+$ ]] && \
           [[ "$restart_on_crash" =~ ^(true|false)$ ]] && \
           [[ "$max_restarts" =~ ^[0-9]+$ ]]; then
            MONITORED_PROCESSES["$process_name"]="$max_cpu,$max_mem,$restart_on_crash,$max_restarts,0"
            log_debug "Configured monitoring for $process_name: CPU=$max_cpu%, MEM=$max_mem MB"
        else
            log_warning "Invalid configuration for $process_name: $limits"
        fi
    done < "$CONFIG_FILE"
    
    log_info "Configuration loaded: ${#MONITORED_PROCESSES[@]} processes configured"
}

# Get process statistics
get_process_stats() {
    local process_name="$1"
    local pid
    
    # Find process PID
    pid=$(pgrep -x "$process_name" | head -n1)
    
    if [ -n "$pid" ]; then
        # Get CPU and memory usage
        local stats=$(ps -p "$pid" -o %cpu=,%mem=)
        echo "$pid $stats"
    else
        echo ""
    fi
}

# Check process health
check_process_health() {
    local process_name="$1"
    local config="${MONITORED_PROCESSES[$process_name]}"
    
    IFS=',' read -r max_cpu max_mem restart_on_crash max_restarts restart_count <<< "$config"
    
    # Get process statistics
    local stats=$(get_process_stats "$process_name")
    
    if [ -z "$stats" ]; then
        if [ "$restart_on_crash" = true ] && [ "$restart_count" -lt "$max_restarts" ]; then
            log_warning "Process $process_name is not running. Attempting restart..."
            if restart_process "$process_name"; then
                MONITORED_PROCESSES["$process_name"]="$max_cpu,$max_mem,$restart_on_crash,$max_restarts,$((restart_count + 1))"
            fi
        else
            log_error "Process $process_name is not running and won't be restarted (count: $restart_count, max: $max_restarts)"
        fi
        return
    fi
    
    # Parse statistics
    read -r pid cpu mem <<< "$stats"
    
    # Check CPU usage
    if (( $(echo "$cpu > $max_cpu" | bc -l) )); then
        log_warning "Process $process_name ($pid) CPU usage too high: $cpu% > $max_cpu%"
    fi
    
    # Check memory usage
    if (( $(echo "$mem > $max_mem" | bc -l) )); then
        log_warning "Process $process_name ($pid) memory usage too high: $mem% > $max_mem%"
    fi
    
    log_debug "Process $process_name ($pid) health: CPU=$cpu%, MEM=$mem%"
}

# Restart process
restart_process() {
    local process_name="$1"
    
    log_info "Attempting to restart $process_name"
    
    # This is a simplified restart - in practice, you'd need process-specific restart commands
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl restart "$process_name" 2>/dev/null
    else
        sudo service "$process_name" restart 2>/dev/null
    fi
    
    # Check if restart was successful
    sleep 2
    if [ -n "$(get_process_stats "$process_name")" ]; then
        log_info "Successfully restarted $process_name"
        return 0
    else
        log_error "Failed to restart $process_name"
        return 1
    fi
}

# Main monitoring loop
monitor_processes() {
    log_info "Starting process monitor"
    
    while [ "$SHUTDOWN_REQUESTED" = false ]; do
        for process_name in "${!MONITORED_PROCESSES[@]}"; do
            check_process_health "$process_name"
        done
        
        sleep "$MONITOR_INTERVAL"
    done
    
    log_info "Process monitor shutting down"
}

# Show status
show_status() {
    echo "=== Process Monitor Status ==="
    echo "Monitor PID: $$"
    echo "Configuration file: $CONFIG_FILE"
    echo "Log file: $LOG_FILE"
    echo
    echo "Monitored Processes:"
    printf "%-20s %-10s %-10s %-10s %-10s %-10s\n" "NAME" "PID" "CPU%" "MEM%" "MAX CPU%" "MAX MEM%"
    echo "--------------------------------------------------------------------"
    
    for process_name in "${!MONITORED_PROCESSES[@]}"; do
        local config="${MONITORED_PROCESSES[$process_name]}"
        IFS=',' read -r max_cpu max_mem restart_on_crash max_restarts restart_count <<< "$config"
        
        local stats=$(get_process_stats "$process_name")
        if [ -n "$stats" ]; then
            read -r pid cpu mem <<< "$stats"
            printf "%-20s %-10s %-10.1f %-10.1f %-10s %-10s\n" \
                "$process_name" "$pid" "$cpu" "$mem" "$max_cpu" "$max_mem"
        else
            printf "%-20s %-10s %-10s %-10s %-10s %-10s\n" \
                "$process_name" "NOT RUNNING" "-" "-" "$max_cpu" "$max_mem"
        fi
    done
}

# Parse command line arguments
case "${1:-}" in
    start)
        initialize
        monitor_processes
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            kill -TERM $(cat "$PID_FILE")
            log_info "Stop signal sent to process monitor"
        else
            log_error "Process monitor is not running"
            exit 1
        fi
        ;;
    restart)
        "$0" stop
        sleep 2
        "$0" start
        ;;
    reload)
        if [ -f "$PID_FILE" ]; then
            kill -HUP $(cat "$PID_FILE")
            log_info "Reload signal sent to process monitor"
        else
            log_error "Process monitor is not running"
            exit 1
        fi
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            show_status
        else
            log_error "Process monitor is not running"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|reload|status}"
        exit 1
        ;;
esac

exit 0
