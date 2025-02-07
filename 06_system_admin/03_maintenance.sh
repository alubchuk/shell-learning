#!/bin/bash

# System Maintenance Tool
# ---------------------
# This script provides various system maintenance tasks including
# user management, package updates, and security checks.

# Configuration
CONFIG_DIR="${HOME}/.config/sysmaint"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
LOG_FILE="${CONFIG_DIR}/maintenance.log"
SECURITY_SCAN_DIR="${CONFIG_DIR}/security"

# Ensure required directories exist
mkdir -p "$CONFIG_DIR" "$SECURITY_SCAN_DIR"

# Create default configuration if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# System Maintenance Configuration

# User management settings
MIN_UID=1000
MAX_UID=60000
PASSWORD_MAX_AGE=90
PASSWORD_MIN_LENGTH=12

# Package management
AUTO_UPDATE=true
UPDATE_SCHEDULE="weekly"
REBOOT_AFTER_KERNEL_UPDATE=false

# Security settings
SCAN_DIRECTORIES="/etc /usr/local/bin /usr/bin"
FILE_PERMISSION_CHECK=true
SECURITY_AUDIT_ENABLED=true

# Cleanup settings
TEMP_FILE_AGE=7  # days
LOG_ROTATION_AGE=30  # days
DISK_SPACE_THRESHOLD=90  # percentage
EOF
fi

# Source configuration
source "$CONFIG_FILE"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo "[$level] $message"
}

# Error handling function
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# User Management Functions
# -----------------------

check_user_password_age() {
    log "INFO" "Checking password age for all users..."
    
    while IFS=: read -r username _ uid _ _ _ _; do
        if [ "$uid" -ge "$MIN_UID" ] && [ "$uid" -le "$MAX_UID" ]; then
            local age=$(passwd -S "$username" 2>/dev/null | awk '{print $3}')
            if [ -n "$age" ] && [ "$age" -gt "$PASSWORD_MAX_AGE" ]; then
                log "WARNING" "Password for user $username is $age days old"
            fi
        fi
    done < /etc/passwd
}

check_user_password_strength() {
    log "INFO" "Checking password strength requirements..."
    
    # Check password configuration
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log "INFO" "Password policy on macOS is managed via Directory Services"
    else
        if [ -f "/etc/security/pwquality.conf" ]; then
            local minlen=$(grep "^minlen" /etc/security/pwquality.conf | awk '{print $3}')
            if [ -n "$minlen" ] && [ "$minlen" -lt "$PASSWORD_MIN_LENGTH" ]; then
                log "WARNING" "Password minimum length ($minlen) is less than recommended ($PASSWORD_MIN_LENGTH)"
            fi
        fi
    fi
}

audit_user_accounts() {
    log "INFO" "Auditing user accounts..."
    
    # Check for users with empty passwords
    local empty_pass=$(awk -F: '($2 == "" ) { print $1 }' /etc/shadow 2>/dev/null)
    if [ -n "$empty_pass" ]; then
        log "ERROR" "Users with empty passwords found: $empty_pass"
    fi
    
    # Check for duplicate UIDs
    local duplicate_uids=$(cut -d: -f3 /etc/passwd | sort -n | uniq -d)
    if [ -n "$duplicate_uids" ]; then
        log "ERROR" "Duplicate UIDs found: $duplicate_uids"
    fi
    
    # Check for duplicate GIDs
    local duplicate_gids=$(cut -d: -f3 /etc/group | sort -n | uniq -d)
    if [ -n "$duplicate_gids" ]; then
        log "ERROR" "Duplicate GIDs found: $duplicate_gids"
    fi
}

# Package Management Functions
# --------------------------

update_system_packages() {
    log "INFO" "Updating system packages..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS updates
        if command -v brew >/dev/null; then
            log "INFO" "Updating Homebrew packages..."
            brew update && brew upgrade
        fi
        
        # Check for system updates
        log "INFO" "Checking for macOS system updates..."
        softwareupdate -l
    else
        # Linux updates
        if command -v apt-get >/dev/null; then
            log "INFO" "Updating APT packages..."
            apt-get update && apt-get -y upgrade
        elif command -v dnf >/dev/null; then
            log "INFO" "Updating DNF packages..."
            dnf -y update
        elif command -v yum >/dev/null; then
            log "INFO" "Updating YUM packages..."
            yum -y update
        fi
    fi
}

check_package_vulnerabilities() {
    log "INFO" "Checking for package vulnerabilities..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew >/dev/null; then
            log "INFO" "Checking Homebrew packages..."
            brew audit
        fi
    else
        if command -v apt-get >/dev/null && command -v debsecan >/dev/null; then
            log "INFO" "Checking for vulnerable packages..."
            debsecan
        fi
    fi
}

# Security Functions
# ----------------

check_file_permissions() {
    log "INFO" "Checking file permissions..."
    
    for dir in $SCAN_DIRECTORIES; do
        if [ -d "$dir" ]; then
            # Find world-writable files
            log "INFO" "Checking for world-writable files in $dir..."
            find "$dir" -type f -perm -0002 -ls 2>/dev/null | while read -r line; do
                log "WARNING" "World-writable file found: $line"
            done
            
            # Find SUID/SGID files
            log "INFO" "Checking for SUID/SGID files in $dir..."
            find "$dir" -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null | while read -r line; do
                log "INFO" "SUID/SGID file found: $line"
            done
        fi
    done
}

perform_security_audit() {
    log "INFO" "Performing security audit..."
    
    # Check SSH configuration
    if [ -f "/etc/ssh/sshd_config" ]; then
        log "INFO" "Checking SSH configuration..."
        
        # Check root login setting
        if grep -q "^PermitRootLogin yes" "/etc/ssh/sshd_config"; then
            log "WARNING" "Root login is permitted via SSH"
        fi
        
        # Check password authentication
        if grep -q "^PasswordAuthentication yes" "/etc/ssh/sshd_config"; then
            log "WARNING" "Password authentication is enabled via SSH"
        fi
    fi
    
    # Check firewall status
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q "enabled"; then
            log "WARNING" "macOS firewall is disabled"
        fi
    else
        if command -v ufw >/dev/null; then
            if ! ufw status | grep -q "active"; then
                log "WARNING" "UFW firewall is not active"
            fi
        fi
    fi
    
    # Check system integrity
    if [[ "$OSTYPE" == "darwin"* ]]; then
        log "INFO" "Checking System Integrity Protection status..."
        if ! csrutil status | grep -q "enabled"; then
            log "WARNING" "System Integrity Protection is disabled"
        fi
    fi
}

# System Cleanup Functions
# ----------------------

cleanup_temp_files() {
    log "INFO" "Cleaning up temporary files..."
    
    # Clean system temporary directories
    if [[ "$OSTYPE" == "darwin"* ]]; then
        find /tmp -type f -atime +"$TEMP_FILE_AGE" -delete 2>/dev/null
        find /var/tmp -type f -atime +"$TEMP_FILE_AGE" -delete 2>/dev/null
    else
        find /tmp -type f -atime +"$TEMP_FILE_AGE" -delete 2>/dev/null
        find /var/tmp -type f -atime +"$TEMP_FILE_AGE" -delete 2>/dev/null
    fi
    
    # Clean user cache
    if [ -d "$HOME/Library/Caches" ]; then
        find "$HOME/Library/Caches" -type f -atime +"$TEMP_FILE_AGE" -delete 2>/dev/null
    fi
}

rotate_logs() {
    log "INFO" "Rotating log files..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [ -d "/var/log" ]; then
            find "/var/log" -name "*.log" -type f -mtime +"$LOG_ROTATION_AGE" -exec rm {} \;
        fi
    else
        if command -v logrotate >/dev/null; then
            logrotate -f /etc/logrotate.conf
        fi
    fi
}

check_disk_space() {
    log "INFO" "Checking disk space..."
    
    local df_cmd="df -h"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        df_cmd="df -h"
    fi
    
    $df_cmd | awk -v threshold="$DISK_SPACE_THRESHOLD" '
    NR>1 {
        gsub(/%/,"",$5)
        if ($5 > threshold) {
            print "WARNING: Partition " $6 " is " $5 "% full"
        }
    }'
}

# Main Functions
# -------------

perform_full_maintenance() {
    log "INFO" "Starting full system maintenance..."
    
    # User management
    check_user_password_age
    check_user_password_strength
    audit_user_accounts
    
    # Package management
    if [ "$AUTO_UPDATE" = true ]; then
        update_system_packages
        check_package_vulnerabilities
    fi
    
    # Security checks
    if [ "$SECURITY_AUDIT_ENABLED" = true ]; then
        perform_security_audit
    fi
    if [ "$FILE_PERMISSION_CHECK" = true ]; then
        check_file_permissions
    fi
    
    # System cleanup
    cleanup_temp_files
    rotate_logs
    check_disk_space
    
    log "INFO" "System maintenance completed"
}

# Show help
show_help() {
    cat << EOF
System Maintenance Tool
Usage: $0 <command> [options]

Commands:
    full                Perform full system maintenance
    users               Perform user management tasks
    packages            Update system packages
    security           Perform security checks
    cleanup            Perform system cleanup
    help               Show this help message

Options:
    -v, --verbose      Enable verbose output
    -f, --force        Force operations without prompting
    --no-update        Skip package updates
    --no-security     Skip security checks

Example:
    $0 full
    $0 security --verbose
EOF
}

# Parse command line arguments
case "${1:-}" in
    full)
        perform_full_maintenance
        ;;
    users)
        check_user_password_age
        check_user_password_strength
        audit_user_accounts
        ;;
    packages)
        update_system_packages
        check_package_vulnerabilities
        ;;
    security)
        perform_security_audit
        check_file_permissions
        ;;
    cleanup)
        cleanup_temp_files
        rotate_logs
        check_disk_space
        ;;
    help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
