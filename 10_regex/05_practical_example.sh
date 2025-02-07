#!/bin/bash

# Log Analysis and Text Processing Framework
# --------------------------------------
# A practical example combining grep, sed, and awk
# for comprehensive log analysis and text processing.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"
readonly REPORT_DIR="$OUTPUT_DIR/reports"
readonly CONFIG_FILE="$OUTPUT_DIR/config.ini"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$REPORT_DIR"

# Create sample log files
create_sample_logs() {
    # Application log
    cat > "$LOG_DIR/app.log" << 'EOF'
2025-02-07 10:00:00 INFO  [main] Server started on port 8080
2025-02-07 10:00:01 DEBUG [db] Connecting to database at localhost:5432
2025-02-07 10:00:02 ERROR [db] Failed to connect: Connection refused
2025-02-07 10:00:03 WARN  [main] Database connection retry 1/3
2025-02-07 10:00:04 ERROR [db] Connection timeout
2025-02-07 10:00:05 INFO  [auth] User john.doe logged in
2025-02-07 10:00:06 DEBUG [api] Processing request GET /api/v1/users
2025-02-07 10:00:07 ERROR [api] Invalid request parameter: id=abc
2025-02-07 10:00:08 INFO  [auth] User jane.smith logged in
2025-02-07 10:00:09 DEBUG [cache] Cache miss for key: user_123
2025-02-07 10:00:10 INFO  [api] Request completed in 150ms
EOF

    # Access log
    cat > "$LOG_DIR/access.log" << 'EOF'
192.168.1.100 - - [07/Feb/2025:10:00:00 +0100] "GET /index.html HTTP/1.1" 200 2048
192.168.1.101 - - [07/Feb/2025:10:00:01 +0100] "POST /api/login HTTP/1.1" 401 1024
192.168.1.102 - - [07/Feb/2025:10:00:02 +0100] "GET /images/logo.png HTTP/1.1" 200 5120
192.168.1.100 - - [07/Feb/2025:10:00:03 +0100] "GET /css/style.css HTTP/1.1" 200 1536
192.168.1.103 - - [07/Feb/2025:10:00:04 +0100] "GET /api/data HTTP/1.1" 500 512
192.168.1.101 - - [07/Feb/2025:10:00:05 +0100] "GET /index.html HTTP/1.1" 200 2048
192.168.1.102 - - [07/Feb/2025:10:00:06 +0100] "POST /api/upload HTTP/1.1" 413 0
192.168.1.100 - - [07/Feb/2025:10:00:07 +0100] "GET /js/main.js HTTP/1.1" 200 4096
EOF

    # Error log
    cat > "$LOG_DIR/error.log" << 'EOF'
[2025-02-07 10:00:02] Database connection failed: Connection refused
[2025-02-07 10:00:04] Database connection timeout after 30s
[2025-02-07 10:00:07] Invalid parameter in API request: id=abc (expected number)
[2025-02-07 10:00:06] File upload failed: File size exceeds limit (10MB)
EOF
}

# 1. Log Analysis Functions
# ---------------------

# Extract and format error messages
analyze_errors() {
    local log_file="$1"
    local output_file="$REPORT_DIR/errors.txt"
    
    echo "Analyzing errors in $log_file..."
    
    # Use grep to find errors, sed to format, and awk to add statistics
    grep -i "error" "$log_file" |
        sed -E 's/^([0-9-]+) ([0-9:]+) ERROR \[(.*?)\] (.*)$/[\1 \2] [\3] ERROR: \4/' |
        awk '
            {
                errors[$3]++
                print
            }
            END {
                print "\nError Summary:"
                for (component in errors)
                    printf "%-20s: %d errors\n", component, errors[component]
            }
        ' > "$output_file"
    
    echo "Error analysis saved to $output_file"
}

# Analyze HTTP status codes
analyze_http_status() {
    local log_file="$1"
    local output_file="$REPORT_DIR/http_status.txt"
    
    echo "Analyzing HTTP status codes in $log_file..."
    
    awk '
        match($0, /"[^"]*"/) {
            request = substr($0, RSTART, RLENGTH)
        }
        {
            status[$9]++
            requests[request,status]++
            total++
        }
        END {
            print "HTTP Status Code Distribution:"
            print "-----------------------------"
            for (code in status) {
                printf "HTTP %s: %d (%.1f%%)\n", 
                    code, status[code], (status[code]/total)*100
            }
            
            print "\nRequests by Status Code:"
            print "----------------------"
            for (req_status in requests) {
                split(req_status, parts, SUBSEP)
                if (requests[req_status] > 0)
                    printf "%s - %s: %d\n", 
                        parts[2], parts[1], requests[req_status]
            }
        }
    ' "$log_file" > "$output_file"
    
    echo "HTTP status analysis saved to $output_file"
}

# 2. Text Processing Functions
# -----------------------

# Clean and normalize log format
normalize_logs() {
    local input_file="$1"
    local output_file="$2"
    
    echo "Normalizing log format of $input_file..."
    
    # Use sed to normalize timestamps and awk to standardize format
    sed -E 's/\[([0-9-]+) /\1 /g' "$input_file" |
        sed -E 's/\[([0-9:]+)\]/\1/g' |
        awk '
            {
                # Extract timestamp and level
                timestamp = $1 " " $2
                if ($3 ~ /^[A-Z]+$/) {
                    level = $3
                    component = $4
                    message = substr($0, index($0, $5))
                } else {
                    level = "INFO"
                    component = $3
                    message = substr($0, index($0, $4))
                }
                
                # Print in standard format
                printf "[%s] %-5s [%-10s] %s\n",
                    timestamp, level, component, message
            }
        ' > "$output_file"
    
    echo "Normalized log saved to $output_file"
}

# Extract metrics and statistics
extract_metrics() {
    local log_file="$1"
    local output_file="$REPORT_DIR/metrics.txt"
    
    echo "Extracting metrics from $log_file..."
    
    awk '
        # Parse and collect metrics
        /response time|latency|duration/ {
            match($0, /[0-9]+[ms|s]/)
            timing = substr($0, RSTART, RLENGTH)
            response_times[timing]++
        }
        /memory|heap|ram/i {
            match($0, /[0-9]+[MG]B/)
            memory = substr($0, RSTART, RLENGTH)
            memory_usage[memory]++
        }
        
        # Generate report
        END {
            print "Performance Metrics"
            print "------------------"
            
            print "\nResponse Times:"
            for (time in response_times)
                printf "%-10s: %d occurrences\n", time, response_times[time]
            
            print "\nMemory Usage:"
            for (mem in memory_usage)
                printf "%-10s: %d occurrences\n", mem, memory_usage[mem]
        }
    ' "$log_file" > "$output_file"
    
    echo "Metrics saved to $output_file"
}

# 3. Pattern Matching Functions
# ------------------------

# Search for specific patterns
search_patterns() {
    local log_file="$1"
    local pattern="$2"
    local context="${3:-0}"
    local output_file="$REPORT_DIR/pattern_matches.txt"
    
    echo "Searching for pattern '$pattern' in $log_file..."
    
    # Use grep with context and highlight matches
    grep --color=always -A "$context" -B "$context" -E "$pattern" "$log_file" |
        sed 's/^/  /' > "$output_file"
    
    echo "Pattern matches saved to $output_file"
}

# Extract structured data
extract_structured_data() {
    local log_file="$1"
    local output_file="$REPORT_DIR/structured_data.txt"
    
    echo "Extracting structured data from $log_file..."
    
    awk '
        # Extract key-value pairs
        match($0, /[a-zA-Z_][a-zA-Z0-9_]*=[^ ]+/) {
            pair = substr($0, RSTART, RLENGTH)
            split(pair, kv, "=")
            data[kv[1]][kv[2]]++
        }
        
        # Generate report
        END {
            print "Structured Data Analysis"
            print "----------------------"
            
            for (key in data) {
                printf "\n%s:\n", key
                for (value in data[key])
                    printf "  %-20s: %d occurrences\n", 
                        value, data[key][value]
            }
        }
    ' "$log_file" > "$output_file"
    
    echo "Structured data saved to $output_file"
}

# 4. Report Generation
# ----------------

# Generate comprehensive report
generate_report() {
    local report_file="$REPORT_DIR/full_report.txt"
    
    echo "Generating comprehensive report..."
    
    {
        echo "Log Analysis Report"
        echo "=================="
        echo "Generated: $(date)"
        echo
        
        echo "1. Error Analysis"
        echo "---------------"
        cat "$REPORT_DIR/errors.txt"
        echo
        
        echo "2. HTTP Status Analysis"
        echo "---------------------"
        cat "$REPORT_DIR/http_status.txt"
        echo
        
        echo "3. Performance Metrics"
        echo "-------------------"
        cat "$REPORT_DIR/metrics.txt"
        echo
        
        echo "4. Structured Data"
        echo "----------------"
        cat "$REPORT_DIR/structured_data.txt"
        
    } > "$report_file"
    
    echo "Full report generated at $report_file"
}

# 5. Command Line Interface
# ---------------------

show_help() {
    cat << EOF
Log Analysis and Text Processing Framework

Usage: $0 <command> [options]

Commands:
    errors      Analyze error messages
    http        Analyze HTTP status codes
    normalize   Normalize log format
    metrics     Extract performance metrics
    search      Search for specific patterns
    data        Extract structured data
    report      Generate comprehensive report
    help        Show this help message

Options:
    -f, --file FILE    Input file
    -p, --pattern PAT  Search pattern
    -c, --context NUM  Lines of context
    -h, --help        Show this help message
EOF
}

# Main execution
main() {
    # Create sample logs if they don't exist
    if [ ! -f "$LOG_DIR/app.log" ]; then
        create_sample_logs
    fi
    
    # Process command
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        errors)
            analyze_errors "$LOG_DIR/app.log"
            ;;
        http)
            analyze_http_status "$LOG_DIR/access.log"
            ;;
        normalize)
            normalize_logs "$LOG_DIR/app.log" "$OUTPUT_DIR/normalized.log"
            ;;
        metrics)
            extract_metrics "$LOG_DIR/app.log"
            ;;
        search)
            search_patterns "$LOG_DIR/app.log" "ERROR|WARN" 2
            ;;
        data)
            extract_structured_data "$LOG_DIR/app.log"
            ;;
        report)
            analyze_errors "$LOG_DIR/app.log"
            analyze_http_status "$LOG_DIR/access.log"
            extract_metrics "$LOG_DIR/app.log"
            extract_structured_data "$LOG_DIR/app.log"
            generate_report
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "Unknown command: $command"
            show_help
            exit 1
            ;;
    esac
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
