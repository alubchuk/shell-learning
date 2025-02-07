#!/bin/bash

# Basic curl Examples
# ----------------
# This script demonstrates basic usage of curl for
# HTTP operations and web interactions.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_URL="https://api.github.com"
readonly TEST_FILE="test.txt"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# 1. Basic HTTP Methods
# ------------------

basic_http_methods() {
    echo "Basic HTTP Methods:"
    echo "-----------------"
    
    # GET request
    echo "1. Simple GET request:"
    curl -s "https://example.com"
    
    # HEAD request
    echo -e "\n2. HEAD request (headers only):"
    curl -I "https://example.com"
    
    # POST request
    echo -e "\n3. POST request:"
    curl -X POST "https://httpbin.org/post" \
         -d "name=John&age=30"
    
    # PUT request
    echo -e "\n4. PUT request:"
    curl -X PUT "https://httpbin.org/put" \
         -d '{"name":"John","age":30}'
    
    # DELETE request
    echo -e "\n5. DELETE request:"
    curl -X DELETE "https://httpbin.org/delete"
}

# 2. Working with Headers
# --------------------

header_operations() {
    echo "Header Operations:"
    echo "-----------------"
    
    # Custom headers
    echo "1. Send custom headers:"
    curl -H "User-Agent: MyScript/1.0" \
         -H "Accept: application/json" \
         "$TEST_URL"
    
    # View response headers
    echo -e "\n2. View response headers:"
    curl -D - -s "$TEST_URL" -o /dev/null
    
    # Content type
    echo -e "\n3. JSON content type:"
    curl -H "Content-Type: application/json" \
         -d '{"key":"value"}' \
         "https://httpbin.org/post"
}

# 3. Authentication
# --------------

authentication_examples() {
    echo "Authentication Examples:"
    echo "----------------------"
    
    # Basic auth
    echo "1. Basic authentication:"
    curl -u "username:password" "https://httpbin.org/basic-auth/username/password"
    
    # Bearer token
    echo -e "\n2. Bearer token:"
    curl -H "Authorization: Bearer abc123" "$TEST_URL"
    
    # Custom auth header
    echo -e "\n3. Custom auth header:"
    curl -H "X-API-Key: your-api-key" "$TEST_URL"
}

# 4. Data Handling
# -------------

data_handling() {
    echo "Data Handling:"
    echo "--------------"
    
    # Form data
    echo "1. Send form data:"
    curl -d "param1=value1&param2=value2" \
         "https://httpbin.org/post"
    
    # JSON data
    echo -e "\n2. Send JSON data:"
    curl -H "Content-Type: application/json" \
         -d '{"key1":"value1","key2":"value2"}' \
         "https://httpbin.org/post"
    
    # File upload
    echo -e "\n3. Upload file:"
    echo "Test content" > "$OUTPUT_DIR/$TEST_FILE"
    curl -F "file=@$OUTPUT_DIR/$TEST_FILE" \
         "https://httpbin.org/post"
}

# 5. Output Options
# --------------

output_options() {
    echo "Output Options:"
    echo "---------------"
    
    # Save to file
    echo "1. Save response to file:"
    curl -o "$OUTPUT_DIR/response.txt" "https://example.com"
    
    # Silent mode
    echo -e "\n2. Silent mode (no progress):"
    curl -s "$TEST_URL"
    
    # Write out format
    echo -e "\n3. Custom write-out format:"
    curl -s -w "\nTime: %{time_total}s\nSize: %{size_download} bytes\n" \
         "https://example.com" -o /dev/null
    
    # Progress meter
    echo -e "\n4. Progress meter:"
    curl -# "https://example.com" -o /dev/null
}

# 6. Error Handling
# --------------

error_handling() {
    echo "Error Handling:"
    echo "--------------"
    
    # Fail on error
    echo "1. Fail on HTTP error:"
    if ! curl -f "$TEST_URL/nonexistent"; then
        echo "Failed with error $?"
    fi
    
    # Show error
    echo -e "\n2. Show error message:"
    curl -S "$TEST_URL/nonexistent" 2>&1 || true
    
    # Retry on error
    echo -e "\n3. Retry on error:"
    curl --retry 3 "$TEST_URL"
}

# 7. Redirects
# ----------

redirect_handling() {
    echo "Redirect Handling:"
    echo "-----------------"
    
    # Follow redirects
    echo "1. Follow redirects:"
    curl -L "http://github.com"
    
    # Show redirect info
    echo -e "\n2. Show redirect info:"
    curl -L -I "http://github.com"
    
    # Maximum redirects
    echo -e "\n3. Maximum redirects:"
    curl -L --max-redirs 2 "http://github.com"
}

# 8. Practical Examples
# -----------------

# Check website status
check_website() {
    local url="$1"
    echo "Checking website: $url"
    
    local response
    response=$(curl -Is "$url" | head -n 1)
    
    if [[ "$response" == *"200 OK"* ]]; then
        echo "Website is up"
        return 0
    else
        echo "Website might be down: $response"
        return 1
    fi
}

# Download with progress
download_file() {
    local url="$1"
    local output="$2"
    
    echo "Downloading: $url"
    curl -# -L -o "$output" "$url"
}

# Main execution
main() {
    # Run examples
    basic_http_methods
    echo -e "\n"
    header_operations
    echo -e "\n"
    authentication_examples
    echo -e "\n"
    data_handling
    echo -e "\n"
    output_options
    echo -e "\n"
    error_handling
    echo -e "\n"
    redirect_handling
    echo -e "\n"
    
    # Practical examples
    check_website "https://example.com"
    echo -e "\n"
    download_file "https://example.com" "$OUTPUT_DIR/example.html"
    
    # Cleanup
    rm -f "$OUTPUT_DIR/$TEST_FILE"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
