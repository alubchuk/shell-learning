#!/bin/bash

# Text Processing Examples (tr and cut)
# ----------------------------------
# This script demonstrates various uses of tr and cut commands
# for text processing and manipulation.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Create test data
setup_test_data() {
    # Create sample text file
    cat > sample.txt << 'EOF'
Hello, World!
This is a TEST file.
Multiple     spaces      here.
123-456-789
user@example.com
PATH=/usr/local/bin:/usr/bin:/bin
CSV,data,example,here
MIXED case TEXT
EOF
    
    # Create CSV data
    cat > data.csv << 'EOF'
Name,Age,City,Email
John Doe,30,New York,john@example.com
Jane Smith,25,Los Angeles,jane@example.com
Bob Johnson,45,Chicago,bob@example.com
Alice Brown,35,Houston,alice@example.com
EOF
    
    # Create log data
    cat > access.log << 'EOF'
192.168.1.100 - - [07/Feb/2025:10:00:01 +0100] "GET /index.html HTTP/1.1" 200 1234
192.168.1.101 - - [07/Feb/2025:10:00:02 +0100] "POST /api/data HTTP/1.1" 201 567
192.168.1.102 - - [07/Feb/2025:10:00:03 +0100] "GET /images/logo.png HTTP/1.1" 200 8901
192.168.1.103 - - [07/Feb/2025:10:00:04 +0100] "GET /css/style.css HTTP/1.1" 304 0
EOF
}

# Clean up test data
cleanup_test_data() {
    rm -f sample.txt data.csv access.log
}

# 1. Basic tr Examples
# -----------------

tr_basics() {
    echo "Basic tr examples:"
    echo "----------------"
    
    # Convert to uppercase
    echo "1. Convert to uppercase:"
    cat sample.txt | tr '[:lower:]' '[:upper:]'
    
    # Convert to lowercase
    echo -e "\n2. Convert to lowercase:"
    cat sample.txt | tr '[:upper:]' '[:lower:]'
    
    # Replace characters
    echo -e "\n3. Replace spaces with underscores:"
    cat sample.txt | tr ' ' '_'
    
    # Replace multiple characters
    echo -e "\n4. Replace punctuation with *:"
    cat sample.txt | tr '[:punct:]' '*'
}

# 2. Advanced tr Examples
# --------------------

tr_advanced() {
    echo "Advanced tr examples:"
    echo "------------------"
    
    # Delete characters
    echo "1. Delete all digits:"
    cat sample.txt | tr -d '[:digit:]'
    
    # Squeeze repeating characters
    echo -e "\n2. Squeeze multiple spaces:"
    cat sample.txt | tr -s ' '
    
    # Delete complement of set
    echo -e "\n3. Keep only alphanumeric and spaces:"
    cat sample.txt | tr -cd '[:alnum:] \n'
    
    # Complex transformations
    echo -e "\n4. ROT13 encoding:"
    echo "Hello, World!" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
}

# 3. Basic cut Examples
# ------------------

cut_basics() {
    echo "Basic cut examples:"
    echo "-----------------"
    
    # Cut by character
    echo "1. First 5 characters of each line:"
    cat sample.txt | cut -c1-5
    
    # Cut by field with delimiter
    echo -e "\n2. Extract CSV fields:"
    cat data.csv | cut -d',' -f1,2
    
    # Cut with different delimiter
    echo -e "\n3. Extract PATH components:"
    echo "$PATH" | cut -d: -f1,3
    
    # Cut range of characters
    echo -e "\n4. Characters 2-10 of each line:"
    cat sample.txt | cut -c2-10
}

# 4. Advanced cut Examples
# ---------------------

cut_advanced() {
    echo "Advanced cut examples:"
    echo "-------------------"
    
    # Extract specific fields from log file
    echo "1. Extract IP addresses from log:"
    cat access.log | cut -d' ' -f1
    
    # Combine with other tools
    echo -e "\n2. Extract and sort email domains:"
    cat data.csv | cut -d',' -f4 | cut -d'@' -f2 | sort -u
    
    # Extract multiple ranges
    echo -e "\n3. Extract multiple character ranges:"
    cat sample.txt | cut -c1-3,5-7,9-
    
    # Handle missing fields
    echo -e "\n4. Handle missing fields:"
    echo "a,b,,d" | cut -d',' -f1-4 --output-delimiter=' '
}

# 5. Combining tr and cut
# --------------------

combine_tools() {
    echo "Combining tr and cut:"
    echo "------------------"
    
    # Normalize and extract data
    echo "1. Normalize and extract CSV data:"
    cat data.csv | tr '[:upper:]' '[:lower:]' | cut -d',' -f1,3
    
    # Clean and format data
    echo -e "\n2. Clean and format log entries:"
    cat access.log | tr -s ' ' | cut -d' ' -f1,4,5,6
    
    # Extract and transform email usernames
    echo -e "\n3. Extract and transform email usernames:"
    cat data.csv | cut -d',' -f4 | cut -d'@' -f1 | tr '[:lower:]' '[:upper:]'
    
    # Format phone numbers
    echo -e "\n4. Format phone numbers:"
    echo "123-456-789" | tr -d '-' | cut -c1-3,4-6,7-9 | tr ' ' '-'
}

# 6. Practical Examples
# ------------------

# Extract and format log data
process_logs() {
    echo "Processing logs:"
    echo "--------------"
    
    # Extract timestamp and status code
    cat access.log | tr -s ' ' | cut -d' ' -f4,9 | tr -d '[]'
}

# Process CSV data
process_csv() {
    echo "Processing CSV:"
    echo "-------------"
    
    # Create user list with email
    cat data.csv | tail -n +2 | cut -d',' -f1,4 | tr ',' ' - '
}

# Main execution
main() {
    # Setup test data
    setup_test_data
    
    # Run examples
    tr_basics
    echo -e "\n"
    tr_advanced
    echo -e "\n"
    cut_basics
    echo -e "\n"
    cut_advanced
    echo -e "\n"
    combine_tools
    echo -e "\n"
    process_logs
    echo -e "\n"
    process_csv
    
    # Cleanup
    cleanup_test_data
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
