#!/bin/bash

# Grep Examples
# ------------

SAMPLE_DIR="./sample_data"

echo "Grep Examples using sample files"
echo "-------------------------------"

# Basic pattern matching
echo -e "\n1. Basic pattern matching (find lines containing 'example'):"
grep "example" "$SAMPLE_DIR/sample.txt"

# Case-insensitive search
echo -e "\n2. Case-insensitive search (find 'LINE' regardless of case):"
grep -i "LINE" "$SAMPLE_DIR/sample.txt"

# Show line numbers
echo -e "\n3. Show line numbers (for lines containing 'comment'):"
grep -n "comment" "$SAMPLE_DIR/sample.txt"

# Count matches
echo -e "\n4. Count matches (number of lines containing 'Duplicate'):"
grep -c "Duplicate" "$SAMPLE_DIR/sample.txt"

# Show context (lines before and after match)
echo -e "\n5. Show context (1 line before and after matches containing 'list'):"
grep -A 1 -B 1 "list" "$SAMPLE_DIR/sample.txt"

# Invert match (show lines NOT containing pattern)
echo -e "\n6. Invert match (lines NOT containing 'a'):"
grep -v "a" "$SAMPLE_DIR/sample.txt" | head -n 3

# Match whole words only
echo -e "\n7. Match whole words only (word 'is' but not 'this'):"
grep -w "is" "$SAMPLE_DIR/sample.txt"

# Regular expressions
echo -e "\n8. Regular expressions (find email addresses):"
grep -E "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$SAMPLE_DIR/sample.txt"

# Multiple patterns
echo -e "\n9. Multiple patterns (lines containing either 'http' or 'https'):"
grep -E "https?://" "$SAMPLE_DIR/sample.txt"

# Recursive search in directory
echo -e "\n10. Recursive search (find 'password' in all files):"
grep -r "password" "$SAMPLE_DIR"

# Search in specific file types
echo -e "\n11. Search in specific file types (find 'host' in .ini files):"
find "$SAMPLE_DIR" -name "*.ini" -exec grep "host" {} \;

# Practical example: Analyzing log files
echo -e "\n12. Analyzing log files (find all 404 errors):"
grep "HTTP/1.1\" 404" "$SAMPLE_DIR/access.log"

# Count HTTP response codes
echo -e "\n13. Count HTTP response codes:"
echo "Response code distribution:"
grep -o "HTTP/1.1\" [0-9][0-9][0-9]" "$SAMPLE_DIR/access.log" | \
    sort | uniq -c | sort -nr

# Find specific IP addresses
echo -e "\n14. Find specific IP addresses (192.168.1.10*):"
grep "^192.168.1.10" "$SAMPLE_DIR/access.log"

# Quiet mode (just return exit status)
echo -e "\n15. Quiet mode (check if pattern exists):"
if grep -q "Database" "$SAMPLE_DIR/config.ini"; then
    echo "Database section found in config.ini"
fi

# Using grep with pipes
echo -e "\n16. Using grep with pipes (find Engineering department with salary > 75000):"
grep "Engineering" "$SAMPLE_DIR/data.csv" | grep -E ",([7-9][0-9]|[0-9]{3,})[0-9]{3},"

# Extended example: Security scan
echo -e "\n17. Security scan (find potential sensitive information):"
echo "Scanning for sensitive information..."
patterns=("password" "secret" "key" "token" "credential")
for pattern in "${patterns[@]}"; do
    echo "Checking for '$pattern':"
    grep -r -i "$pattern" "$SAMPLE_DIR" || true
done
