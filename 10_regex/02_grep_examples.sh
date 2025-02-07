#!/bin/bash

# grep Examples
# -----------
# This script demonstrates various grep features and
# usage patterns for text searching and filtering.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"
readonly TEST_DIR="$OUTPUT_DIR/test_files"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$TEST_DIR"

# Create test files
create_test_files() {
    # Main log file
    cat > "$LOG_DIR/app.log" << 'EOF'
2025-02-07 10:00:00 INFO  Server started on port 8080
2025-02-07 10:00:01 DEBUG Initializing database connection
2025-02-07 10:00:02 ERROR Failed to connect to database: Connection refused
2025-02-07 10:00:03 WARN  Retrying database connection (attempt 1/3)
2025-02-07 10:00:04 ERROR Database connection timeout
2025-02-07 10:00:05 WARN  Retrying database connection (attempt 2/3)
2025-02-07 10:00:06 INFO  Database connection established
2025-02-07 10:00:07 DEBUG User authentication enabled
2025-02-07 10:00:08 INFO  Loading configuration from config.json
2025-02-07 10:00:09 ERROR Invalid configuration format
2025-02-07 10:00:10 INFO  Using default configuration
2025-02-07 10:00:11 DEBUG Starting background tasks
2025-02-07 10:00:12 INFO  System ready
EOF

    # Configuration file
    cat > "$TEST_DIR/config.ini" << 'EOF'
[database]
host = localhost
port = 5432
user = admin
password = secret123

[server]
host = 0.0.0.0
port = 8080
debug = true

[logging]
level = INFO
file = /var/log/app.log
max_size = 100M
EOF

    # Source code file
    cat > "$TEST_DIR/example.py" << 'EOF'
import logging
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(message)s'
)

class DatabaseConnection:
    def __init__(self, host, port, user, password):
        self.host = host
        self.port = port
        self.user = user
        self.password = password
        
    def connect(self):
        logging.info(f"Connecting to database at {self.host}:{self.port}")
        # Connection logic here
        
    def disconnect(self):
        logging.info("Disconnecting from database")
        # Disconnection logic here

def main():
    try:
        db = DatabaseConnection(
            host="localhost",
            port=5432,
            user="admin",
            password="secret123"
        )
        db.connect()
    except Exception as e:
        logging.error(f"Failed to connect: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF
}

# 1. Basic Pattern Matching
# ---------------------

basic_grep() {
    echo "Basic Pattern Matching:"
    echo "----------------------"
    
    # Simple string match
    echo "1. Lines containing 'ERROR':"
    grep "ERROR" "$LOG_DIR/app.log"
    
    # Case insensitive
    echo -e "\n2. Case-insensitive 'error':"
    grep -i "error" "$LOG_DIR/app.log"
    
    # Whole word match
    echo -e "\n3. Whole word 'INFO':"
    grep -w "INFO" "$LOG_DIR/app.log"
    
    # Invert match
    echo -e "\n4. Lines not containing 'DEBUG':"
    grep -v "DEBUG" "$LOG_DIR/app.log"
}

# 2. Regular Expressions
# ------------------

regex_grep() {
    echo "Regular Expression Patterns:"
    echo "--------------------------"
    
    # Basic regex
    echo "1. Lines starting with '2025':"
    grep "^2025" "$LOG_DIR/app.log"
    
    # Extended regex
    echo -e "\n2. ISO dates:"
    grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}" "$LOG_DIR/app.log"
    
    # Perl regex
    echo -e "\n3. Time format (HH:MM:SS):"
    grep -P "(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d" "$LOG_DIR/app.log"
    
    # Multiple patterns
    echo -e "\n4. ERROR or WARN messages:"
    grep -E "ERROR|WARN" "$LOG_DIR/app.log"
}

# 3. Context Control
# --------------

context_grep() {
    echo "Context Control:"
    echo "---------------"
    
    # Lines before
    echo "1. 2 lines before ERROR:"
    grep -B 2 "ERROR" "$LOG_DIR/app.log"
    
    # Lines after
    echo -e "\n2. 2 lines after ERROR:"
    grep -A 2 "ERROR" "$LOG_DIR/app.log"
    
    # Lines before and after
    echo -e "\n3. 1 line before and after ERROR:"
    grep -C 1 "ERROR" "$LOG_DIR/app.log"
    
    # Custom separator
    echo -e "\n4. Custom context separator:"
    grep -B 1 --group-separator="---" "ERROR" "$LOG_DIR/app.log"
}

# 4. File Control
# -----------

file_control() {
    echo "File Control:"
    echo "------------"
    
    # Multiple files
    echo "1. Search in multiple files:"
    grep "host" "$TEST_DIR"/*
    
    # Recursive search
    echo -e "\n2. Recursive search for 'password':"
    grep -r "password" "$TEST_DIR"
    
    # File pattern
    echo -e "\n3. Search only in .py files:"
    grep -r --include="*.py" "logging" "$TEST_DIR"
    
    # Exclude pattern
    echo -e "\n4. Exclude .ini files:"
    grep -r --exclude="*.ini" "host" "$TEST_DIR"
}

# 5. Output Control
# -------------

output_control() {
    echo "Output Control:"
    echo "--------------"
    
    # Line numbers
    echo "1. Show line numbers:"
    grep -n "INFO" "$LOG_DIR/app.log"
    
    # Only matching
    echo -e "\n2. Only matching parts:"
    grep -o "ERROR.*" "$LOG_DIR/app.log"
    
    # Count matches
    echo -e "\n3. Count ERROR occurrences:"
    grep -c "ERROR" "$LOG_DIR/app.log"
    
    # Quiet mode
    echo -e "\n4. Check if pattern exists:"
    if grep -q "ERROR" "$LOG_DIR/app.log"; then
        echo "Found ERROR messages"
    fi
}

# 6. Advanced Features
# ----------------

advanced_grep() {
    echo "Advanced Features:"
    echo "-----------------"
    
    # Binary files
    echo "1. Handle binary files:"
    grep -a "text" "$TEST_DIR"/*
    
    # Line buffered
    echo -e "\n2. Line buffered output:"
    grep --line-buffered "INFO" "$LOG_DIR/app.log"
    
    # With filename
    echo -e "\n3. Always show filename:"
    grep -H "host" "$TEST_DIR"/*
    
    # Without filename
    echo -e "\n4. Never show filename:"
    grep -h "host" "$TEST_DIR"/*
}

# 7. Practical Examples
# -----------------

# Find all error messages
find_errors() {
    local log_file="$1"
    echo "Finding all error messages in $log_file:"
    grep -n "ERROR" "$log_file"
}

# Count log levels
count_log_levels() {
    local log_file="$1"
    echo "Log level distribution in $log_file:"
    grep -o "INFO\|DEBUG\|WARN\|ERROR" "$log_file" | sort | uniq -c
}

# Search for sensitive data
find_sensitive() {
    local dir="$1"
    echo "Searching for sensitive data patterns in $dir:"
    grep -r -E "password|secret|key|token" "$dir"
}

# Extract configuration values
extract_config() {
    local config_file="$1"
    local section="$2"
    echo "Extracting [$section] configuration from $config_file:"
    grep -A 10 "^\[$section\]" "$config_file" | grep -B 10 "^\[" | grep -v "^\["
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    basic_grep
    echo -e "\n"
    regex_grep
    echo -e "\n"
    context_grep
    echo -e "\n"
    file_control
    echo -e "\n"
    output_control
    echo -e "\n"
    advanced_grep
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    find_errors "$LOG_DIR/app.log"
    echo -e "\n"
    count_log_levels "$LOG_DIR/app.log"
    echo -e "\n"
    find_sensitive "$TEST_DIR"
    echo -e "\n"
    extract_config "$TEST_DIR/config.ini" "database"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
