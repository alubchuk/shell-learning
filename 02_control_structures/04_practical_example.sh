#!/bin/bash

# Practical Example: File Management Script
# --------------------------------------
# This script demonstrates a practical use of control structures
# It can:
# 1. List files in a directory
# 2. Search for files
# 3. Create backup of files
# 4. Clean up old backups

# Global variables
BACKUP_DIR="./backups"
MAX_BACKUPS=5

# Function to display usage
show_help() {
    cat << EOF
Usage: $0 [option] [argument]
Options:
    -l, --list    : List files in specified directory
    -s, --search  : Search for files with pattern
    -b, --backup  : Create backup of specified file/directory
    -c, --clean   : Clean old backups
    -h, --help    : Show this help message
EOF
}

# Function to list files in directory
list_files() {
    local dir=${1:-"."}  # Use current directory if none specified
    
    if [ ! -d "$dir" ]; then
        echo "Error: Directory '$dir' does not exist" >&2
        return 1
    fi

    echo "Listing contents of $dir:"
    echo "------------------------"
    
    for item in "$dir"/*; do
        if [ -f "$item" ]; then
            size=$(ls -lh "$item" | awk '{print $5}')
            echo "File: $(basename "$item") (Size: $size)"
        elif [ -d "$item" ]; then
            count=$(ls -A "$item" | wc -l)
            echo "Directory: $(basename "$item") (Items: $count)"
        fi
    done
}

# Function to search for files
search_files() {
    local pattern=$1
    
    if [ -z "$pattern" ]; then
        echo "Error: Search pattern not provided" >&2
        return 1
    }

    echo "Searching for files matching pattern: $pattern"
    echo "-------------------------------------------"
    
    found=false
    while IFS= read -r -d '' file; do
        echo "Found: $file"
        found=true
    done < <(find . -type f -name "*${pattern}*" -print0)

    if [ "$found" = false ]; then
        echo "No files found matching pattern: $pattern"
    fi
}

# Function to create backup
create_backup() {
    local source=$1
    
    if [ -z "$source" ]; then
        echo "Error: Source not specified" >&2
        return 1
    fi

    if [ ! -e "$source" ]; then
        echo "Error: Source '$source' does not exist" >&2
        return 1
    }

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    # Create backup filename with timestamp
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="$(basename "$source")_$timestamp.tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"

    # Create backup
    if tar -czf "$backup_path" "$source" 2>/dev/null; then
        echo "Backup created: $backup_name"
    else
        echo "Error: Backup failed" >&2
        return 1
    fi
}

# Function to clean old backups
clean_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "No backups directory found"
        return 0
    fi

    local backup_count=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    
    if [ $backup_count -eq 0 ]; then
        echo "No backups found"
        return 0
    fi

    if [ $backup_count -gt $MAX_BACKUPS ]; then
        echo "Cleaning old backups..."
        ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +$(($MAX_BACKUPS + 1)) | xargs rm -f
        echo "Cleaned $((backup_count - MAX_BACKUPS)) old backup(s)"
    else
        echo "No cleanup needed (found $backup_count backup(s))"
    fi
}

# Main script logic
case "$1" in
    -l|--list)
        list_files "$2"
        ;;
    -s|--search)
        search_files "$2"
        ;;
    -b|--backup)
        create_backup "$2"
        ;;
    -c|--clean)
        clean_backups
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Error: Invalid option"
        show_help
        exit 1
        ;;
esac
