#!/bin/bash

# =============================================================================
# Shell Script Monitoring Examples
# This script demonstrates monitoring and alerting techniques for shell scripts,
# including system metrics, custom metrics, and alert notifications.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Monitoring settings
readonly MONITOR_INTERVAL=${MONITOR_INTERVAL:-60}  # seconds
readonly METRICS_DIR=${METRICS_DIR:-/tmp/metrics}
readonly ALERT_HISTORY=${ALERT_HISTORY:-/tmp/alerts.json}

# Alert thresholds
readonly CPU_THRESHOLD=${CPU_THRESHOLD:-80}        # percentage
readonly MEMORY_THRESHOLD=${MEMORY_THRESHOLD:-80}  # percentage
readonly DISK_THRESHOLD=${DISK_THRESHOLD:-90}      # percentage
readonly LOAD_THRESHOLD=${LOAD_THRESHOLD:-5}       # load average

# Alert notification settings
readonly SLACK_WEBHOOK=${SLACK_WEBHOOK:-}
readonly EMAIL_TO=${EMAIL_TO:-}
readonly SMS_TO=${SMS_TO:-}

# -----------------------------------------------------------------------------
# Metric Collection
# -----------------------------------------------------------------------------

# Initialize metrics directory
init_metrics() {
    mkdir -p "$METRICS_DIR"
    
    # Initialize metric files
    echo "0" > "${METRICS_DIR}/cpu_usage"
    echo "0" > "${METRICS_DIR}/memory_usage"
    echo "0" > "${METRICS_DIR}/disk_usage"
    echo "0" > "${METRICS_DIR}/load_average"
    echo "0" > "${METRICS_DIR}/error_count"
    echo "0" > "${METRICS_DIR}/request_count"
}

# Collect system metrics
collect_system_metrics() {
    # CPU usage
    local cpu_usage
    cpu_usage=$(top -l 1 | grep "CPU usage" | awk '{print $3}' | tr -d '%')
    echo "$cpu_usage" > "${METRICS_DIR}/cpu_usage"
    
    # Memory usage
    local memory_usage
    memory_usage=$(vm_stat | awk '/Pages active/ {print $3}' | tr -d '.')
    memory_usage=$((memory_usage * 4096 / 1024 / 1024))  # Convert to MB
    echo "$memory_usage" > "${METRICS_DIR}/memory_usage"
    
    # Disk usage
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    echo "$disk_usage" > "${METRICS_DIR}/disk_usage"
    
    # Load average
    local load_average
    load_average=$(sysctl -n vm.loadavg | awk '{print $2}')
    echo "$load_average" > "${METRICS_DIR}/load_average"
}

# Collect custom metrics
collect_custom_metrics() {
    # Example: Count error logs
    local error_count
    error_count=$(grep -c "ERROR" /var/log/system.log 2>/dev/null || echo "0")
    echo "$error_count" > "${METRICS_DIR}/error_count"
    
    # Example: Count HTTP requests
    local request_count
    request_count=$(grep -c "GET" /var/log/apache2/access.log 2>/dev/null || echo "0")
    echo "$request_count" > "${METRICS_DIR}/request_count"
}

# -----------------------------------------------------------------------------
# Alert Processing
# -----------------------------------------------------------------------------

# Initialize alert history
init_alert_history() {
    if [ ! -f "$ALERT_HISTORY" ]; then
        echo '{"alerts":[]}' > "$ALERT_HISTORY"
    fi
}

# Add alert to history
add_alert() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    
    # Create alert JSON
    local alert
    alert=$(jq -n \
        --arg timestamp "$timestamp" \
        --arg level "$level" \
        --arg message "$message" \
        '{timestamp: $timestamp, level: $level, message: $message}')
    
    # Add to history
    jq --arg alert "$alert" '.alerts += [$alert|fromjson]' "$ALERT_HISTORY" > "${ALERT_HISTORY}.tmp"
    mv "${ALERT_HISTORY}.tmp" "$ALERT_HISTORY"
    
    # Trim history (keep last 1000 alerts)
    jq '.alerts|=.[-1000:]' "$ALERT_HISTORY" > "${ALERT_HISTORY}.tmp"
    mv "${ALERT_HISTORY}.tmp" "$ALERT_HISTORY"
}

# Check metrics and generate alerts
check_alerts() {
    local alerts=()
    
    # Check CPU usage
    local cpu_usage
    cpu_usage=$(<"${METRICS_DIR}/cpu_usage")
    if [ "${cpu_usage%.*}" -gt "$CPU_THRESHOLD" ]; then
        alerts+=("CRITICAL: CPU usage at ${cpu_usage}%")
    fi
    
    # Check memory usage
    local memory_usage
    memory_usage=$(<"${METRICS_DIR}/memory_usage")
    if [ "${memory_usage%.*}" -gt "$MEMORY_THRESHOLD" ]; then
        alerts+=("CRITICAL: Memory usage at ${memory_usage}%")
    fi
    
    # Check disk usage
    local disk_usage
    disk_usage=$(<"${METRICS_DIR}/disk_usage")
    if [ "${disk_usage%.*}" -gt "$DISK_THRESHOLD" ]; then
        alerts+=("CRITICAL: Disk usage at ${disk_usage}%")
    fi
    
    # Check load average
    local load_average
    load_average=$(<"${METRICS_DIR}/load_average")
    if [ "${load_average%.*}" -gt "$LOAD_THRESHOLD" ]; then
        alerts+=("WARNING: High load average: ${load_average}")
    fi
    
    # Process alerts
    for alert in "${alerts[@]}"; do
        add_alert "CRITICAL" "$alert"
        send_alert "$alert"
    done
}

# -----------------------------------------------------------------------------
# Alert Notifications
# -----------------------------------------------------------------------------

# Send alert via Slack
send_slack_alert() {
    local message=$1
    
    if [ -n "$SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$SLACK_WEBHOOK"
    fi
}

# Send alert via email
send_email_alert() {
    local message=$1
    
    if [ -n "$EMAIL_TO" ]; then
        echo "$message" | mail -s "System Alert" "$EMAIL_TO"
    fi
}

# Send alert via SMS
send_sms_alert() {
    local message=$1
    
    if [ -n "$SMS_TO" ]; then
        # Example using Twilio API
        if [ -n "${TWILIO_ACCOUNT_SID:-}" ] && [ -n "${TWILIO_AUTH_TOKEN:-}" ]; then
            curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
                --data-urlencode "To=$SMS_TO" \
                --data-urlencode "From=${TWILIO_FROM:-}" \
                --data-urlencode "Body=$message" \
                -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN"
        fi
    fi
}

# Send alert through all configured channels
send_alert() {
    local message=$1
    
    send_slack_alert "$message"
    send_email_alert "$message"
    send_sms_alert "$message"
}

# -----------------------------------------------------------------------------
# Metric Visualization
# -----------------------------------------------------------------------------

# Generate ASCII chart
generate_ascii_chart() {
    local metric=$1
    local width=${2:-50}
    local height=${3:-10}
    
    # Read last 50 values
    local values=()
    while IFS= read -r line; do
        values+=("$line")
    done < <(tail -n "$width" "${METRICS_DIR}/${metric}_history" 2>/dev/null)
    
    # Find min/max
    local min=999999
    local max=0
    for value in "${values[@]}"; do
        if [ "${value%.*}" -lt "$min" ]; then min=${value%.*}; fi
        if [ "${value%.*}" -gt "$max" ]; then max=${value%.*}; fi
    done
    
    # Generate chart
    echo "Chart for $metric (min: $min, max: $max)"
    echo "----------------------------------------"
    
    for ((i=height-1; i>=0; i--)); do
        local line=""
        local threshold=$((min + (max - min) * i / (height - 1)))
        
        for value in "${values[@]}"; do
            if [ "${value%.*}" -ge "$threshold" ]; then
                line+="#"
            else
                line+=" "
            fi
        done
        
        printf "%4d |%s|\n" "$threshold" "$line"
    done
    
    echo "----------------------------------------"
}

# -----------------------------------------------------------------------------
# Monitoring Loop
# -----------------------------------------------------------------------------

# Start monitoring
start_monitoring() {
    echo "Starting system monitoring..."
    
    # Initialize
    init_metrics
    init_alert_history
    
    # Monitoring loop
    while true; do
        # Collect metrics
        collect_system_metrics
        collect_custom_metrics
        
        # Check for alerts
        check_alerts
        
        # Generate visualizations
        clear
        generate_ascii_chart "cpu_usage"
        generate_ascii_chart "memory_usage"
        
        # Wait for next interval
        sleep "$MONITOR_INTERVAL"
    done
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    echo "Starting monitoring demonstration..."
    
    # Start monitoring in background
    start_monitoring &
    monitor_pid=$!
    
    # Wait for user interrupt
    trap 'kill $monitor_pid 2>/dev/null' INT TERM
    wait $monitor_pid
    
    echo "Monitoring demonstration completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
