#!/bin/bash

# File Operations Examples (touch)
# -----------------------------
# This script demonstrates various uses of the touch command
# for file creation and timestamp manipulation.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Setup test directory
setup_test_dir() {
    echo "Setting up test directory..."
    mkdir -p test_files
    cd test_files || exit 1
}

# Clean up test directory
cleanup_test_dir() {
    echo "Cleaning up..."
    cd ..
    rm -rf test_files
}

# 1. Basic Touch Examples
# --------------------

basic_touch() {
    echo "Basic touch examples:"
    echo "------------------"
    
    # Create a new file
    echo "1. Creating new file:"
    touch new_file.txt
    ls -l new_file.txt
    
    # Create multiple files
    echo -e "\n2. Creating multiple files:"
    touch file1.txt file2.txt file3.txt
    ls -l file*.txt
    
    # Create file in non-existent directory
    echo -e "\n3. Creating file with directory:"
    mkdir -p subdir
    touch subdir/nested_file.txt
    ls -l subdir/nested_file.txt
}

# 2. Timestamp Manipulation
# ----------------------

timestamp_manipulation() {
    echo "Timestamp manipulation:"
    echo "---------------------"
    
    # Set specific access time
    echo "1. Set access time:"
    touch -a -t 202401010000 access_time.txt
    ls -lu access_time.txt
    
    # Set specific modification time
    echo -e "\n2. Set modification time:"
    touch -m -t 202401010000 mod_time.txt
    ls -l mod_time.txt
    
    # Set both times
    echo -e "\n3. Set both times:"
    touch -t 202401010000 both_times.txt
    ls -l both_times.txt
    
    # Use reference file
    echo -e "\n4. Use reference file:"
    touch reference.txt
    sleep 2
    touch new_file.txt
    touch -r reference.txt new_file.txt
    ls -l reference.txt new_file.txt
}

# 3. Advanced Touch Usage
# --------------------

advanced_touch() {
    echo "Advanced touch usage:"
    echo "------------------"
    
    # Don't create new file
    echo "1. Don't create new file:"
    touch -c nonexistent.txt
    ls nonexistent.txt 2>/dev/null || echo "File not created"
    
    # Update timestamp only if file exists
    echo -e "\n2. Update existing file only:"
    touch existing.txt
    touch -c existing.txt
    ls -l existing.txt
    
    # Set future timestamp
    echo -e "\n3. Set future timestamp:"
    touch -t 202512312359 future.txt
    ls -l future.txt
    
    # Set timestamp relative to current time
    echo -e "\n4. Set relative timestamp:"
    touch now.txt
    sleep 2
    touch -d "2 hours ago" past.txt
    ls -l now.txt past.txt
}

# 4. Batch Operations
# ----------------

batch_operations() {
    echo "Batch operations:"
    echo "---------------"
    
    # Create multiple files with pattern
    echo "1. Create files with pattern:"
    touch file_{1..5}.txt
    ls -l file_*.txt
    
    # Update timestamps of multiple files
    echo -e "\n2. Update multiple timestamps:"
    touch -t 202401010000 *.txt
    ls -l *.txt
    
    # Create files in multiple directories
    echo -e "\n3. Create files in multiple directories:"
    mkdir -p dir_{1..3}
    touch dir_{1..3}/file.txt
    ls -R dir_*
    
    # Create files with different extensions
    echo -e "\n4. Create files with different extensions:"
    touch data.{txt,csv,json,xml}
    ls -l data.*
}

# 5. Integration with Find
# ---------------------

find_integration() {
    echo "Integration with find:"
    echo "-------------------"
    
    # Update all file timestamps recursively
    echo "1. Update timestamps recursively:"
    find . -type f -exec touch {} \;
    ls -R
    
    # Update specific file types
    echo -e "\n2. Update specific file types:"
    find . -name "*.txt" -exec touch -t 202401010000 {} \;
    ls -l *.txt
    
    # Update files older than reference
    echo -e "\n3. Update old files:"
    touch reference_time.txt
    sleep 2
    touch old_file.txt
    find . -type f -not -newer reference_time.txt -exec touch {} \;
    ls -l old_file.txt
}

# 6. Practical Examples
# ------------------

# Create directory structure with files
create_project_structure() {
    echo "Creating project structure:"
    echo "------------------------"
    
    # Create directories
    mkdir -p {src,docs,tests}/{main,utils}
    
    # Create files in each directory
    touch src/main/{app,config,utils}.py
    touch docs/main/{readme,api,usage}.md
    touch tests/main/{test_app,test_config,test_utils}.py
    
    # Show structure
    tree .
}

# Update file timestamps for backup
prepare_for_backup() {
    echo "Preparing for backup:"
    echo "------------------"
    
    # Create some files
    touch -t 202301010000 old_file.txt
    touch new_file.txt
    
    # Show before
    echo "Before:"
    ls -l *.txt
    
    # Update old files
    find . -type f -mtime +30 -exec touch {} \;
    
    # Show after
    echo -e "\nAfter:"
    ls -l *.txt
}

# Main execution
main() {
    # Setup
    setup_test_dir
    
    # Run examples
    basic_touch
    echo -e "\n"
    timestamp_manipulation
    echo -e "\n"
    advanced_touch
    echo -e "\n"
    batch_operations
    echo -e "\n"
    find_integration
    echo -e "\n"
    create_project_structure
    echo -e "\n"
    prepare_for_backup
    
    # Cleanup
    cleanup_test_dir
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
