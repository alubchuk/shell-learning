#!/bin/bash

# Diff Command Examples
# -----------------
# This script demonstrates various uses of the diff command
# for comparing files and directories.

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
    # File 1 - Original
    cat > "$TEST_DIR/file1.txt" << 'EOF'
Line 1
Line 2
Line 3
Line 4
Line 5
EOF

    # File 2 - Modified
    cat > "$TEST_DIR/file2.txt" << 'EOF'
Line 1
Line 2 - modified
Line 3
New line
Line 5
EOF

    # Configuration files
    cat > "$TEST_DIR/config1.ini" << 'EOF'
# Database settings
DB_HOST=localhost
DB_PORT=5432
DB_USER=admin

# Server settings
SERVER_PORT=8080
DEBUG=true
EOF

    cat > "$TEST_DIR/config2.ini" << 'EOF'
# Database settings
DB_HOST=127.0.0.1
DB_PORT=5432
DB_USER=admin

# Server settings
SERVER_PORT=9090
DEBUG=false
LOGGING=true
EOF

    # Create directories for comparison
    mkdir -p "$TEST_DIR/dir1" "$TEST_DIR/dir2"
    
    # Dir1 contents
    echo "file A" > "$TEST_DIR/dir1/file_a.txt"
    echo "file B" > "$TEST_DIR/dir1/file_b.txt"
    
    # Dir2 contents
    echo "file A modified" > "$TEST_DIR/dir2/file_a.txt"
    echo "file C" > "$TEST_DIR/dir2/file_c.txt"
}

# 1. Basic Diff Usage
# --------------

basic_diff() {
    echo "Basic Diff Examples:"
    echo "------------------"
    
    # Simple comparison
    echo "1. Simple file comparison:"
    diff "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
    
    # Unified format
    echo -e "\n2. Unified format:"
    diff -u "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
    
    # Side by side
    echo -e "\n3. Side by side comparison:"
    diff -y "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
    
    # Context format
    echo -e "\n4. Context format:"
    diff -c "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
}

# 2. Directory Comparison
# ------------------

directory_diff() {
    echo "Directory Comparison:"
    echo "-------------------"
    
    # Basic directory diff
    echo "1. Basic directory comparison:"
    diff -r "$TEST_DIR/dir1" "$TEST_DIR/dir2"
    
    # Brief report
    echo -e "\n2. Brief report:"
    diff -rq "$TEST_DIR/dir1" "$TEST_DIR/dir2"
    
    # Side by side directory comparison
    echo -e "\n3. Side by side directory comparison:"
    diff -r -y "$TEST_DIR/dir1" "$TEST_DIR/dir2"
}

# 3. Configuration Comparison
# ---------------------

config_diff() {
    echo "Configuration Comparison:"
    echo "-----------------------"
    
    # Compare configs
    echo "1. Configuration differences:"
    diff "$TEST_DIR/config1.ini" "$TEST_DIR/config2.ini"
    
    # Ignore comments and blank lines
    echo -e "\n2. Ignore comments and blank lines:"
    diff -I '^#' -B "$TEST_DIR/config1.ini" "$TEST_DIR/config2.ini"
    
    # Show only changed lines
    echo -e "\n3. Changed lines only:"
    diff --changed-group-format='%>' --unchanged-group-format='' \
        "$TEST_DIR/config1.ini" "$TEST_DIR/config2.ini"
}

# 4. Advanced Diff Features
# -------------------

advanced_diff() {
    echo "Advanced Diff Features:"
    echo "---------------------"
    
    # Ignore whitespace
    echo "1. Ignore whitespace:"
    diff -w "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
    
    # Ignore case
    echo -e "\n2. Ignore case:"
    diff -i "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt"
    
    # Show only additions
    echo -e "\n3. Show only additions:"
    diff "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" |
        grep '^>'
    
    # Show only deletions
    echo -e "\n4. Show only deletions:"
    diff "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" |
        grep '^<'
}

# 5. Practical Examples
# ----------------

# Compare and update configuration
compare_and_update() {
    local source_file="$1"
    local target_file="$2"
    local backup_file="${target_file}.bak"
    
    echo "Comparing and updating configuration:"
    echo "----------------------------------"
    
    # Create backup
    cp "$target_file" "$backup_file"
    
    # Show differences
    echo "Differences found:"
    diff -u "$source_file" "$target_file"
    
    # Update missing entries
    awk 'NR==FNR{a[$0];next} !($0 in a)' "$target_file" "$source_file" |
        tee -a "$target_file"
    
    echo "Configuration updated. Backup saved as $backup_file"
}

# Find and report changes
report_changes() {
    local dir1="$1"
    local dir2="$2"
    local report_file="$3"
    
    echo "Generating change report:"
    echo "----------------------"
    
    {
        echo "=== Change Report ==="
        echo "Date: $(date)"
        echo -e "\n1. Added files:"
        diff -rq "$dir1" "$dir2" | grep "Only in $dir2"
        echo -e "\n2. Removed files:"
        diff -rq "$dir1" "$dir2" | grep "Only in $dir1"
        echo -e "\n3. Modified files:"
        diff -rq "$dir1" "$dir2" | grep "differ"
    } | tee "$report_file"
}

# Create patch file
create_patch() {
    local old_file="$1"
    local new_file="$2"
    local patch_file="$3"
    
    echo "Creating patch file:"
    echo "-----------------"
    
    # Create unified diff patch
    diff -u "$old_file" "$new_file" > "$patch_file"
    
    echo "Patch file created: $patch_file"
    echo "To apply: patch $old_file $patch_file"
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    basic_diff
    echo -e "\n"
    directory_diff
    echo -e "\n"
    config_diff
    echo -e "\n"
    advanced_diff
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Compare and update configs
    compare_and_update "$TEST_DIR/config1.ini" "$TEST_DIR/config2.ini"
    
    # Generate change report
    report_changes "$TEST_DIR/dir1" "$TEST_DIR/dir2" \
        "$OUTPUT_DIR/changes.txt"
    
    # Create patch
    create_patch "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" \
        "$OUTPUT_DIR/changes.patch"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
