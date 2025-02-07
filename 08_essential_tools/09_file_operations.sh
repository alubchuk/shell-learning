#!/bin/bash

# File Operations Commands
# --------------------
# This script demonstrates the usage of ls, mkdir,
# cp, mv, and related file operations.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_DIR="$OUTPUT_DIR/test_files"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$TEST_DIR"

# 1. Directory Creation
# -----------------

mkdir_examples() {
    echo "Mkdir Examples:"
    echo "--------------"
    
    # Basic directory creation
    echo "1. Create single directory:"
    mkdir -p "$TEST_DIR/dir1"
    ls -ld "$TEST_DIR/dir1"
    
    # Create multiple directories
    echo -e "\n2. Create multiple directories:"
    mkdir -p "$TEST_DIR/dir2" "$TEST_DIR/dir3"
    ls -ld "$TEST_DIR/dir2" "$TEST_DIR/dir3"
    
    # Create nested directories
    echo -e "\n3. Create nested directories:"
    mkdir -p "$TEST_DIR/parent/child/grandchild"
    ls -R "$TEST_DIR/parent"
    
    # Create with specific permissions
    echo -e "\n4. Create with permissions:"
    mkdir -m 755 "$TEST_DIR/secured_dir"
    ls -ld "$TEST_DIR/secured_dir"
}

# 2. Directory Listing
# ----------------

ls_examples() {
    echo "Ls Examples:"
    echo "------------"
    
    # Create test files
    touch "$TEST_DIR/file1.txt"
    touch "$TEST_DIR/file2.txt"
    touch "$TEST_DIR/.hidden"
    chmod 600 "$TEST_DIR/file1.txt"
    
    # Basic listing
    echo "1. Basic listing:"
    ls "$TEST_DIR"
    
    # Long format
    echo -e "\n2. Long format:"
    ls -l "$TEST_DIR"
    
    # Show hidden files
    echo -e "\n3. Show hidden files:"
    ls -la "$TEST_DIR"
    
    # Sort by time
    echo -e "\n4. Sort by time:"
    ls -lt "$TEST_DIR"
    
    # Recursive listing
    echo -e "\n5. Recursive listing:"
    ls -R "$TEST_DIR"
    
    # Human readable sizes
    echo -e "\n6. Human readable sizes:"
    ls -lh "$TEST_DIR"
}

# 3. File Organization
# ----------------

organize_files() {
    local base_dir="$1"
    
    echo "Organizing files in: $base_dir"
    
    # Create organization directories
    mkdir -p "$base_dir"/{documents,images,scripts}
    
    # Create test files
    touch "$base_dir/doc1.txt"
    touch "$base_dir/doc2.pdf"
    touch "$base_dir/image1.jpg"
    touch "$base_dir/script1.sh"
    
    # Move files to appropriate directories
    mv "$base_dir"/*.txt "$base_dir"/*.pdf "$base_dir/documents/"
    mv "$base_dir"/*.jpg "$base_dir"/*.png 2>/dev/null "$base_dir/images/" || true
    mv "$base_dir"/*.sh "$base_dir/scripts/"
    
    # Show results
    echo -e "\nOrganized directory structure:"
    ls -R "$base_dir"
}

# 4. Advanced Listing
# ---------------

advanced_listing() {
    echo "Advanced Listing Examples:"
    echo "------------------------"
    
    # Create test files with different timestamps
    for i in {1..5}; do
        echo "Content $i" > "$TEST_DIR/file$i.txt"
        touch -t "202502070$i"0000 "$TEST_DIR/file$i.txt"
    done
    
    # List by size
    echo "1. Sort by size:"
    ls -lS "$TEST_DIR"
    
    # List by time, reversed
    echo -e "\n2. Sort by time (newest first):"
    ls -ltr "$TEST_DIR"
    
    # Custom format
    echo -e "\n3. Custom format:"
    ls -l --time-style="+%Y-%m-%d %H:%M" "$TEST_DIR"
    
    # Find files by pattern
    echo -e "\n4. Pattern matching:"
    ls -l "$TEST_DIR"/file[1-3].txt
}

# 5. Directory Operations
# -------------------

directory_operations() {
    echo "Directory Operations:"
    echo "--------------------"
    
    # Create test structure
    mkdir -p "$TEST_DIR/project"/{src,docs,tests}
    touch "$TEST_DIR/project/src/main.sh"
    touch "$TEST_DIR/project/docs/readme.md"
    touch "$TEST_DIR/project/tests/test_main.sh"
    
    # List directory tree
    echo "1. Directory tree:"
    ls -R "$TEST_DIR/project"
    
    # Count files
    echo -e "\n2. File count:"
    ls -1 "$TEST_DIR/project" | wc -l
    
    # Find empty directories
    echo -e "\n3. Empty directories:"
    find "$TEST_DIR/project" -type d -empty
    
    # Show directory sizes
    echo -e "\n4. Directory sizes:"
    du -sh "$TEST_DIR/project"/*
}

# 6. Practical Examples
# ----------------

# Create project structure
create_project() {
    local project_name="$1"
    local base_dir="$2"
    
    echo "Creating project: $project_name"
    
    # Create directory structure
    mkdir -p "$base_dir/$project_name"/{src,tests,docs,config,data}
    
    # Create initial files
    touch "$base_dir/$project_name/src/main.sh"
    touch "$base_dir/$project_name/tests/test_main.sh"
    touch "$base_dir/$project_name/docs/README.md"
    touch "$base_dir/$project_name/config/settings.conf"
    
    # Set permissions
    chmod 755 "$base_dir/$project_name/src"/*.sh
    chmod 644 "$base_dir/$project_name/config"/*.conf
    
    echo "Project structure created:"
    ls -R "$base_dir/$project_name"
}

# Backup directory
backup_directory() {
    local source_dir="$1"
    local backup_dir="$2"
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    
    echo "Creating backup of $source_dir"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Create backup
    cp -R "$source_dir" "$backup_dir/backup_$timestamp"
    
    echo "Backup created: $backup_dir/backup_$timestamp"
    ls -lh "$backup_dir"
}

# Clean directory
clean_directory() {
    local target_dir="$1"
    local pattern="${2:-*.tmp}"
    
    echo "Cleaning directory: $target_dir"
    echo "Pattern: $pattern"
    
    # Find and remove matching files
    find "$target_dir" -name "$pattern" -type f -print -delete
    
    echo "Directory cleaned"
    ls -la "$target_dir"
}

# Main execution
main() {
    # Run examples
    mkdir_examples
    echo -e "\n"
    ls_examples
    echo -e "\n"
    organize_files "$TEST_DIR/organized"
    echo -e "\n"
    advanced_listing
    echo -e "\n"
    directory_operations
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Create project
    create_project "test_project" "$TEST_DIR"
    
    # Create backup
    backup_directory "$TEST_DIR/test_project" "$TEST_DIR/backups"
    
    # Clean temporary files
    touch "$TEST_DIR/file1.tmp" "$TEST_DIR/file2.tmp"
    clean_directory "$TEST_DIR" "*.tmp"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
