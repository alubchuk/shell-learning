#!/bin/bash

# =============================================================================
# Shell Script Maintenance Examples
# This script demonstrates best practices for shell script maintenance,
# including code refactoring, dependency management, and code quality tools.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Script Version and Configuration
# -----------------------------------------------------------------------------
readonly VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_FILE="${SCRIPT_DIR}/config.yml"

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

# Check required commands
check_dependencies() {
    local missing_deps=()
    
    # Required system commands
    local required_commands=(
        "awk"
        "sed"
        "grep"
        "curl"
        "jq"
        "shellcheck"
        "yamllint"
    )
    
    # Check each command
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Missing required dependencies:"
        printf '  - %s\n' "${missing_deps[@]}"
        echo
        echo "Install missing dependencies:"
        echo "  brew install ${missing_deps[*]}  # macOS"
        echo "  apt install ${missing_deps[*]}   # Ubuntu/Debian"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Code Quality Tools
# -----------------------------------------------------------------------------

# Run shellcheck on script
run_shellcheck() {
    local script_path=$1
    echo "Running shellcheck on $script_path..."
    
    # Run shellcheck with specific options
    shellcheck \
        --shell=bash \
        --severity=style \
        --color=always \
        --check-sourced \
        --external-sources \
        "$script_path"
}

# Run YAML lint on configuration
run_yamllint() {
    local config_path=$1
    echo "Running yamllint on $config_path..."
    
    # Run yamllint with specific options
    yamllint \
        --strict \
        --format parsable \
        "$config_path"
}

# Check script formatting
check_formatting() {
    local script_path=$1
    echo "Checking formatting of $script_path..."
    
    # Check for consistent indentation
    if grep -P '^ ' "$script_path"; then
        echo "Error: Use tabs for indentation"
        return 1
    fi
    
    # Check for trailing whitespace
    if grep -P '\s$' "$script_path"; then
        echo "Error: Remove trailing whitespace"
        return 1
    fi
    
    # Check for multiple blank lines
    if grep -P '\n\n\n' "$script_path"; then
        echo "Error: Multiple blank lines found"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Code Refactoring Examples
# -----------------------------------------------------------------------------

# Example 1: Extract Configuration
# Before:
#   DATABASE_HOST=localhost
#   DATABASE_PORT=5432
#   DATABASE_NAME=myapp
#
# After:
load_config() {
    local config_file=$1
    
    # Load configuration from YAML
    if [ -f "$config_file" ]; then
        # Parse YAML with yq if available
        if command -v yq >/dev/null 2>&1; then
            DATABASE_HOST=$(yq eval '.database.host' "$config_file")
            DATABASE_PORT=$(yq eval '.database.port' "$config_file")
            DATABASE_NAME=$(yq eval '.database.name' "$config_file")
        else
            # Fallback to grep/sed
            DATABASE_HOST=$(grep 'host:' "$config_file" | sed 's/.*: //')
            DATABASE_PORT=$(grep 'port:' "$config_file" | sed 's/.*: //')
            DATABASE_NAME=$(grep 'name:' "$config_file" | sed 's/.*: //')
        fi
    else
        # Default values
        DATABASE_HOST=${DATABASE_HOST:-localhost}
        DATABASE_PORT=${DATABASE_PORT:-5432}
        DATABASE_NAME=${DATABASE_NAME:-myapp}
    fi
}

# Example 2: Extract Function
# Before:
#   if [ -f "$file" ]; then
#       size=$(stat -f %z "$file")
#       if [ "$size" -gt 1048576 ]; then
#           echo "File too large"
#           exit 1
#       fi
#   fi
#
# After:
validate_file_size() {
    local file=$1
    local max_size=${2:-1048576}  # Default 1MB
    
    if [ ! -f "$file" ]; then
        echo "Error: File not found: $file"
        return 1
    fi
    
    local size
    size=$(stat -f %z "$file")
    
    if [ "$size" -gt "$max_size" ]; then
        echo "Error: File too large: $file ($size bytes > $max_size bytes)"
        return 1
    fi
    
    return 0
}

# Example 3: Improve Error Handling
# Before:
#   mysql -h "$host" -u "$user" -p"$pass" "$db" < "$file"
#
# After:
run_database_query() {
    local host=$1
    local user=$2
    local pass=$3
    local db=$4
    local file=$5
    
    # Validate inputs
    local required_vars=("host" "user" "pass" "db" "file")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            echo "Error: Missing required parameter: $var"
            return 1
        fi
    done
    
    # Validate file
    if [ ! -f "$file" ]; then
        echo "Error: SQL file not found: $file"
        return 1
    fi
    
    # Run query with error handling
    if ! mysql -h "$host" -u "$user" -p"$pass" "$db" < "$file" 2>/tmp/mysql.err; then
        echo "Error executing SQL query:"
        cat /tmp/mysql.err
        rm -f /tmp/mysql.err
        return 1
    fi
    
    rm -f /tmp/mysql.err
    return 0
}

# Example 4: Add Logging
# Before:
#   echo "Starting backup..."
#   tar -czf backup.tar.gz /data
#   echo "Backup complete"
#
# After:
log() {
    local level=$1
    shift
    local message=$*
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Log to file if LOG_FILE is set
    if [ -n "${LOG_FILE:-}" ]; then
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
    
    # Log to console unless QUIET is set
    if [ -z "${QUIET:-}" ]; then
        echo "[$timestamp] [$level] $message"
    fi
}

backup_data() {
    local source_dir=$1
    local backup_file=$2
    
    log "INFO" "Starting backup of $source_dir to $backup_file"
    
    if [ ! -d "$source_dir" ]; then
        log "ERROR" "Source directory not found: $source_dir"
        return 1
    fi
    
    if ! tar -czf "$backup_file" "$source_dir" 2>/tmp/backup.err; then
        log "ERROR" "Backup failed:"
        cat /tmp/backup.err
        rm -f /tmp/backup.err
        return 1
    fi
    
    log "INFO" "Backup completed successfully"
    rm -f /tmp/backup.err
    return 0
}

# Example 5: Improve Performance
# Before:
#   for file in $(ls *.txt); do
#       count=$(wc -l < "$file")
#       echo "$file: $count"
#   done
#
# After:
count_lines() {
    local dir=$1
    local pattern=${2:-"*.txt"}
    
    # Use find instead of ls
    find "$dir" -type f -name "$pattern" -print0 | while IFS= read -r -d '' file; do
        # Use awk instead of wc for better performance
        local count
        count=$(awk 'END {print NR}' "$file")
        echo "$file: $count"
    done
}

# -----------------------------------------------------------------------------
# Maintenance Tools
# -----------------------------------------------------------------------------

# Update script from repository
update_script() {
    local script_url=$1
    local script_path=$2
    
    log "INFO" "Checking for updates..."
    
    # Download new version
    local temp_file
    temp_file=$(mktemp)
    
    if ! curl -sSL "$script_url" -o "$temp_file"; then
        log "ERROR" "Failed to download update"
        rm -f "$temp_file"
        return 1
    fi
    
    # Compare versions
    local current_version
    current_version=$(grep '^readonly VERSION=' "$script_path" | cut -d'"' -f2)
    local new_version
    new_version=$(grep '^readonly VERSION=' "$temp_file" | cut -d'"' -f2)
    
    if [ "$current_version" = "$new_version" ]; then
        log "INFO" "Already at latest version ($current_version)"
        rm -f "$temp_file"
        return 0
    fi
    
    # Backup current script
    cp "$script_path" "${script_path}.bak"
    
    # Install new version
    mv "$temp_file" "$script_path"
    chmod +x "$script_path"
    
    log "INFO" "Updated from version $current_version to $new_version"
    return 0
}

# Clean up old files
cleanup_old_files() {
    local dir=$1
    local pattern=${2:-"*"}
    local days=${3:-30}
    
    log "INFO" "Cleaning up files in $dir older than $days days"
    
    # Find and remove old files
    find "$dir" -type f -name "$pattern" -mtime +"$days" -print0 | while IFS= read -r -d '' file; do
        log "INFO" "Removing old file: $file"
        rm -f "$file"
    done
}

# Archive logs
archive_logs() {
    local log_dir=$1
    local archive_dir=$2
    local days=${3:-7}
    
    log "INFO" "Archiving logs older than $days days"
    
    # Create archive directory
    mkdir -p "$archive_dir"
    
    # Find and archive old logs
    find "$log_dir" -type f -name "*.log" -mtime +"$days" -print0 | while IFS= read -r -d '' file; do
        local archive_file
        archive_file="${archive_dir}/$(basename "$file").$(date +%Y%m%d).gz"
        
        log "INFO" "Archiving $file to $archive_file"
        gzip -c "$file" > "$archive_file"
        rm -f "$file"
    done
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    echo "Starting code maintenance demonstration..."
    
    # Check dependencies
    check_dependencies || exit 1
    
    # Load configuration
    load_config "$CONFIG_FILE"
    
    # Run code quality checks
    run_shellcheck "$0"
    run_yamllint "$CONFIG_FILE"
    check_formatting "$0"
    
    # Demonstrate refactored functions
    validate_file_size "example.txt" 1048576
    backup_data "/tmp/data" "/tmp/backup.tar.gz"
    count_lines "/tmp" "*.log"
    
    # Run maintenance tasks
    cleanup_old_files "/tmp" "*.tmp" 7
    archive_logs "/var/log" "/var/archive" 30
    
    echo "Code maintenance demonstration completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
