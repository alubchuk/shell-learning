#!/bin/bash

# =============================================================================
# Shell Script Logging Examples
# This script demonstrates comprehensive logging techniques for shell scripts,
# including different log levels, formats, and destinations.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Logging Configuration
# -----------------------------------------------------------------------------

# Log levels
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

# Default configuration
LOG_LEVEL=${LOG_LEVEL:-INFO}
LOG_FORMAT=${LOG_FORMAT:-text}  # text, json, syslog
LOG_OUTPUT=${LOG_OUTPUT:-console}  # console, file, syslog
LOG_FILE=${LOG_FILE:-/tmp/example.log}
LOG_MAX_SIZE=${LOG_MAX_SIZE:-10485760}  # 10MB
LOG_BACKUP_COUNT=${LOG_BACKUP_COUNT:-5}

# ANSI color codes
declare -A LOG_COLORS=(
    [DEBUG]="\033[0;36m"    # Cyan
    [INFO]="\033[0;32m"     # Green
    [WARN]="\033[0;33m"     # Yellow
    [ERROR]="\033[0;31m"    # Red
    [FATAL]="\033[0;35m"    # Purple
    [RESET]="\033[0m"
)

# -----------------------------------------------------------------------------
# Logging Implementation
# -----------------------------------------------------------------------------

# Check if a message should be logged
should_log() {
    local level=$1
    local level_value=${LOG_LEVELS[$level]}
    local min_level_value=${LOG_LEVELS[$LOG_LEVEL]}
    
    [ "$level_value" -ge "$min_level_value" ]
}

# Format log message
format_log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    case "$LOG_FORMAT" in
        json)
            # JSON format
            printf '{"timestamp":"%s","level":"%s","message":"%s","pid":%d}\n' \
                "$timestamp" "$level" "$message" "$$"
            ;;
        syslog)
            # Syslog format
            printf '<%d>1 %s %s %s[%d]: %s\n' \
                "${LOG_LEVELS[$level]}" "$timestamp" "$(hostname)" \
                "$(basename "$0")" "$$" "$message"
            ;;
        *)
            # Text format
            if [ "$LOG_OUTPUT" = "console" ] && [ -t 1 ]; then
                # Use colors for console output
                printf "%s[%s] [%s%s%s] %s\n" \
                    "$timestamp" "$$" \
                    "${LOG_COLORS[$level]}" "$level" "${LOG_COLORS[RESET]}" \
                    "$message"
            else
                # Plain text for file output
                printf "%s[%s] [%s] %s\n" \
                    "$timestamp" "$$" "$level" "$message"
            fi
            ;;
    esac
}

# Write log message
write_log() {
    local formatted_message=$1
    
    case "$LOG_OUTPUT" in
        file)
            # Check file size and rotate if necessary
            if [ -f "$LOG_FILE" ]; then
                local size
                size=$(stat -f %z "$LOG_FILE")
                if [ "$size" -gt "$LOG_MAX_SIZE" ]; then
                    rotate_logs
                fi
            fi
            
            # Ensure log directory exists
            mkdir -p "$(dirname "$LOG_FILE")"
            
            # Append to log file
            echo "$formatted_message" >> "$LOG_FILE"
            ;;
        syslog)
            # Send to syslog
            logger -p user.info "$formatted_message"
            ;;
        *)
            # Write to console
            echo "$formatted_message"
            ;;
    esac
}

# Rotate log files
rotate_logs() {
    local i
    
    # Remove oldest log file
    rm -f "${LOG_FILE}.${LOG_BACKUP_COUNT}"
    
    # Rotate existing log files
    for ((i=LOG_BACKUP_COUNT-1; i>=0; i--)); do
        if [ -f "${LOG_FILE}.$i" ]; then
            mv "${LOG_FILE}.$i" "${LOG_FILE}.$((i+1))"
        fi
    done
    
    # Rotate current log file
    if [ -f "$LOG_FILE" ]; then
        mv "$LOG_FILE" "${LOG_FILE}.0"
    fi
}

# -----------------------------------------------------------------------------
# Logging Functions
# -----------------------------------------------------------------------------

# Log at specific level
log() {
    local level=$1
    local message=$2
    
    if should_log "$level"; then
        local formatted_message
        formatted_message=$(format_log_message "$level" "$message")
        write_log "$formatted_message"
    fi
}

# Convenience functions for each log level
debug() { log "DEBUG" "$1"; }
info() { log "INFO" "$1"; }
warn() { log "WARN" "$1"; }
error() { log "ERROR" "$1"; }
fatal() { log "FATAL" "$1"; exit 1; }

# -----------------------------------------------------------------------------
# Advanced Logging Features
# -----------------------------------------------------------------------------

# Start logging session
start_logging_session() {
    local session_id
    session_id=$(uuidgen 2>/dev/null || echo "$RANDOM-$RANDOM")
    export LOG_SESSION_ID=$session_id
    
    info "Starting logging session: $session_id"
}

# End logging session
end_logging_session() {
    if [ -n "${LOG_SESSION_ID:-}" ]; then
        info "Ending logging session: $LOG_SESSION_ID"
        unset LOG_SESSION_ID
    fi
}

# Log with context
log_with_context() {
    local level=$1
    local message=$2
    shift 2
    local context=("$@")
    
    # Add context to message
    local context_str
    context_str=$(printf ",%s" "${context[@]}")
    context_str=${context_str:1}
    
    log "$level" "$message [context: $context_str]"
}

# Log execution time
log_execution_time() {
    local start_time=$1
    local end_time=$2
    local operation=$3
    
    local duration=$((end_time - start_time))
    debug "Operation '$operation' completed in ${duration}s"
}

# -----------------------------------------------------------------------------
# Example Usage
# -----------------------------------------------------------------------------

# Example function with logging
process_file() {
    local file=$1
    local start_time
    start_time=$(date +%s)
    
    debug "Starting file processing: $file"
    
    # Validate file
    if [ ! -f "$file" ]; then
        error "File not found: $file"
        return 1
    fi
    
    # Process file
    local size
    size=$(stat -f %z "$file")
    info "Processing file: $file (size: $size bytes)"
    
    # Simulate processing
    sleep 1
    
    local end_time
    end_time=$(date +%s)
    log_execution_time "$start_time" "$end_time" "process_file"
    
    info "File processing completed: $file"
}

# Example function with context logging
process_user() {
    local username=$1
    local action=$2
    
    log_with_context "INFO" "Processing user" \
        "username=$username" \
        "action=$action" \
        "timestamp=$(date +%s)"
    
    # Simulate processing
    sleep 1
    
    log_with_context "INFO" "User processing completed" \
        "username=$username" \
        "action=$action" \
        "status=success"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    echo "Starting logging demonstration..."
    
    # Start logging session
    start_logging_session
    
    # Example 1: Basic logging
    debug "This is a debug message"
    info "This is an info message"
    warn "This is a warning message"
    error "This is an error message"
    
    # Example 2: File processing with logging
    echo "test content" > /tmp/example.txt
    process_file /tmp/example.txt
    
    # Example 3: Context logging
    process_user "testuser" "create"
    
    # Example 4: Different log formats
    LOG_FORMAT=json info "This is a JSON formatted log message"
    LOG_FORMAT=syslog info "This is a syslog formatted message"
    
    # Example 5: Log file rotation
    if [ "$LOG_OUTPUT" = "file" ]; then
        info "Creating log entries for rotation demonstration"
        for i in {1..1000}; do
            info "Log entry $i"
        done
    fi
    
    # End logging session
    end_logging_session
    
    echo "Logging demonstration completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
