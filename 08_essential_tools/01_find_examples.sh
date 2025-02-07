#!/bin/bash

# Find Command Examples
# -------------------
# This script demonstrates various uses of the find command
# for searching and operating on files.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Create test directory structure
setup_test_files() {
    echo "Setting up test files..."
    
    # Create test directory
    mkdir -p test_files/{docs,images,logs}
    
    # Create various file types
    touch test_files/docs/{doc1,doc2,doc3}.txt
    touch test_files/images/{img1,img2}.jpg
    touch test_files/images/{img3,img4}.png
    touch test_files/logs/app_{1..5}.log
    
    # Create files with different timestamps
    touch -t 202301010000 test_files/docs/old_doc.txt
    touch -t $(date +%Y%m%d0000) test_files/docs/new_doc.txt
    
    # Create files with different sizes
    dd if=/dev/zero of=test_files/large_file.dat bs=1M count=10 2>/dev/null
    dd if=/dev/zero of=test_files/small_file.dat bs=1K count=1 2>/dev/null
    
    echo "Test files created."
}

# Clean up test files
cleanup_test_files() {
    echo "Cleaning up test files..."
    rm -rf test_files
}

# 1. Basic Find Examples
# -------------------

find_by_name() {
    echo "Finding files by name:"
    echo "---------------------"
    
    # Find all .txt files
    echo "All .txt files:"
    find test_files -name "*.txt"
    
    # Find case-insensitive
    echo -e "\nAll image files (case-insensitive):"
    find test_files -iname "*.jpg" -o -iname "*.png"
    
    # Find by partial name
    echo -e "\nFiles containing 'doc':"
    find test_files -name "*doc*"
}

# 2. Find by Type
# -------------

find_by_type() {
    echo "Finding by type:"
    echo "---------------"
    
    # Find only files
    echo "Regular files:"
    find test_files -type f
    
    # Find only directories
    echo -e "\nDirectories:"
    find test_files -type d
    
    # Find symbolic links (if any)
    echo -e "\nSymbolic links:"
    find test_files -type l
}

# 3. Find by Time
# -------------

find_by_time() {
    echo "Finding by time:"
    echo "---------------"
    
    # Files modified in the last day
    echo "Modified in last 24 hours:"
    find test_files -mtime -1
    
    # Files accessed in the last hour
    echo -e "\nAccessed in last hour:"
    find test_files -amin -60
    
    # Files modified before certain date
    echo -e "\nFiles modified before 2024:"
    find test_files -type f -newermt "2024-01-01" -ls
}

# 4. Find by Size
# -------------

find_by_size() {
    echo "Finding by size:"
    echo "--------------"
    
    # Files larger than 1MB
    echo "Large files (>1MB):"
    find test_files -size +1M
    
    # Files smaller than 10KB
    echo -e "\nSmall files (<10KB):"
    find test_files -size -10k
    
    # Empty files
    echo -e "\nEmpty files:"
    find test_files -type f -empty
}

# 5. Find with Expressions
# ---------------------

find_with_expressions() {
    echo "Finding with expressions:"
    echo "----------------------"
    
    # Logical AND
    echo "Text files in docs directory:"
    find test_files -type f -path "*/docs/*" -name "*.txt"
    
    # Logical OR
    echo -e "\nLogs or images:"
    find test_files \( -name "*.log" -o -name "*.jpg" \)
    
    # Negation
    echo -e "\nAll files except logs:"
    find test_files -type f ! -name "*.log"
}

# 6. Find with Actions
# -----------------

find_with_actions() {
    echo "Finding with actions:"
    echo "-------------------"
    
    # Execute command on found files
    echo "File details:"
    find test_files -type f -exec ls -lh {} \;
    
    # Count lines in text files
    echo -e "\nLine counts in text files:"
    find test_files -name "*.txt" -exec wc -l {} \;
    
    # Custom formatted output
    echo -e "\nCustom format:"
    find test_files -type f -printf "%p %s bytes\n"
}

# 7. Advanced Find Examples
# ----------------------

find_advanced() {
    echo "Advanced find examples:"
    echo "---------------------"
    
    # Find and process in parallel
    echo "Processing in parallel:"
    find test_files -type f -print0 | xargs -0 -P 4 ls -l
    
    # Find with depth control
    echo -e "\nFiles in depth 2:"
    find test_files -mindepth 2 -maxdepth 2 -type f
    
    # Complex permission and ownership
    echo -e "\nWritable files:"
    find test_files -type f -perm -u=w
}

# 8. Practical Examples
# ------------------

# Find and archive old logs
archive_old_logs() {
    echo "Archiving old logs:"
    echo "-----------------"
    
    find test_files -name "*.log" -mtime +30 -exec tar czf logs_archive.tar.gz {} +
    echo "Old logs archived to logs_archive.tar.gz"
}

# Find and process duplicate files
find_duplicates() {
    echo "Finding duplicate files:"
    echo "----------------------"
    
    find test_files -type f -exec md5sum {} \; | sort | uniq -d -w32
}

# Main execution
main() {
    # Setup test environment
    setup_test_files
    
    # Run examples
    find_by_name
    echo -e "\n"
    find_by_type
    echo -e "\n"
    find_by_time
    echo -e "\n"
    find_by_size
    echo -e "\n"
    find_with_expressions
    echo -e "\n"
    find_with_actions
    echo -e "\n"
    find_advanced
    echo -e "\n"
    archive_old_logs
    echo -e "\n"
    find_duplicates
    
    # Cleanup
    cleanup_test_files
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
