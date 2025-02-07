#!/bin/bash

# Sorting and Filtering Commands
# --------------------------
# This script demonstrates the usage of sort, uniq,
# and related filtering commands.

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
    # Numbers file
    cat > "$TEST_DIR/numbers.txt" << 'EOF'
42
13
7
42
99
7
13
EOF

    # Words file
    cat > "$TEST_DIR/words.txt" << 'EOF'
apple
banana
cherry
apple
date
banana
elderberry
cherry
EOF

    # Log entries
    cat > "$TEST_DIR/access.log" << 'EOF'
192.168.1.100 GET /index.html 200
10.0.0.1 POST /api/login 401
192.168.1.100 GET /style.css 200
10.0.0.2 GET /api/data 500
192.168.1.100 GET /script.js 200
10.0.0.1 GET /index.html 200
10.0.0.2 POST /api/upload 413
EOF

    # CSV data
    cat > "$TEST_DIR/data.csv" << 'EOF'
Name,Age,City,Score
John Smith,30,New York,85
Alice Brown,25,London,92
Bob Wilson,35,Paris,78
John Smith,30,New York,85
Charlie Davis,28,Tokyo,88
Alice Brown,25,London,92
EOF
}

# 1. Sort Examples
# ------------

sort_examples() {
    echo "Sort Examples:"
    echo "-------------"
    
    # Basic sorting
    echo "1. Basic sort:"
    sort "$TEST_DIR/numbers.txt"
    
    # Numeric sort
    echo -e "\n2. Numeric sort:"
    sort -n "$TEST_DIR/numbers.txt"
    
    # Reverse sort
    echo -e "\n3. Reverse sort:"
    sort -r "$TEST_DIR/words.txt"
    
    # Sort by field
    echo -e "\n4. Sort by second field (age):"
    sort -t',' -k2 -n "$TEST_DIR/data.csv"
    
    # Multiple sort keys
    echo -e "\n5. Sort by city then name:"
    sort -t',' -k3,3 -k1,1 "$TEST_DIR/data.csv"
}

# 2. Uniq Examples
# ------------

uniq_examples() {
    echo "Uniq Examples:"
    echo "-------------"
    
    # Basic unique
    echo "1. Basic unique:"
    sort "$TEST_DIR/words.txt" | uniq
    
    # Count occurrences
    echo -e "\n2. Count occurrences:"
    sort "$TEST_DIR/words.txt" | uniq -c
    
    # Only show duplicates
    echo -e "\n3. Only duplicates:"
    sort "$TEST_DIR/words.txt" | uniq -d
    
    # Only show unique lines
    echo -e "\n4. Only unique lines:"
    sort "$TEST_DIR/words.txt" | uniq -u
    
    # Skip fields
    echo -e "\n5. Unique by first field:"
    sort -t',' -k1,1 "$TEST_DIR/data.csv" | uniq -f 1
}

# 3. Combined Operations
# -----------------

combined_operations() {
    echo "Combined Operations:"
    echo "------------------"
    
    # Sort and count unique IP addresses
    echo "1. Unique IP addresses and counts:"
    awk '{print $1}' "$TEST_DIR/access.log" |
        sort |
        uniq -c |
        sort -rn
    
    # Find duplicate records
    echo -e "\n2. Duplicate records:"
    sort "$TEST_DIR/data.csv" |
        uniq -d
    
    # Sort by multiple criteria
    echo -e "\n3. Multi-criteria sort:"
    sort -t',' -k3,3 -k2,2n "$TEST_DIR/data.csv" |
        uniq
    
    # Frequency analysis
    echo -e "\n4. HTTP status code frequency:"
    awk '{print $4}' "$TEST_DIR/access.log" |
        sort |
        uniq -c |
        sort -rn
}

# 4. Advanced Patterns
# ---------------

advanced_patterns() {
    echo "Advanced Patterns:"
    echo "----------------"
    
    # Sort IP addresses naturally
    echo "1. Natural sort of IPs:"
    awk '{print $1}' "$TEST_DIR/access.log" |
        sort -t'.' -k1,1n -k2,2n -k3,3n -k4,4n |
        uniq
    
    # Group and count by multiple fields
    echo -e "\n2. Group by city and count:"
    cut -d',' -f1,3 "$TEST_DIR/data.csv" |
        sort |
        uniq -c |
        sort -rn
    
    # Find unique combinations
    echo -e "\n3. Unique method-status combinations:"
    awk '{print $2, $4}' "$TEST_DIR/access.log" |
        sort |
        uniq -c |
        sort -rn
}

# 5. Practical Examples
# ----------------

# Analyze log entries
analyze_logs() {
    local log_file="$1"
    local output_dir="$2"
    
    echo "Analyzing log file: $log_file"
    
    # IP address statistics
    awk '{print $1}' "$log_file" |
        sort |
        uniq -c |
        sort -rn > "$output_dir/ip_stats.txt"
    
    # HTTP status codes
    awk '{print $4}' "$log_file" |
        sort |
        uniq -c |
        sort -rn > "$output_dir/status_stats.txt"
    
    # Request methods
    awk '{print $2}' "$log_file" |
        sort |
        uniq -c |
        sort -rn > "$output_dir/method_stats.txt"
    
    echo "Analysis complete. Check output files in $output_dir"
}

# Find duplicate data
find_duplicates() {
    local input_file="$1"
    local field_num="$2"
    local output_file="$3"
    
    echo "Finding duplicates in field $field_num of $input_file"
    
    cut -d',' -f"$field_num" "$input_file" |
        sort |
        uniq -d > "$output_file"
    
    echo "Duplicates saved to $output_file"
}

# Sort and merge files
sort_merge() {
    local output_file="$1"
    shift
    local files=("$@")
    
    echo "Merging files: ${files[*]}"
    
    sort -u "${files[@]}" > "$output_file"
    
    echo "Merged output saved to $output_file"
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    sort_examples
    echo -e "\n"
    uniq_examples
    echo -e "\n"
    combined_operations
    echo -e "\n"
    advanced_patterns
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Analyze logs
    analyze_logs "$TEST_DIR/access.log" "$OUTPUT_DIR"
    
    # Find duplicates
    find_duplicates "$TEST_DIR/data.csv" 1 "$OUTPUT_DIR/duplicates.txt"
    
    # Sort and merge
    sort_merge "$OUTPUT_DIR/merged.txt" \
        "$TEST_DIR/numbers.txt" \
        "$TEST_DIR/words.txt"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
