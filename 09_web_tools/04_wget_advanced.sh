#!/bin/bash

# Advanced wget Examples
# -------------------
# This script demonstrates advanced wget features for
# website mirroring, recursive downloads, and automation.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_URL="https://example.com"
readonly MIRROR_DIR="$OUTPUT_DIR/mirror"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$MIRROR_DIR" "$LOG_DIR"

# 1. Website Mirroring
# -----------------

website_mirror() {
    echo "Website Mirroring:"
    echo "-----------------"
    
    # Basic mirror
    echo "1. Basic website mirror:"
    wget --mirror \
         --convert-links \
         --no-parent \
         -P "$MIRROR_DIR/basic" \
         "$TEST_URL"
    
    # Complete mirror with all options
    echo -e "\n2. Complete mirror:"
    wget --mirror \
         --convert-links \
         --adjust-extension \
         --page-requisites \
         --no-parent \
         -P "$MIRROR_DIR/complete" \
         "$TEST_URL"
    
    # Mirror with depth limit
    echo -e "\n3. Mirror with depth limit:"
    wget --mirror \
         --level=2 \
         --convert-links \
         -P "$MIRROR_DIR/depth_limited" \
         "$TEST_URL"
    
    # Mirror specific content
    echo -e "\n4. Mirror specific content:"
    wget --mirror \
         --accept jpg,jpeg,png,gif \
         --convert-links \
         -P "$MIRROR_DIR/images" \
         "$TEST_URL"
}

# 2. Recursive Downloads
# ------------------

recursive_downloads() {
    echo "Recursive Downloads:"
    echo "-------------------"
    
    # Basic recursive
    echo "1. Basic recursive download:"
    wget -r -P "$OUTPUT_DIR/recursive" "$TEST_URL"
    
    # Recursive with regex
    echo -e "\n2. Recursive with regex:"
    wget -r \
         --accept-regex ".*\.(pdf|doc)$" \
         -P "$OUTPUT_DIR/documents" \
         "$TEST_URL"
    
    # Spanning hosts
    echo -e "\n3. Recursive spanning hosts:"
    wget -r -H \
         --domains=example.com,example.org \
         -P "$OUTPUT_DIR/multi_domain" \
         "$TEST_URL"
    
    # Time-based recursive
    echo -e "\n4. Time-based recursive:"
    wget -r \
         --level=1 \
         -N \
         -P "$OUTPUT_DIR/updated" \
         "$TEST_URL"
}

# 3. Spider Mode
# -----------

spider_operations() {
    echo "Spider Operations:"
    echo "-----------------"
    
    # Check broken links
    echo "1. Check broken links:"
    wget --spider -r "$TEST_URL" 2>&1 | \
        grep -B2 '404' > "$LOG_DIR/broken_links.log"
    
    # List all URLs
    echo -e "\n2. List all URLs:"
    wget --spider -r "$TEST_URL" 2>&1 | \
        grep '^--' | awk '{ print $3 }' > "$LOG_DIR/all_urls.log"
    
    # Check site structure
    echo -e "\n3. Check site structure:"
    wget --spider -r \
         --no-verbose \
         "$TEST_URL" 2>&1 | \
        grep -i 'http' > "$LOG_DIR/site_structure.log"
}

# 4. Advanced Filtering
# -----------------

advanced_filtering() {
    echo "Advanced Filtering:"
    echo "------------------"
    
    # Include/exclude patterns
    echo "1. Include/exclude patterns:"
    wget -r \
         --include-directories="images,css" \
         --exclude-directories="js,temp" \
         -P "$OUTPUT_DIR/filtered" \
         "$TEST_URL"
    
    # Complex regex
    echo -e "\n2. Complex regex patterns:"
    wget -r \
         --accept-regex ".*\.(jpg|png)" \
         --reject-regex "thumb|small" \
         -P "$OUTPUT_DIR/regex_filtered" \
         "$TEST_URL"
    
    # Time window
    echo -e "\n3. Time window filtering:"
    wget -r \
         --no-parent \
         -N \
         --cut-dirs=1 \
         -P "$OUTPUT_DIR/recent" \
         "$TEST_URL"
}

# 5. Advanced Options
# ---------------

advanced_options() {
    echo "Advanced Options:"
    echo "----------------"
    
    # Custom output template
    echo "1. Custom output template:"
    wget -r \
         --no-parent \
         -nd \
         -A jpg,jpeg \
         --content-disposition \
         -P "$OUTPUT_DIR/custom" \
         "$TEST_URL"
    
    # Random wait
    echo -e "\n2. Random wait between requests:"
    wget -r \
         --random-wait \
         --wait=1 \
         -P "$OUTPUT_DIR/throttled" \
         "$TEST_URL"
    
    # Custom logging
    echo -e "\n3. Custom logging format:"
    wget -r \
         --no-verbose \
         --output-file="$LOG_DIR/custom.log" \
         -P "$OUTPUT_DIR/logged" \
         "$TEST_URL"
}

# 6. Batch Processing
# ---------------

batch_processing() {
    echo "Batch Processing:"
    echo "----------------"
    
    # Create URL list
    echo "$TEST_URL/page1" > "$OUTPUT_DIR/urls.txt"
    echo "$TEST_URL/page2" >> "$OUTPUT_DIR/urls.txt"
    
    # Process URL list
    echo "1. Process URL list:"
    wget -i "$OUTPUT_DIR/urls.txt" \
         -P "$OUTPUT_DIR/batch"
    
    # Parallel downloads
    echo -e "\n2. Parallel downloads:"
    cat "$OUTPUT_DIR/urls.txt" | \
        parallel --jobs 3 wget -P "$OUTPUT_DIR/parallel" {}
    
    # Batch with quotas
    echo -e "\n3. Batch with quotas:"
    wget -i "$OUTPUT_DIR/urls.txt" \
         --quota=1m \
         -P "$OUTPUT_DIR/quota"
}

# 7. Site Backup
# -----------

site_backup() {
    echo "Site Backup:"
    echo "------------"
    
    local backup_dir="$OUTPUT_DIR/backup/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    # Full site backup
    echo "1. Full site backup:"
    wget --mirror \
         --convert-links \
         --backup-converted \
         --html-extension \
         --restrict-file-names=windows \
         -P "$backup_dir" \
         "$TEST_URL"
    
    # Create archive
    echo -e "\n2. Create backup archive:"
    tar -czf "$backup_dir.tar.gz" -C "$OUTPUT_DIR/backup" "$(basename "$backup_dir")"
}

# 8. Practical Examples
# -----------------

# Website availability checker
check_website_availability() {
    local url="$1"
    local log_file="$LOG_DIR/availability.log"
    
    echo "Checking availability: $url"
    if wget --spider --timeout=10 "$url" 2>&1; then
        echo "$(date): $url is available" >> "$log_file"
        return 0
    else
        echo "$(date): $url is not available" >> "$log_file"
        return 1
    fi
}

# Incremental site backup
incremental_backup() {
    local url="$1"
    local backup_dir="$2"
    
    echo "Running incremental backup of $url"
    wget --mirror \
         --no-parent \
         -N \
         -P "$backup_dir" \
         "$url"
}

# Main execution
main() {
    # Run examples
    website_mirror
    echo -e "\n"
    recursive_downloads
    echo -e "\n"
    spider_operations
    echo -e "\n"
    advanced_filtering
    echo -e "\n"
    advanced_options
    echo -e "\n"
    batch_processing
    echo -e "\n"
    site_backup
    echo -e "\n"
    
    # Practical examples
    check_website_availability "$TEST_URL"
    incremental_backup "$TEST_URL" "$OUTPUT_DIR/incremental"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
