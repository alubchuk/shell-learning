#!/bin/bash

# =============================================================================
# Shell Script Security Examples
# This script demonstrates secure shell scripting practices, including input
# validation, secure file operations, and privilege management.
# =============================================================================

# Enable strict mode with security-focused options
set -euo pipefail
IFS=$'\n\t'

# Ensure secure path
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# -----------------------------------------------------------------------------
# Security Configuration
# -----------------------------------------------------------------------------

# Secure umask (no write for group/others)
umask 077

# Disable core dumps
ulimit -c 0

# Secure temporary directory
readonly SECURE_TMP
SECURE_TMP=$(mktemp -d)
trap 'rm -rf "$SECURE_TMP"' EXIT

# -----------------------------------------------------------------------------
# Input Validation and Sanitization
# -----------------------------------------------------------------------------

# Validate and sanitize file path
sanitize_path() {
    local path=$1
    
    # Remove any null bytes
    path=${path//$'\0'/}
    
    # Convert to absolute path
    path=$(realpath -q "$path" 2>/dev/null || echo "")
    
    # Validate path
    if [ -z "$path" ]; then
        echo "Invalid path" >&2
        return 1
    fi
    
    # Check for directory traversal
    if [[ $path == *".."* ]]; then
        echo "Directory traversal not allowed" >&2
        return 1
    fi
    
    # Check if path is within allowed directory
    local allowed_dir
    allowed_dir=$(realpath "${SECURE_TMP}")
    if [[ $path != "$allowed_dir"* ]]; then
        echo "Path not within allowed directory" >&2
        return 1
    fi
    
    echo "$path"
}

# Validate and sanitize command input
sanitize_command() {
    local cmd=$1
    
    # Remove any null bytes
    cmd=${cmd//$'\0'/}
    
    # Check for shell metacharacters
    if [[ $cmd =~ [;&|><$\`\\] ]]; then
        echo "Invalid characters in command" >&2
        return 1
    fi
    
    # Check against whitelist of allowed commands
    local allowed_commands=(
        "ls"
        "cat"
        "grep"
        "awk"
        "sed"
    )
    
    local command_name
    command_name=$(echo "$cmd" | awk '{print $1}')
    
    if [[ ! " ${allowed_commands[*]} " =~ ${command_name} ]]; then
        echo "Command not allowed: $command_name" >&2
        return 1
    fi
    
    echo "$cmd"
}

# Validate and sanitize string input
sanitize_string() {
    local input=$1
    local max_length=${2:-100}
    
    # Remove any null bytes
    input=${input//$'\0'/}
    
    # Remove any non-printable characters
    input=$(echo "$input" | tr -dc '[:print:]')
    
    # Truncate to maximum length
    input=${input:0:$max_length}
    
    # Escape special characters
    input=$(printf '%q' "$input")
    
    echo "$input"
}

# -----------------------------------------------------------------------------
# Secure File Operations
# -----------------------------------------------------------------------------

# Create secure temporary file
create_secure_temp() {
    local prefix=${1:-temp}
    
    # Create file with secure permissions
    mktemp "${SECURE_TMP}/${prefix}.XXXXXXXXXX"
}

# Write to file securely
secure_write() {
    local file=$1
    local content=$2
    
    # Validate file path
    local safe_path
    safe_path=$(sanitize_path "$file") || return 1
    
    # Create temporary file
    local temp_file
    temp_file=$(create_secure_temp) || return 1
    
    # Write content to temporary file
    echo "$content" > "$temp_file"
    
    # Move temporary file to target (atomic operation)
    mv "$temp_file" "$safe_path"
}

# Read file securely
secure_read() {
    local file=$1
    
    # Validate file path
    local safe_path
    safe_path=$(sanitize_path "$file") || return 1
    
    # Check file permissions
    if [ ! -r "$safe_path" ]; then
        echo "File not readable" >&2
        return 1
    fi
    
    # Read file content
    cat "$safe_path"
}

# -----------------------------------------------------------------------------
# Privilege Management
# -----------------------------------------------------------------------------

# Check if script is running as root
check_root() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Script should not run as root" >&2
        exit 1
    fi
}

# Drop privileges if running as root
drop_privileges() {
    local target_user=${1:-nobody}
    
    if [ "$(id -u)" -eq 0 ]; then
        # Save SUDO_UID if available
        local uid=${SUDO_UID:-65534}  # 65534 is nobody
        local gid=${SUDO_GID:-65534}
        
        # Drop group privileges
        if ! groups="$(id -G "$target_user" 2>/dev/null)"; then
            echo "Failed to get groups for $target_user" >&2
            return 1
        fi
        
        # Set groups first, as we may not be able to after dropping uid
        if ! groupmod "$gid"; then
            echo "Failed to switch to group $gid" >&2
            return 1
        fi
        
        # Drop user privileges
        if ! usermod "$uid"; then
            echo "Failed to switch to user $uid" >&2
            return 1
        fi
    fi
}

# -----------------------------------------------------------------------------
# Secure Command Execution
# -----------------------------------------------------------------------------

# Execute command securely
secure_exec() {
    local cmd=$1
    shift
    local args=("$@")
    
    # Validate command
    local safe_cmd
    safe_cmd=$(sanitize_command "$cmd") || return 1
    
    # Validate arguments
    local safe_args=()
    for arg in "${args[@]}"; do
        local safe_arg
        safe_arg=$(sanitize_string "$arg") || return 1
        safe_args+=("$safe_arg")
    done
    
    # Execute command with timeout
    timeout 30 "$safe_cmd" "${safe_args[@]}"
}

# -----------------------------------------------------------------------------
# Secure Data Handling
# -----------------------------------------------------------------------------

# Encrypt file
encrypt_file() {
    local input=$1
    local output=$2
    local key=$3
    
    # Validate paths
    local safe_input
    safe_input=$(sanitize_path "$input") || return 1
    local safe_output
    safe_output=$(sanitize_path "$output") || return 1
    
    # Create temporary key file
    local key_file
    key_file=$(create_secure_temp "key") || return 1
    echo -n "$key" > "$key_file"
    
    # Encrypt file
    openssl enc -aes-256-cbc -salt \
        -in "$safe_input" \
        -out "$safe_output" \
        -pass file:"$key_file"
    
    # Securely remove key file
    shred -u "$key_file"
}

# Decrypt file
decrypt_file() {
    local input=$1
    local output=$2
    local key=$3
    
    # Validate paths
    local safe_input
    safe_input=$(sanitize_path "$input") || return 1
    local safe_output
    safe_output=$(sanitize_path "$output") || return 1
    
    # Create temporary key file
    local key_file
    key_file=$(create_secure_temp "key") || return 1
    echo -n "$key" > "$key_file"
    
    # Decrypt file
    openssl enc -aes-256-cbc -d \
        -in "$safe_input" \
        -out "$safe_output" \
        -pass file:"$key_file"
    
    # Securely remove key file
    shred -u "$key_file"
}

# -----------------------------------------------------------------------------
# Security Auditing
# -----------------------------------------------------------------------------

# Check file permissions
audit_permissions() {
    local path=$1
    
    # Validate path
    local safe_path
    safe_path=$(sanitize_path "$path") || return 1
    
    # Check owner
    local owner
    owner=$(stat -f "%Su" "$safe_path")
    echo "Owner: $owner"
    
    # Check group
    local group
    group=$(stat -f "%Sg" "$safe_path")
    echo "Group: $group"
    
    # Check permissions
    local perms
    perms=$(stat -f "%Op" "$safe_path")
    echo "Permissions: $perms"
    
    # Check for world-writable
    if [ $((perms & 002)) -ne 0 ]; then
        echo "WARNING: File is world-writable" >&2
    fi
    
    # Check for setuid/setgid
    if [ $((perms & 06000)) -ne 0 ]; then
        echo "WARNING: File has setuid/setgid bits set" >&2
    fi
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    echo "Starting security demonstration..."
    
    # Check if running as root
    check_root
    
    # Example 1: Secure file operations
    echo -e "\n1. Secure file operations:"
    local test_file
    test_file=$(create_secure_temp "test")
    secure_write "$test_file" "Secret data"
    secure_read "$test_file"
    
    # Example 2: Command execution
    echo -e "\n2. Secure command execution:"
    secure_exec "ls" "-l" "$SECURE_TMP"
    
    # Example 3: Data encryption
    echo -e "\n3. Data encryption:"
    local secret="This is sensitive data"
    local enc_file
    enc_file=$(create_secure_temp "encrypted")
    local dec_file
    dec_file=$(create_secure_temp "decrypted")
    local key="secret_key"
    
    echo "$secret" > "${SECURE_TMP}/original"
    encrypt_file "${SECURE_TMP}/original" "$enc_file" "$key"
    decrypt_file "$enc_file" "$dec_file" "$key"
    
    echo "Original:"
    cat "${SECURE_TMP}/original"
    echo "Decrypted:"
    cat "$dec_file"
    
    # Example 4: Security audit
    echo -e "\n4. Security audit:"
    audit_permissions "$test_file"
    
    echo -e "\nSecurity demonstration completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
