#!/bin/bash

# Web Automation Framework
# ---------------------
# A practical example combining curl and wget for
# web automation, testing, and monitoring.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"
readonly CONFIG_FILE="$OUTPUT_DIR/config.json"
readonly COOKIE_JAR="$OUTPUT_DIR/cookies.txt"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. API Testing Framework
# --------------------

# Test API endpoint
test_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local auth="${4:-}"
    local log_file="$LOG_DIR/api_test_$(date +%Y%m%d).log"
    
    echo "Testing $method $endpoint"
    
    # Prepare curl command
    local curl_cmd="curl -s -X $method"
    
    # Add authentication if provided
    if [ -n "$auth" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $auth'"
    fi
    
    # Add data if provided
    if [ -n "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    # Add output formatting
    curl_cmd="$curl_cmd -w '\nStatus: %{http_code}\nTime: %{time_total}s\n'"
    
    # Execute and log
    {
        echo "=== $(date) ==="
        echo "Request: $method $endpoint"
        echo "Data: $data"
        eval "$curl_cmd '$endpoint'"
        echo "==="
    } | tee -a "$log_file"
}

# Run API test suite
run_api_tests() {
    echo "Running API Test Suite..."
    
    # Test GET
    test_api "GET" "https://api.github.com/zen"
    
    # Test POST
    test_api "POST" "https://httpbin.org/post" '{"test":"data"}'
    
    # Test with auth
    test_api "GET" "https://api.github.com/user" "" "YOUR_TOKEN"
}

# 2. Website Monitoring
# -----------------

# Check website health
check_website() {
    local url="$1"
    local check_type="${2:-basic}" # basic, full
    local log_file="$LOG_DIR/website_health_$(date +%Y%m%d).log"
    
    echo "Checking website: $url"
    
    {
        echo "=== $(date) ==="
        echo "URL: $url"
        echo "Check type: $check_type"
        
        # Basic check (wget spider)
        if wget --spider --timeout=10 "$url" 2>&1; then
            echo "Basic check: OK"
            
            # Full check
            if [ "$check_type" = "full" ]; then
                # Check response time
                local response_time
                response_time=$(curl -s -w "%{time_total}" -o /dev/null "$url")
                echo "Response time: ${response_time}s"
                
                # Check SSL certificate
                echo "SSL Certificate:"
                curl -vI "$url" 2>&1 | grep "SSL certificate"
                
                # Check for specific content
                if curl -s "$url" | grep -q "DOCTYPE html"; then
                    echo "Content check: OK"
                else
                    echo "Content check: Failed"
                fi
            fi
        else
            echo "Website is DOWN"
        fi
        echo "==="
    } | tee -a "$log_file"
}

# Monitor multiple websites
monitor_websites() {
    local sites=(
        "https://example.com"
        "https://github.com"
        "https://httpbin.org"
    )
    
    for site in "${sites[@]}"; do
        check_website "$site" "full"
        sleep 1
    done
}

# 3. Batch Download Manager
# ---------------------

# Download manager with retry and resume
download_manager() {
    local url="$1"
    local output="$2"
    local max_retries=3
    local retry_count=0
    
    echo "Downloading: $url"
    
    while [ $retry_count -lt $max_retries ]; do
        if wget -c \
            --progress=bar \
            --retry-connrefused \
            --waitretry=1 \
            -O "$output" \
            "$url"; then
            echo "Download successful: $output"
            return 0
        else
            retry_count=$((retry_count + 1))
            echo "Retry $retry_count of $max_retries"
            sleep 2
        fi
    done
    
    echo "Failed to download after $max_retries attempts"
    return 1
}

# Process download queue
process_download_queue() {
    local queue_file="$OUTPUT_DIR/download_queue.txt"
    local download_dir="$OUTPUT_DIR/downloads"
    mkdir -p "$download_dir"
    
    # Create sample queue
    cat > "$queue_file" << EOF
https://example.com/file1.pdf
https://example.com/file2.jpg
https://example.com/file3.zip
EOF
    
    # Process queue
    while IFS= read -r url; do
        local filename
        filename=$(basename "$url")
        download_manager "$url" "$download_dir/$filename"
    done < "$queue_file"
}

# 4. Site Backup Tool
# ---------------

# Create site backup
backup_site() {
    local url="$1"
    local backup_dir="$OUTPUT_DIR/backups/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    echo "Creating backup of: $url"
    
    # Mirror the site
    wget --mirror \
         --convert-links \
         --html-extension \
         --restrict-file-names=windows \
         --no-parent \
         --no-verbose \
         --show-progress \
         -P "$backup_dir" \
         "$url"
    
    # Create archive
    local archive_name="backup_$(date +%Y%m%d).tar.gz"
    tar -czf "$OUTPUT_DIR/backups/$archive_name" -C "$backup_dir" .
    
    echo "Backup created: $OUTPUT_DIR/backups/$archive_name"
}

# Rotate backups
rotate_backups() {
    local backup_dir="$OUTPUT_DIR/backups"
    local max_backups=5
    
    # Remove old backups
    cd "$backup_dir" && ls -t *.tar.gz | tail -n +$((max_backups + 1)) | xargs rm -f
}

# 5. Command Line Interface
# ---------------------

show_help() {
    cat << EOF
Web Automation Framework

Usage: $0 <command> [options]

Commands:
    test        Run API test suite
    monitor     Monitor website health
    download    Process download queue
    backup      Create site backup
    help        Show this help message

Options:
    -u, --url URL      Target URL
    -t, --type TYPE    Check type (basic, full)
    -h, --help         Show this help message
EOF
}

# Main execution
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        test)
            run_api_tests
            ;;
        monitor)
            monitor_websites
            ;;
        download)
            process_download_queue
            ;;
        backup)
            local url="${1:-https://example.com}"
            backup_site "$url"
            rotate_backups
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
