#!/bin/bash

# Basic Regular Expression Examples
# -----------------------------
# This script demonstrates basic regex patterns and
# their usage in shell scripting.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_FILE="$OUTPUT_DIR/test.txt"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Create test data
create_test_data() {
    cat > "$TEST_FILE" << 'EOF'
John Doe
jane.doe@example.com
Bob Smith Jr.
alice-smith@company.co.uk
12345
(555) 123-4567
+1-987-654-3210
https://www.example.com
http://sub.domain.org/path
192.168.1.1
2025-02-07
02/07/2025
Text with some numbers 42 and 7.
Special chars: !@#$%^&*()
CamelCaseText
snake_case_text
UPPERCASE_TEXT
EOF
}

# 1. Basic Character Matching
# -----------------------

basic_matching() {
    echo "Basic Character Matching:"
    echo "------------------------"
    
    # Single character
    echo "1. Lines containing 'a':"
    grep "a" "$TEST_FILE"
    
    # Character class
    echo -e "\n2. Lines with vowels:"
    grep "[aeiou]" "$TEST_FILE"
    
    # Character range
    echo -e "\n3. Lines with numbers:"
    grep "[0-9]" "$TEST_FILE"
    
    # Negated class
    echo -e "\n4. Lines without numbers:"
    grep "[^0-9]" "$TEST_FILE"
}

# 2. Quantifiers
# -----------

quantifier_examples() {
    echo "Quantifier Examples:"
    echo "-------------------"
    
    # Zero or more
    echo "1. Lines with 'o' followed by zero or more 'o's:"
    grep "o*" "$TEST_FILE"
    
    # One or more
    echo -e "\n2. Lines with one or more digits:"
    grep -E "[0-9]+" "$TEST_FILE"
    
    # Zero or one
    echo -e "\n3. Optional 's' at the end:"
    grep -E "number?s?" "$TEST_FILE"
    
    # Exact count
    echo -e "\n4. Exactly three digits:"
    grep -E "[0-9]{3}" "$TEST_FILE"
    
    # Range count
    echo -e "\n5. Two to four digits:"
    grep -E "[0-9]{2,4}" "$TEST_FILE"
}

# 3. Anchors
# --------

anchor_examples() {
    echo "Anchor Examples:"
    echo "---------------"
    
    # Start of line
    echo "1. Lines starting with uppercase:"
    grep "^[A-Z]" "$TEST_FILE"
    
    # End of line
    echo -e "\n2. Lines ending with digit:"
    grep "[0-9]$" "$TEST_FILE"
    
    # Word boundary
    echo -e "\n3. Words containing 'Text':"
    grep -E "\bText\b" "$TEST_FILE"
    
    # Complete line
    echo -e "\n4. Lines with only digits:"
    grep "^[0-9]+$" "$TEST_FILE"
}

# 4. Special Characters
# -----------------

special_characters() {
    echo "Special Characters:"
    echo "------------------"
    
    # Any character
    echo "1. Three characters between 'e' and 'm':"
    grep "e...m" "$TEST_FILE"
    
    # Alternation
    echo -e "\n2. 'http' or 'https':"
    grep -E "https?://" "$TEST_FILE"
    
    # Grouping
    echo -e "\n3. Repeated patterns:"
    grep -E "(ha){2,}" "$TEST_FILE"
    
    # Escaped characters
    echo -e "\n4. Lines with periods:"
    grep "\." "$TEST_FILE"
}

# 5. Common Patterns
# --------------

common_patterns() {
    echo "Common Patterns:"
    echo "---------------"
    
    # Email addresses
    echo "1. Email addresses:"
    grep -E "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$TEST_FILE"
    
    # URLs
    echo -e "\n2. URLs:"
    grep -E "https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/[A-Za-z0-9./-]*)?" "$TEST_FILE"
    
    # Phone numbers
    echo -e "\n3. Phone numbers:"
    grep -E "(\+1-)?[0-9]{3}[- ]?[0-9]{3}[- ]?[0-9]{4}" "$TEST_FILE"
    
    # IP addresses
    echo -e "\n4. IP addresses:"
    grep -E "([0-9]{1,3}\.){3}[0-9]{1,3}" "$TEST_FILE"
    
    # Dates
    echo -e "\n5. Dates:"
    grep -E "[0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}/[0-9]{2}/[0-9]{4}" "$TEST_FILE"
}

# 6. Case Sensitivity
# ---------------

case_examples() {
    echo "Case Sensitivity Examples:"
    echo "-------------------------"
    
    # Case sensitive
    echo "1. Case sensitive 'text':"
    grep "text" "$TEST_FILE"
    
    # Case insensitive
    echo -e "\n2. Case insensitive 'text':"
    grep -i "text" "$TEST_FILE"
    
    # Word variations
    echo -e "\n3. Different case patterns:"
    grep -E "[A-Z][a-z]+" "$TEST_FILE"
}

# 7. Validation Functions
# -------------------

# Validate email
validate_email() {
    local email="$1"
    local pattern="^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
    
    if [[ "$email" =~ $pattern ]]; then
        echo "'$email' is a valid email address"
        return 0
    else
        echo "'$email' is NOT a valid email address"
        return 1
    fi
}

# Validate phone number
validate_phone() {
    local phone="$1"
    local pattern="^(\+1-)?[0-9]{3}[- ]?[0-9]{3}[- ]?[0-9]{4}$"
    
    if [[ "$phone" =~ $pattern ]]; then
        echo "'$phone' is a valid phone number"
        return 0
    else
        echo "'$phone' is NOT a valid phone number"
        return 1
    fi
}

# Validate IP address
validate_ip() {
    local ip="$1"
    local pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ "$ip" =~ $pattern ]]; then
        # Additional validation for valid numbers
        local IFS='.'
        read -ra octets <<< "$ip"
        for octet in "${octets[@]}"; do
            if ((octet < 0 || octet > 255)); then
                echo "'$ip' is NOT a valid IP address"
                return 1
            fi
        done
        echo "'$ip' is a valid IP address"
        return 0
    else
        echo "'$ip' is NOT a valid IP address"
        return 1
    fi
}

# 8. Practical Examples
# -----------------

# Extract all unique email addresses
extract_emails() {
    local file="$1"
    grep -E -o "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}" "$file" | sort -u
}

# Format phone numbers consistently
format_phones() {
    local file="$1"
    grep -E "(\+1-)?[0-9]{3}[- ]?[0-9]{3}[- ]?[0-9]{4}" "$file" | 
        sed -E 's/[- ]//g' |
        sed -E 's/(\+1)?([0-9]{3})([0-9]{3})([0-9]{4})/+1-\2-\3-\4/'
}

# Main execution
main() {
    # Create test data
    create_test_data
    
    # Run examples
    basic_matching
    echo -e "\n"
    quantifier_examples
    echo -e "\n"
    anchor_examples
    echo -e "\n"
    special_characters
    echo -e "\n"
    common_patterns
    echo -e "\n"
    case_examples
    echo -e "\n"
    
    # Validation examples
    echo "Validation Examples:"
    echo "-------------------"
    validate_email "test@example.com"
    validate_email "invalid.email"
    validate_phone "+1-123-456-7890"
    validate_phone "invalid-phone"
    validate_ip "192.168.1.1"
    validate_ip "256.256.256.256"
    
    # Practical examples
    echo -e "\nExtracted Email Addresses:"
    extract_emails "$TEST_FILE"
    
    echo -e "\nFormatted Phone Numbers:"
    format_phones "$TEST_FILE"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
