#!/bin/bash

# Process Substitution Examples
# -------------------------
# This script demonstrates various process substitution
# patterns and techniques.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_DIR="$OUTPUT_DIR/test_files"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$TEST_DIR"

# Create test files
create_test_files() {
    # File 1
    cat > "$TEST_DIR/file1.txt" << 'EOF'
apple
banana
cherry
date
elderberry
EOF

    # File 2
    cat > "$TEST_DIR/file2.txt" << 'EOF'
apple
blueberry
cherry
dragonfruit
elderberry
EOF

    # Log file 1
    cat > "$TEST_DIR/app1.log" << 'EOF'
2025-02-07 10:00:00 INFO  Server started
2025-02-07 10:00:01 ERROR Database connection failed
2025-02-07 10:00:02 WARN  Retrying connection
2025-02-07 10:00:03 INFO  Connection established
EOF

    # Log file 2
    cat > "$TEST_DIR/app2.log" << 'EOF'
2025-02-07 10:00:00 INFO  Backup started
2025-02-07 10:00:01 ERROR Disk space low
2025-02-07 10:00:02 WARN  Cleanup required
2025-02-07 10:00:03 INFO  Backup completed
EOF

    # Data file
    cat > "$TEST_DIR/data.csv" << 'EOF'
id,name,value
1,John,100
2,Jane,200
3,Bob,150
4,Alice,175
5,Charlie,225
EOF
}

# 1. Basic Process Substitution
# ------------------------

basic_substitution() {
    echo "Basic Process Substitution:"
    echo "-------------------------"
    
    # Compare files
    echo "1. File comparison:"
    diff <(sort "$TEST_DIR/file1.txt") <(sort "$TEST_DIR/file2.txt")
    
    # Multiple command output
    echo -e "\n2. Multiple commands:"
    cat <(echo "Header") "$TEST_DIR/file1.txt" <(echo "Footer")
    
    # Process and compare
    echo -e "\n3. Process and compare:"
    comm <(sort "$TEST_DIR/file1.txt") <(sort "$TEST_DIR/file2.txt")
}

# 2. Data Processing
# --------------

data_processing() {
    echo "Data Processing:"
    echo "---------------"
    
    # Extract and process columns
    echo "1. Column processing:"
    paste <(cut -d',' -f2 "$TEST_DIR/data.csv") \
          <(cut -d',' -f3 "$TEST_DIR/data.csv") |
        tail -n +2
    
    # Multiple transformations
    echo -e "\n2. Data transformations:"
    paste <(cut -d',' -f2 "$TEST_DIR/data.csv" | tr '[:lower:]' '[:upper:]') \
          <(cut -d',' -f3 "$TEST_DIR/data.csv" | sort -n) |
        tail -n +2
    
    # Aggregate data
    echo -e "\n3. Data aggregation:"
    echo "Total value: $(cut -d',' -f3 "$TEST_DIR/data.csv" | tail -n +2 | paste -sd+ | bc)"
    echo "Average value: $(cut -d',' -f3 "$TEST_DIR/data.csv" | tail -n +2 | paste -sd+ | bc | awk '{print $1/5}')"
}

# 3. Log Analysis
# -----------

log_analysis() {
    echo "Log Analysis:"
    echo "------------"
    
    # Compare log files
    echo "1. Log comparison:"
    diff <(grep ERROR "$TEST_DIR/app1.log") \
         <(grep ERROR "$TEST_DIR/app2.log")
    
    # Merge and sort logs
    echo -e "\n2. Merged logs:"
    sort -m <(cut -d' ' -f1,2 "$TEST_DIR/app1.log") \
           <(cut -d' ' -f1,2 "$TEST_DIR/app2.log")
    
    # Process multiple logs
    echo -e "\n3. Error summary:"
    grep -h ERROR <(cat "$TEST_DIR/app1.log") \
                 <(cat "$TEST_DIR/app2.log")
}

# 4. Advanced Patterns
# ---------------

advanced_patterns() {
    echo "Advanced Patterns:"
    echo "----------------"
    
    # Multiple process substitution
    echo "1. Multiple substitution:"
    diff <(sort "$TEST_DIR/file1.txt" | uniq) \
         <(sort "$TEST_DIR/file2.txt" | uniq) \
         <(echo -e "apple\ncherry\nelderberry")
    
    # Nested substitution
    echo -e "\n2. Nested substitution:"
    while read -r line; do
        echo "$line"
    done < <(paste <(cut -d',' -f2 "$TEST_DIR/data.csv") \
                   <(cut -d',' -f3 "$TEST_DIR/data.csv"))
    
    # Dynamic command generation
    echo -e "\n3. Dynamic commands:"
    eval "$(cat <(echo 'echo "Dynamic execution"') <(echo 'date'))"
}

# 5. Real-time Processing
# -------------------

real_time_processing() {
    echo "Real-time Processing:"
    echo "-------------------"
    
    # Simulate real-time data
    echo "1. Real-time monitoring (runs for 5 seconds):"
    timeout 5 bash -c '
        while true; do
            echo "$(date +%H:%M:%S) Data: $RANDOM"
            sleep 1
        done
    ' | tee >(grep --line-buffered "Data" > "$TEST_DIR/data.log") \
          >(awk "{sum += \$3} END {print \"Average: \" sum/NR}" > "$TEST_DIR/stats.log")
    
    echo -e "\n2. Processing results:"
    echo "Data log:"
    cat "$TEST_DIR/data.log"
    echo -e "\nStats:"
    cat "$TEST_DIR/stats.log"
}

# 6. Configuration Management
# ----------------------

config_management() {
    echo "Configuration Management:"
    echo "----------------------"
    
    # Generate config
    generate_config() {
        cat << EOF
database:
  host: localhost
  port: 5432
server:
  host: 0.0.0.0
  port: 8080
EOF
    }
    
    # Process config
    echo "1. Configuration processing:"
    while IFS= read -r line; do
        if [[ $line == *":"* ]]; then
            echo "Found config: $line"
        fi
    done < <(generate_config)
    
    # Merge configs
    echo -e "\n2. Merged configuration:"
    cat <(generate_config) \
        <(echo "logging:
  level: INFO
  file: app.log")
}

# 7. Performance Monitoring
# --------------------

performance_monitoring() {
    echo "Performance Monitoring:"
    echo "--------------------"
    
    # Monitor system stats
    echo "1. System monitoring (5 seconds):"
    {
        # CPU usage
        top -l 2 | grep "CPU usage" &
        # Memory usage
        vm_stat 1 5 &
        # Disk usage
        df -h &
    } > >(grep --line-buffered . > "$TEST_DIR/system.log")
    
    sleep 5
    
    echo -e "\n2. Monitoring results:"
    cat "$TEST_DIR/system.log"
}

# 8. Practical Examples
# ----------------

# File synchronization
sync_files() {
    local src="$1"
    local dst="$2"
    
    echo "Synchronizing files:"
    echo "-------------------"
    
    # Compare and sync
    comm -23 <(ls "$src" | sort) <(ls "$dst" | sort) |
        while read -r file; do
            echo "Copying: $file"
            cp "$src/$file" "$dst/"
        done
}

# Log monitoring
monitor_logs() {
    local log_dir="$1"
    local pattern="$2"
    
    echo "Monitoring logs for pattern: $pattern"
    echo "-----------------------------------"
    
    # Monitor multiple log files
    tail -f <(find "$log_dir" -name "*.log" -exec tail -f {} \;) |
        grep --line-buffered "$pattern"
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    basic_substitution
    echo -e "\n"
    data_processing
    echo -e "\n"
    log_analysis
    echo -e "\n"
    advanced_patterns
    echo -e "\n"
    real_time_processing
    echo -e "\n"
    config_management
    echo -e "\n"
    performance_monitoring
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    sync_files "$TEST_DIR" "$OUTPUT_DIR"
    echo -e "\n"
    monitor_logs "$TEST_DIR" "ERROR" &
    MONITOR_PID=$!
    sleep 5
    kill $MONITOR_PID
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
