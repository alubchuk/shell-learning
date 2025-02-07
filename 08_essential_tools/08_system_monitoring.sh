#!/bin/bash

# System Monitoring Commands
# ----------------------
# This script demonstrates the usage of top, ps,
# timeout, and date commands for system monitoring.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly MONITOR_DIR="$OUTPUT_DIR/monitoring"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$MONITOR_DIR"

# 1. Date Examples
# ------------

date_examples() {
    echo "Date Examples:"
    echo "-------------"
    
    # Current date and time
    echo "1. Current date and time:"
    date
    
    # Custom format
    echo -e "\n2. Custom format:"
    date "+%Y-%m-%d %H:%M:%S"
    
    # UTC time
    echo -e "\n3. UTC time:"
    date -u
    
    # Specific timezone
    echo -e "\n4. New York time:"
    TZ='America/New_York' date
    
    # Date calculations
    echo -e "\n5. Date calculations:"
    echo "Yesterday: $(date -v-1d '+%Y-%m-%d')"
    echo "Tomorrow: $(date -v+1d '+%Y-%m-%d')"
}

# 2. Top Examples
# -----------

top_examples() {
    echo "Top Examples:"
    echo "------------"
    
    # Snapshot of processes
    echo "1. Process snapshot:"
    top -l 1 -n 5 -o CPU
    
    # CPU intensive processes
    echo -e "\n2. CPU intensive processes:"
    top -l 1 -o CPU -n 5 -stats pid,command,cpu,mem
    
    # Memory intensive processes
    echo -e "\n3. Memory intensive processes:"
    top -l 1 -o MEM -n 5 -stats pid,command,mem,cpu
}

# 3. Timeout Examples
# --------------

timeout_examples() {
    echo "Timeout Examples:"
    echo "----------------"
    
    # Basic timeout
    echo "1. Basic timeout (2 seconds):"
    timeout 2 tail -f /dev/null || echo "Command timed out"
    
    # Timeout with signal
    echo -e "\n2. Timeout with SIGTERM:"
    timeout -s TERM 2 sleep 5 || echo "Command terminated"
    
    # Preserve status
    echo -e "\n3. Preserve status:"
    if ! timeout 1 sleep 2; then
        echo "Command timed out with status $?"
    fi
}

# 4. Process Monitoring
# -----------------

monitor_process() {
    local process_name="$1"
    local duration="$2"
    local output_file="$3"
    
    echo "Monitoring $process_name for $duration seconds..."
    
    timeout "$duration" bash -c "
        while true; do
            ps aux | grep -i '$process_name' | grep -v grep
            sleep 1
        done
    " > "$output_file"
    
    echo "Monitoring complete. Results saved to $output_file"
}

# 5. System Stats Collection
# ---------------------

collect_system_stats() {
    local duration="$1"
    local interval="$2"
    local output_dir="$3"
    
    echo "Collecting system stats for $duration seconds..."
    
    # CPU stats
    timeout "$duration" bash -c "
        while true; do
            top -l 1 -n 0 -S | grep -E 'CPU usage|PhysMem'
            sleep $interval
        done
    " > "$output_dir/cpu_stats.log" &
    
    # Memory stats
    timeout "$duration" bash -c "
        while true; do
            vm_stat 1 1
            sleep $interval
        done
    " > "$output_dir/memory_stats.log" &
    
    # Disk stats
    timeout "$duration" bash -c "
        while true; do
            df -h
            sleep $interval
        done
    " > "$output_dir/disk_stats.log" &
    
    # Wait for collection to complete
    sleep "$duration"
    wait
    
    echo "Stats collection complete. Check $output_dir for results."
}

# 6. Performance Monitoring
# --------------------

monitor_performance() {
    local duration="$1"
    local output_dir="$2"
    
    echo "Monitoring system performance for $duration seconds..."
    
    # Create monitoring script
    cat > "$output_dir/monitor.sh" << 'EOF'
#!/bin/bash

while true; do
    date '+%Y-%m-%d %H:%M:%S'
    echo "CPU Usage:"
    top -l 1 -n 0 -S | grep "CPU usage"
    echo "Memory Usage:"
    vm_stat 1 1 | head -n 2
    echo "Disk Usage:"
    df -h | grep "/dev/"
    echo "-------------------"
    sleep 1
done
EOF
    
    chmod +x "$output_dir/monitor.sh"
    
    # Run monitoring
    timeout "$duration" "$output_dir/monitor.sh" > "$output_dir/performance.log"
    
    echo "Performance monitoring complete. Results in $output_dir/performance.log"
}

# 7. Process Management
# -----------------

manage_process() {
    local command="$1"
    local max_runtime="$2"
    local output_file="$3"
    
    echo "Managing process: $command"
    
    # Start process with timeout
    timeout "$max_runtime" bash -c "
        # Start the process
        $command &
        pid=\$!
        
        # Monitor the process
        while kill -0 \$pid 2>/dev/null; do
            echo \"\$(date): Process \$pid running\"
            ps -p \$pid -o pid,ppid,cmd,%cpu,%mem
            sleep 1
        done
    " > "$output_file"
    
    echo "Process management complete. Check $output_file for details."
}

# 8. Practical Examples
# ----------------

# Resource usage monitor
monitor_resources() {
    local duration="$1"
    local output_dir="$2"
    
    echo "Starting resource monitoring for $duration seconds..."
    
    # Monitor CPU
    (
        echo "Timestamp,CPU User,CPU System,CPU Idle"
        while true; do
            top -l 1 -n 0 -S | grep "CPU usage" |
                awk -F'[,%]' '{printf "%s,%.1f,%.1f,%.1f\n",
                    strftime("%Y-%m-%d %H:%M:%S"),
                    $1, $4, $7}'
            sleep 1
        done
    ) > "$output_dir/cpu_usage.csv" &
    CPU_PID=$!
    
    # Monitor memory
    (
        echo "Timestamp,Free Memory,Active Memory,Inactive Memory"
        while true; do
            vm_stat 1 1 | tail -n 1 |
                awk '{printf "%s,%d,%d,%d\n",
                    strftime("%Y-%m-%d %H:%M:%S"),
                    $1*4096/1024/1024,
                    $3*4096/1024/1024,
                    $5*4096/1024/1024}'
            sleep 1
        done
    ) > "$output_dir/memory_usage.csv" &
    MEM_PID=$!
    
    # Wait for duration
    sleep "$duration"
    
    # Cleanup
    kill $CPU_PID $MEM_PID
    wait
    
    echo "Resource monitoring complete. Check CSV files in $output_dir"
}

# Main execution
main() {
    # Run examples
    date_examples
    echo -e "\n"
    top_examples
    echo -e "\n"
    timeout_examples
    echo -e "\n"
    
    # Monitor specific process
    monitor_process "Terminal" 5 "$MONITOR_DIR/terminal_monitor.log"
    echo -e "\n"
    
    # Collect system stats
    collect_system_stats 10 2 "$MONITOR_DIR"
    echo -e "\n"
    
    # Monitor performance
    monitor_performance 10 "$MONITOR_DIR"
    echo -e "\n"
    
    # Manage test process
    manage_process "sleep 5" 10 "$MONITOR_DIR/process_management.log"
    echo -e "\n"
    
    # Monitor resources
    monitor_resources 10 "$MONITOR_DIR"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
