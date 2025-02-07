#!/bin/bash

# Basic wget Examples
# ----------------
# This script demonstrates basic usage of wget for
# downloading files and websites.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_URL="https://example.com"
readonly TEST_FILE="test.txt"

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# 1. Basic Downloads
# ---------------

basic_downloads() {
    echo "Basic Downloads:"
    echo "---------------"
    
    # Simple download
    echo "1. Download single file:"
    wget -q "$TEST_URL" -O "$OUTPUT_DIR/index.html"
    
    # Download with original filename
    echo "2. Download keeping original filename:"
    cd "$OUTPUT_DIR" && wget -q "$TEST_URL"
    
    # Download with progress bar
    echo "3. Download with progress bar:"
    wget --progress=bar "$TEST_URL" -O "$OUTPUT_DIR/progress_test.html"
    
    # Download multiple files
    echo "4. Download multiple files:"
    wget -q "$TEST_URL/file1" "$TEST_URL/file2" -P "$OUTPUT_DIR"
}

# 2. Output Options
# --------------

output_options() {
    echo "Output Options:"
    echo "--------------"
    
    # Quiet mode
    echo "1. Quiet mode:"
    wget -q "$TEST_URL" -O "$OUTPUT_DIR/quiet.html"
    
    # Debug mode
    echo "2. Debug mode:"
    wget -d "$TEST_URL" -O "$OUTPUT_DIR/debug.html"
    
    # Save output log
    echo "3. Save output log:"
    wget -o "$OUTPUT_DIR/wget.log" "$TEST_URL"
    
    # Append to log
    echo "4. Append to log:"
    wget -a "$OUTPUT_DIR/wget.log" "$TEST_URL"
}

# 3. Authentication
# --------------

authentication_examples() {
    echo "Authentication Examples:"
    echo "----------------------"
    
    # Basic auth
    echo "1. Basic authentication:"
    wget --user=username --password=password \
         "https://example.com/protected"
    
    # Use .netrc file
    echo "2. Using .netrc file:"
    echo "machine example.com login myuser password mypass" > "$OUTPUT_DIR/.netrc"
    chmod 600 "$OUTPUT_DIR/.netrc"
    wget --netrc-file="$OUTPUT_DIR/.netrc" "https://example.com/protected"
    
    # HTTP auth
    echo "3. HTTP authentication:"
    wget --http-user=username --http-password=password \
         "https://example.com/protected"
}

# 4. Download Control
# ---------------

download_control() {
    echo "Download Control:"
    echo "----------------"
    
    # Limit rate
    echo "1. Limit download rate:"
    wget --limit-rate=100k "$TEST_URL"
    
    # Continue interrupted download
    echo "2. Continue download:"
    wget -c "$TEST_URL"
    
    # Retry on failure
    echo "3. Retry on failure:"
    wget --tries=3 --retry-connrefused "$TEST_URL"
    
    # Timeout settings
    echo "4. Timeout settings:"
    wget --timeout=10 --dns-timeout=5 --connect-timeout=5 "$TEST_URL"
}

# 5. File Handling
# -------------

file_handling() {
    echo "File Handling:"
    echo "--------------"
    
    # Timestamping
    echo "1. Use timestamping:"
    wget -N "$TEST_URL"
    
    # Don't overwrite
    echo "2. Don't overwrite existing files:"
    wget -nc "$TEST_URL"
    
    # Backup existing
    echo "3. Backup existing files:"
    wget --backup-converted "$TEST_URL"
    
    # Specify output directory
    echo "4. Save to specific directory:"
    wget -P "$OUTPUT_DIR" "$TEST_URL"
}

# 6. URL Handling
# ------------

url_handling() {
    echo "URL Handling:"
    echo "-------------"
    
    # Follow FTP links
    echo "1. Follow FTP links:"
    wget --follow-ftp "$TEST_URL"
    
    # Ignore SSL
    echo "2. Ignore SSL certificate:"
    wget --no-check-certificate "$TEST_URL"
    
    # Use specific SSL cert
    echo "3. Use specific SSL certificate:"
    # wget --certificate=cert.pem "$TEST_URL"
    echo "Example: wget --certificate=cert.pem $TEST_URL"
    
    # Handle redirects
    echo "4. Follow redirects:"
    wget --max-redirect=5 "$TEST_URL"
}

# 7. Headers and Cookies
# ------------------

header_handling() {
    echo "Header and Cookie Handling:"
    echo "-------------------------"
    
    # Custom headers
    echo "1. Add custom headers:"
    wget --header="User-Agent: CustomScript/1.0" "$TEST_URL"
    
    # Save cookies
    echo "2. Save cookies:"
    wget --save-cookies "$OUTPUT_DIR/cookies.txt" \
         --keep-session-cookies \
         "$TEST_URL"
    
    # Load cookies
    echo "3. Load cookies:"
    wget --load-cookies "$OUTPUT_DIR/cookies.txt" "$TEST_URL"
    
    # Post data
    echo "4. POST request:"
    wget --post-data="name=value" "$TEST_URL"
}

# 8. Practical Examples
# -----------------

# Download with retry
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_retries=3
    
    echo "Downloading $url"
    wget --tries="$max_retries" \
         --retry-connrefused \
         --waitretry=1 \
         --output-document="$output" \
         "$url"
}

# Check if file exists before download
smart_download() {
    local url="$1"
    local output="$2"
    
    if [ -f "$output" ]; then
        echo "File exists, checking if newer version available..."
        wget -N -P "$(dirname "$output")" "$url"
    else
        echo "Downloading new file..."
        wget -P "$(dirname "$output")" "$url"
    fi
}

# Main execution
main() {
    # Run examples
    basic_downloads
    echo -e "\n"
    output_options
    echo -e "\n"
    authentication_examples
    echo -e "\n"
    download_control
    echo -e "\n"
    file_handling
    echo -e "\n"
    url_handling
    echo -e "\n"
    header_handling
    echo -e "\n"
    
    # Practical examples
    download_with_retry "$TEST_URL" "$OUTPUT_DIR/retry_test.html"
    smart_download "$TEST_URL" "$OUTPUT_DIR/smart_test.html"
    
    # Cleanup
    rm -f "$OUTPUT_DIR"/{.netrc,cookies.txt}
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
