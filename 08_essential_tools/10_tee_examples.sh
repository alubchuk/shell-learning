#!/bin/bash

# Tee Command Examples
# ----------------
# This script demonstrates various uses of the tee command
# for output redirection and logging.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Basic Tee Usage
# --------------

basic_tee() {
    echo "Basic Tee Examples:"
    echo "-----------------"
    
    # Simple output to file
    echo "1. Basic output:"
    echo "Hello, World!" | tee "$LOG_DIR/hello.txt"
    
    # Append to file
    echo -e "\n2. Append output:"
    echo "Line 1" | tee -a "$LOG_DIR/append.txt"
    echo "Line 2" | tee -a "$LOG_DIR/append.txt"
    
    # Multiple files
    echo -e "\n3. Multiple files:"
    echo "Multi-file output" | tee "$LOG_DIR/file1.txt" "$LOG_DIR/file2.txt"
    
    # Show results
    echo -e "\nResults:"
    echo "hello.txt:"
    cat "$LOG_DIR/hello.txt"
    echo -e "\nappend.txt:"
    cat "$LOG_DIR/append.txt"
}

# 2. Command Output Logging
# --------------------

command_logging() {
    echo "Command Logging Examples:"
    echo "----------------------"
    
    # Log command output
    echo "1. Command output logging:"
    ls -l "$SCRIPT_DIR" | tee "$LOG_DIR/ls_output.log"
    
    # Log with timestamp
    echo -e "\n2. Timestamped logging:"
    {
        echo "=== $(date) ==="
        ps aux | head -n 5
    } | tee "$LOG_DIR/ps_output.log"
    
    # Log errors too
    echo -e "\n3. Error logging:"
    {
        echo "=== Command Output ==="
        ls /nonexistent 2>&1
    } | tee "$LOG_DIR/error.log"
}

# 3. Multi-file Processing
# -------------------

process_files() {
    echo "Multi-file Processing:"
    echo "--------------------"
    
    # Create test files
    echo "1. Processing multiple files:"
    for i in {1..3}; do
        echo "File $i content" > "$LOG_DIR/input$i.txt"
    done
    
    # Process and log
    cat "$LOG_DIR"/input*.txt |
        tee "$LOG_DIR/combined.txt" |
        grep "File" |
        tee "$LOG_DIR/filtered.txt"
    
    echo -e "\nResults:"
    echo "Combined output:"
    cat "$LOG_DIR/combined.txt"
    echo -e "\nFiltered output:"
    cat "$LOG_DIR/filtered.txt"
}

# 4. Pipeline Debugging
# -----------------

debug_pipeline() {
    echo "Pipeline Debugging:"
    echo "-----------------"
    
    # Create test data
    seq 1 5 > "$LOG_DIR/numbers.txt"
    
    echo "1. Debug pipeline steps:"
    cat "$LOG_DIR/numbers.txt" |
        tee "$LOG_DIR/step1.log" |
        awk '{print $1 * 2}' |
        tee "$LOG_DIR/step2.log" |
        grep '4' |
        tee "$LOG_DIR/step3.log"
    
    echo -e "\nPipeline steps:"
    for step in {1..3}; do
        echo "Step $step:"
        cat "$LOG_DIR/step$step.log"
    done
}

# 5. Real-time Monitoring
# ------------------

monitor_output() {
    echo "Real-time Monitoring:"
    echo "-------------------"
    
    # Monitor command output
    echo "1. Monitoring output (5 seconds):"
    {
        for i in {1..5}; do
            echo "Tick $i: $(date)"
            sleep 1
        done
    } | tee "$LOG_DIR/monitor.log"
    
    echo -e "\nMonitoring log:"
    cat "$LOG_DIR/monitor.log"
}

# 6. Log Rotation
# -----------

rotate_logs() {
    local base_log="$1"
    local max_logs="$2"
    
    echo "Log Rotation:"
    echo "------------"
    
    # Rotate existing logs
    for i in $(seq $((max_logs - 1)) -1 1); do
        if [ -f "${base_log}.$i" ]; then
            mv "${base_log}.$i" "${base_log}.$((i + 1))"
        fi
    done
    
    if [ -f "$base_log" ]; then
        mv "$base_log" "${base_log}.1"
    fi
    
    # Create new log
    echo "Creating new log..."
    echo "Log created at $(date)" | tee "$base_log"
}

# 7. Practical Examples
# ----------------

# System information logger
log_system_info() {
    local output_file="$1"
    
    echo "Logging System Information:"
    echo "-------------------------"
    
    {
        echo "=== System Information Report ==="
        echo "Date: $(date)"
        echo -e "\n=== CPU Info ==="
        top -l 1 | head -n 10
        echo -e "\n=== Memory Info ==="
        vm_stat
        echo -e "\n=== Disk Usage ==="
        df -h
    } | tee "$output_file"
}

# Multi-level logging
multi_level_log() {
    local command="$1"
    local log_dir="$2"
    
    echo "Multi-level Logging:"
    echo "------------------"
    
    # Create log files
    {
        echo "=== $(date) ==="
        eval "$command"
    } 2> >(tee "$log_dir/error.log" >&2) \
      1> >(tee "$log_dir/output.log")
}

# Command output splitter
split_output() {
    local command="$1"
    local output_pattern="$2"
    local match_log="$3"
    local nomatch_log="$4"
    
    echo "Splitting Command Output:"
    echo "----------------------"
    
    eval "$command" |
        tee >(grep "$output_pattern" > "$match_log") \
            >(grep -v "$output_pattern" > "$nomatch_log") \
            >/dev/null
    
    echo "Matching lines saved to: $match_log"
    echo "Non-matching lines saved to: $nomatch_log"
}

# Main execution
main() {
    # Run examples
    basic_tee
    echo -e "\n"
    command_logging
    echo -e "\n"
    process_files
    echo -e "\n"
    debug_pipeline
    echo -e "\n"
    monitor_output
    echo -e "\n"
    
    # Rotate logs
    rotate_logs "$LOG_DIR/rotating.log" 3
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # System information logging
    log_system_info "$LOG_DIR/sysinfo.log"
    
    # Multi-level logging
    multi_level_log "ls /nonexistent" "$LOG_DIR"
    
    # Split command output
    split_output "ls -l $SCRIPT_DIR" "\.sh$" \
        "$LOG_DIR/scripts.log" \
        "$LOG_DIR/non_scripts.log"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
