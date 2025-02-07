#!/bin/bash

# Advanced curl Examples
# -------------------
# This script demonstrates advanced curl features and
# real-world usage patterns.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly COOKIE_JAR="$OUTPUT_DIR/cookies.txt"
readonly TEST_URL="https://api.github.com"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# 1. Cookie Handling
# ---------------

cookie_operations() {
    echo "Cookie Operations:"
    echo "-----------------"
    
    # Save cookies
    echo "1. Save cookies:"
    curl -c "$COOKIE_JAR" \
         -d "username=testuser&password=testpass" \
         "https://httpbin.org/cookies/set"
    
    # Use saved cookies
    echo -e "\n2. Use saved cookies:"
    curl -b "$COOKIE_JAR" "https://httpbin.org/cookies"
    
    # Set specific cookie
    echo -e "\n3. Set specific cookie:"
    curl -b "session=abc123" "https://httpbin.org/cookies"
    
    # Show cookie details
    echo -e "\n4. Cookie details:"
    cat "$COOKIE_JAR"
}

# 2. SSL/TLS Options
# ---------------

ssl_operations() {
    echo "SSL/TLS Operations:"
    echo "------------------"
    
    # Skip SSL verification (not recommended for production)
    echo "1. Skip SSL verification:"
    curl -k "https://example.com"
    
    # Specify SSL version
    echo -e "\n2. Use TLS 1.2:"
    curl --tlsv1.2 "https://example.com"
    
    # Use client certificate
    echo -e "\n3. Client certificate:"
    # curl --cert client.pem --key client.key "https://example.com"
    echo "Example: curl --cert client.pem --key client.key https://example.com"
    
    # Show SSL certificate
    echo -e "\n4. Show certificate info:"
    curl -vI "https://example.com" 2>&1 | grep "SSL"
}

# 3. Proxy Support
# -------------

proxy_examples() {
    echo "Proxy Examples:"
    echo "--------------"
    
    # HTTP proxy
    echo "1. HTTP proxy:"
    # curl -x proxy:port http://example.com
    echo "Example: curl -x proxy:port http://example.com"
    
    # SOCKS proxy
    echo -e "\n2. SOCKS proxy:"
    # curl --socks5 proxy:port http://example.com
    echo "Example: curl --socks5 proxy:port http://example.com"
    
    # Proxy authentication
    echo -e "\n3. Proxy authentication:"
    # curl -x proxy:port -U user:pass http://example.com
    echo "Example: curl -x proxy:port -U user:pass http://example.com"
}

# 4. Advanced Data Transfer
# ---------------------

advanced_transfer() {
    echo "Advanced Transfer:"
    echo "-----------------"
    
    # Multiple files
    echo "1. Upload multiple files:"
    echo "test1" > "$OUTPUT_DIR/file1.txt"
    echo "test2" > "$OUTPUT_DIR/file2.txt"
    curl -F "file1=@$OUTPUT_DIR/file1.txt" \
         -F "file2=@$OUTPUT_DIR/file2.txt" \
         "https://httpbin.org/post"
    
    # Resume download
    echo -e "\n2. Resume download:"
    curl -C - -o "$OUTPUT_DIR/large_file" "https://example.com/large_file"
    
    # Rate limiting
    echo -e "\n3. Rate limiting:"
    curl --limit-rate 1000B "https://example.com"
    
    # Multiple URLs
    echo -e "\n4. Multiple URLs:"
    curl "https://example.com/{1,2,3}"
}

# 5. Debugging and Tracing
# ---------------------

debug_options() {
    echo "Debugging Options:"
    echo "-----------------"
    
    # Verbose output
    echo "1. Verbose output:"
    curl -v "https://example.com" 2>&1
    
    # Trace HTTP
    echo -e "\n2. Trace HTTP:"
    curl --trace "$OUTPUT_DIR/trace.txt" "https://example.com"
    
    # Trace ASCII
    echo -e "\n3. Trace ASCII:"
    curl --trace-ascii "$OUTPUT_DIR/trace_ascii.txt" "https://example.com"
    
    # Show timing
    echo -e "\n4. Timing data:"
    curl -w "@$OUTPUT_DIR/curl-format.txt" -o /dev/null -s "https://example.com"
}

# 6. API Interaction
# ---------------

api_operations() {
    echo "API Operations:"
    echo "--------------"
    
    # GET with query parameters
    echo "1. GET with parameters:"
    curl -G --data-urlencode "q=test" \
         --data-urlencode "sort=desc" \
         "$TEST_URL/search/repositories"
    
    # POST with JSON
    echo -e "\n2. POST with JSON:"
    curl -H "Content-Type: application/json" \
         -d '{"title":"Test","body":"Content"}' \
         "https://httpbin.org/post"
    
    # PUT with file
    echo -e "\n3. PUT with file:"
    echo '{"data":"update"}' > "$OUTPUT_DIR/update.json"
    curl -X PUT -d "@$OUTPUT_DIR/update.json" \
         "https://httpbin.org/put"
    
    # PATCH request
    echo -e "\n4. PATCH request:"
    curl -X PATCH \
         -H "Content-Type: application/json" \
         -d '{"update":"partial"}' \
         "https://httpbin.org/patch"
}

# 7. Advanced Authentication
# ----------------------

advanced_auth() {
    echo "Advanced Authentication:"
    echo "----------------------"
    
    # OAuth2 token
    echo "1. OAuth2:"
    curl -H "Authorization: Bearer YOUR_TOKEN" \
         "$TEST_URL/user"
    
    # Digest auth
    echo -e "\n2. Digest auth:"
    curl --digest -u "user:pass" \
         "https://httpbin.org/digest-auth/auth/user/pass"
    
    # NTLM auth
    echo -e "\n3. NTLM auth:"
    # curl --ntlm -u "user:pass" "https://example.com"
    echo "Example: curl --ntlm -u user:pass https://example.com"
}

# 8. Practical Examples
# -----------------

# API testing function
test_api_endpoint() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    
    echo "Testing $method $endpoint"
    
    if [ -n "$data" ]; then
        curl -X "$method" \
             -H "Content-Type: application/json" \
             -d "$data" \
             -w "\nStatus: %{http_code}\nTime: %{time_total}s\n" \
             "$endpoint"
    else
        curl -X "$method" \
             -w "\nStatus: %{http_code}\nTime: %{time_total}s\n" \
             "$endpoint"
    fi
}

# Create curl format file
create_curl_format() {
    cat > "$OUTPUT_DIR/curl-format.txt" << 'EOF'
    time_namelookup:  %{time_namelookup}s\n
       time_connect:  %{time_connect}s\n
    time_appconnect:  %{time_appconnect}s\n
   time_pretransfer:  %{time_pretransfer}s\n
      time_redirect:  %{time_redirect}s\n
 time_starttransfer:  %{time_starttransfer}s\n
                    ----------\n
         time_total:  %{time_total}s\n
EOF
}

# Main execution
main() {
    # Create curl format file
    create_curl_format
    
    # Run examples
    cookie_operations
    echo -e "\n"
    ssl_operations
    echo -e "\n"
    proxy_examples
    echo -e "\n"
    advanced_transfer
    echo -e "\n"
    debug_options
    echo -e "\n"
    api_operations
    echo -e "\n"
    advanced_auth
    echo -e "\n"
    
    # Practical example
    test_api_endpoint "GET" "https://api.github.com/zen"
    test_api_endpoint "POST" "https://httpbin.org/post" '{"test":"data"}'
    
    # Cleanup
    rm -f "$OUTPUT_DIR"/{file1.txt,file2.txt,update.json}
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
