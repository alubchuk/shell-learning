#!/bin/bash

# sed Examples
# ----------
# This script demonstrates various sed features and
# usage patterns for text manipulation.

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
    # Sample text file
    cat > "$TEST_DIR/sample.txt" << 'EOF'
This is line 1
This is line 2
This is line 3
This is a test line
Another test line
Final test line
Some numbers: 123, 456, 789
Some emails: john@example.com, jane@example.com
Phone: (555) 123-4567
Date: 2025-02-07
#This is a comment
  Indented line
NO_SPACES_LINE
CamelCaseText
snake_case_text
UPPERCASE_TEXT
EOF

    # HTML file
    cat > "$TEST_DIR/page.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Welcome</h1>
    <p>This is a test page.</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
        <li>Item 3</li>
    </ul>
    <div class="content">
        Some content here
    </div>
</body>
</html>
EOF

    # Configuration file
    cat > "$TEST_DIR/config.txt" << 'EOF'
# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin
DB_PASS=secret123

# Server settings
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
DEBUG_MODE=true

# Paths
LOG_PATH=/var/log/app.log
DATA_PATH=/var/data
TEMP_PATH=/tmp
EOF
}

# 1. Basic Substitution
# -----------------

basic_substitution() {
    echo "Basic Substitution:"
    echo "------------------"
    
    # Simple replacement
    echo "1. Replace 'line' with 'row':"
    sed 's/line/row/g' "$TEST_DIR/sample.txt"
    
    # Case insensitive
    echo -e "\n2. Case insensitive replacement:"
    sed 's/test/TEST/gi' "$TEST_DIR/sample.txt"
    
    # Replace nth occurrence
    echo -e "\n3. Replace 2nd occurrence:"
    sed 's/test/TEST/2' "$TEST_DIR/sample.txt"
    
    # Replace on specific lines
    echo -e "\n4. Replace on lines 1-3:"
    sed '1,3s/is/IS/g' "$TEST_DIR/sample.txt"
}

# 2. Line Operations
# --------------

line_operations() {
    echo "Line Operations:"
    echo "---------------"
    
    # Print specific lines
    echo "1. Print lines 2-4:"
    sed -n '2,4p' "$TEST_DIR/sample.txt"
    
    # Delete lines
    echo -e "\n2. Delete lines 1-2:"
    sed '1,2d' "$TEST_DIR/sample.txt"
    
    # Insert before
    echo -e "\n3. Insert before line 3:"
    sed '3i\NEW LINE' "$TEST_DIR/sample.txt"
    
    # Append after
    echo -e "\n4. Append after line 3:"
    sed '3a\NEW LINE' "$TEST_DIR/sample.txt"
}

# 3. Pattern Space
# ------------

pattern_space() {
    echo "Pattern Space Operations:"
    echo "-----------------------"
    
    # Hold space example
    echo "1. Reverse pairs of lines:"
    sed 'N;P;D' "$TEST_DIR/sample.txt"
    
    # Multiple lines
    echo -e "\n2. Join lines:"
    sed ':a;N;$!ba;s/\n/ /g' "$TEST_DIR/sample.txt"
    
    # Duplicate lines
    echo -e "\n3. Duplicate each line:"
    sed 'p' "$TEST_DIR/sample.txt"
    
    # Exchange pattern and hold space
    echo -e "\n4. Exchange with hold space:"
    sed 'x;n' "$TEST_DIR/sample.txt"
}

# 4. Regular Expressions
# ------------------

regex_operations() {
    echo "Regular Expression Operations:"
    echo "----------------------------"
    
    # Basic regex
    echo "1. Lines starting with 'This':"
    sed -n '/^This/p' "$TEST_DIR/sample.txt"
    
    # Extended regex
    echo -e "\n2. Extract email addresses:"
    sed -E 's/.*([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}).*/\1/g' "$TEST_DIR/sample.txt"
    
    # Back references
    echo -e "\n3. Swap words:"
    sed -E 's/(word1) (word2)/\2 \1/g' "$TEST_DIR/sample.txt"
    
    # Multiple patterns
    echo -e "\n4. Multiple substitutions:"
    sed -e 's/test/TEST/g' -e 's/line/LINE/g' "$TEST_DIR/sample.txt"
}

# 5. HTML Processing
# --------------

html_processing() {
    echo "HTML Processing:"
    echo "---------------"
    
    # Remove HTML tags
    echo "1. Remove HTML tags:"
    sed 's/<[^>]*>//g' "$TEST_DIR/page.html"
    
    # Extract specific tags
    echo -e "\n2. Extract <li> contents:"
    sed -n 's/.*<li>\(.*\)<\/li>.*/\1/p' "$TEST_DIR/page.html"
    
    # Add attributes
    echo -e "\n3. Add class to paragraphs:"
    sed 's/<p>/<p class="text">/g' "$TEST_DIR/page.html"
    
    # Format HTML
    echo -e "\n4. Indent HTML:"
    sed 's/^/    /' "$TEST_DIR/page.html"
}

# 6. Configuration Processing
# ----------------------

config_processing() {
    echo "Configuration Processing:"
    echo "-----------------------"
    
    # Remove comments
    echo "1. Remove comments:"
    sed '/^#/d' "$TEST_DIR/config.txt"
    
    # Extract values
    echo -e "\n2. Extract values:"
    sed -n 's/.*=\(.*\)/\1/p' "$TEST_DIR/config.txt"
    
    # Update values
    echo -e "\n3. Update port value:"
    sed 's/\(SERVER_PORT=\).*/\18081/' "$TEST_DIR/config.txt"
    
    # Format output
    echo -e "\n4. Format as JSON:"
    sed -n 's/\([^=]*\)=\(.*\)/"\1": "\2",/p' "$TEST_DIR/config.txt"
}

# 7. Advanced Features
# ----------------

advanced_features() {
    echo "Advanced Features:"
    echo "----------------"
    
    # Conditional execution
    echo "1. Execute if pattern matches:"
    sed '/test/{s/line/LINE/g}' "$TEST_DIR/sample.txt"
    
    # Range patterns
    echo -e "\n2. Process range of patterns:"
    sed '/start/,/end/s/test/TEST/g' "$TEST_DIR/sample.txt"
    
    # Branch and labels
    echo -e "\n3. Branch to label:"
    sed ':start;s/test/TEST/g;t start' "$TEST_DIR/sample.txt"
    
    # Quit after pattern
    echo -e "\n4. Quit after pattern:"
    sed '/test/q' "$TEST_DIR/sample.txt"
}

# 8. Practical Examples
# -----------------

# Format log entries
format_logs() {
    local input="$1"
    sed -E 's/^([0-9-]+) ([0-9:]+) ([A-Z]+)(.*)/[\1 \2] (\3)\4/' "$input"
}

# Clean configuration
clean_config() {
    local input="$1"
    sed -e '/^#/d' -e '/^$/d' -e 's/[[:space:]]*$//' "$input"
}

# Convert case
convert_case() {
    local input="$1"
    local case="$2"
    case "$case" in
        upper) sed 's/.*/\U&/' "$input" ;;
        lower) sed 's/.*/\L&/' "$input" ;;
        *) echo "Invalid case: $case" >&2; return 1 ;;
    esac
}

# Format JSON
format_json() {
    local input="$1"
    sed -E 's/^[[:space:]]*//' |
        sed -E 's/([^,])$/\1,/' |
        sed '1i{' |
        sed '$s/,$/\n}/'
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    basic_substitution
    echo -e "\n"
    line_operations
    echo -e "\n"
    pattern_space
    echo -e "\n"
    regex_operations
    echo -e "\n"
    html_processing
    echo -e "\n"
    config_processing
    echo -e "\n"
    advanced_features
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    echo "1. Formatted logs:"
    format_logs "$TEST_DIR/sample.txt"
    
    echo -e "\n2. Cleaned config:"
    clean_config "$TEST_DIR/config.txt"
    
    echo -e "\n3. Uppercase conversion:"
    convert_case "$TEST_DIR/sample.txt" "upper"
    
    echo -e "\n4. JSON formatting:"
    clean_config "$TEST_DIR/config.txt" | format_json
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
