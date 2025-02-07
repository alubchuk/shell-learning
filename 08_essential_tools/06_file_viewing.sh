#!/bin/bash

# File Viewing Commands
# ------------------
# This script demonstrates the usage of essential file viewing
# commands: cat, head, tail, less, echo

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
    # Create a sample log file
    seq 1 100 | awk '{print "Line " $1 ": Log entry at " strftime("%Y-%m-%d %H:%M:%S")}' > "$TEST_DIR/sample.log"
    
    # Create a configuration file
    cat > "$TEST_DIR/config.ini" << 'EOF'
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASS=secret

# Server Configuration
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
DEBUG_MODE=true

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE=/var/log/app.log
EOF

    # Create a data file
    cat > "$TEST_DIR/data.txt" << 'EOF'
ID,Name,Department,Salary
1,John Smith,Engineering,75000
2,Jane Doe,Marketing,65000
3,Bob Wilson,Engineering,80000
4,Alice Brown,Sales,70000
5,Charlie Davis,Marketing,62000
EOF
}

# 1. Echo Examples
# ------------

echo_examples() {
    echo "Echo Examples:"
    echo "-------------"
    
    # Basic output
    echo "1. Basic output:"
    echo "Hello, World!"
    
    # Escape sequences
    echo -e "\n2. Escape sequences:"
    echo -e "Tab\tSeparated\tText"
    echo -e "Line 1\nLine 2\nLine 3"
    
    # Variables
    echo -e "\n3. Variables:"
    local name="John"
    echo "Hello, $name!"
    
    # Command substitution
    echo -e "\n4. Command substitution:"
    echo "Current date: $(date)"
    
    # Suppress newline
    echo -e "\n5. No newline:"
    echo -n "First "
    echo "Second"
}

# 2. Cat Examples
# -----------

cat_examples() {
    echo "Cat Examples:"
    echo "------------"
    
    # Display file contents
    echo "1. Display file:"
    cat "$TEST_DIR/config.ini"
    
    # Number lines
    echo -e "\n2. Number all lines:"
    cat -n "$TEST_DIR/config.ini"
    
    # Show non-printing characters
    echo -e "\n3. Show special characters:"
    cat -A "$TEST_DIR/config.ini" | head -n 5
    
    # Squeeze blank lines
    echo -e "\n4. Squeeze blank lines:"
    cat -s "$TEST_DIR/config.ini"
    
    # Concatenate files
    echo -e "\n5. Concatenate files:"
    cat "$TEST_DIR/config.ini" "$TEST_DIR/data.txt"
}

# 3. Head Examples
# ------------

head_examples() {
    echo "Head Examples:"
    echo "-------------"
    
    # Default (first 10 lines)
    echo "1. Default head:"
    head "$TEST_DIR/sample.log"
    
    # Custom number of lines
    echo -e "\n2. First 5 lines:"
    head -n 5 "$TEST_DIR/sample.log"
    
    # Show all but last N lines
    echo -e "\n3. All but last 95 lines:"
    head -n -95 "$TEST_DIR/sample.log"
    
    # Multiple files
    echo -e "\n4. Head of multiple files:"
    head -n 2 "$TEST_DIR/config.ini" "$TEST_DIR/data.txt"
}

# 4. Tail Examples
# ------------

tail_examples() {
    echo "Tail Examples:"
    echo "-------------"
    
    # Default (last 10 lines)
    echo "1. Default tail:"
    tail "$TEST_DIR/sample.log"
    
    # Custom number of lines
    echo -e "\n2. Last 5 lines:"
    tail -n 5 "$TEST_DIR/sample.log"
    
    # Follow file updates
    echo -e "\n3. Follow mode (for 5 seconds):"
    tail -f "$TEST_DIR/sample.log" &
    TAIL_PID=$!
    sleep 5
    kill $TAIL_PID
    
    # Multiple files
    echo -e "\n4. Tail of multiple files:"
    tail -n 2 "$TEST_DIR/config.ini" "$TEST_DIR/data.txt"
}

# 5. Practical Examples
# ----------------

# Monitor log file
monitor_log() {
    local log_file="$1"
    local pattern="${2:-ERROR}"
    
    echo "Monitoring $log_file for pattern: $pattern"
    tail -f "$log_file" | grep --line-buffered "$pattern"
}

# Display file with context
display_with_context() {
    local file="$1"
    local line_num="$2"
    local context="${3:-5}"
    
    echo "Displaying line $line_num with $context lines of context:"
    head -n $((line_num + context)) "$file" | tail -n $((2 * context + 1))
}

# Concatenate with line numbers
cat_numbered() {
    local output_file="$1"
    shift
    
    echo "Creating numbered output from multiple files:"
    cat -n "$@" > "$output_file"
    echo "Output saved to: $output_file"
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    echo_examples
    echo -e "\n"
    cat_examples
    echo -e "\n"
    head_examples
    echo -e "\n"
    tail_examples
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Monitor log (background)
    monitor_log "$TEST_DIR/sample.log" "Line 5" &
    MONITOR_PID=$!
    sleep 2
    kill $MONITOR_PID
    
    # Display with context
    display_with_context "$TEST_DIR/sample.log" 50 3
    
    # Concatenate files
    cat_numbered "$OUTPUT_DIR/combined.txt" \
        "$TEST_DIR/config.ini" \
        "$TEST_DIR/data.txt"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
