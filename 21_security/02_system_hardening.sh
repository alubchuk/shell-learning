#!/bin/bash

# =============================================================================
# System Hardening Examples
# This script demonstrates system hardening techniques, including file system
# security, network security, and system monitoring.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# Ensure secure path
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# System paths
readonly SYSCTL_CONF="/etc/sysctl.conf"
readonly SSH_CONFIG="/etc/ssh/sshd_config"
readonly HOSTS_ALLOW="/etc/hosts.allow"
readonly HOSTS_DENY="/etc/hosts.deny"
readonly FIREWALL_RULES="/etc/pf.conf"

# Backup directory
readonly BACKUP_DIR="/var/backups/hardening"

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Log message with timestamp
log() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Backup file before modification
backup_file() {
    local file=$1
    local backup="${BACKUP_DIR}/$(basename "$file").$(date +%Y%m%d_%H%M%S)"
    
    mkdir -p "$BACKUP_DIR"
    cp -p "$file" "$backup"
    log "INFO" "Created backup: $backup"
}

# Verify file permissions
verify_permissions() {
    local file=$1
    local expected_perms=$2
    local expected_owner=${3:-root}
    local expected_group=${4:-root}
    
    local actual_perms
    actual_perms=$(stat -f "%Lp" "$file")
    local actual_owner
    actual_owner=$(stat -f "%Su" "$file")
    local actual_group
    actual_group=$(stat -f "%Sg" "$file")
    
    if [ "$actual_perms" != "$expected_perms" ] || \
       [ "$actual_owner" != "$expected_owner" ] || \
       [ "$actual_group" != "$expected_group" ]; then
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# File System Security
# -----------------------------------------------------------------------------

# Secure file permissions
secure_file_permissions() {
    log "INFO" "Securing file permissions..."
    
    # Secure system files
    chmod 644 /etc/passwd
    chmod 000 /etc/shadow
    chmod 644 /etc/group
    chmod 600 /etc/gshadow
    chmod 644 /etc/hosts
    chmod 600 /etc/ssh/*_key
    chmod 644 /etc/ssh/*.pub
    
    # Secure user home directories
    find /home -maxdepth 1 -type d -exec chmod 750 {} \;
    
    # Remove world-writable files
    find / -type f -perm -0002 -exec chmod o-w {} \;
    
    # Remove unowned files
    find / -nouser -o -nogroup -exec chown root:root {} \;
}

# Secure mount points
secure_mount_points() {
    log "INFO" "Securing mount points..."
    
    # Add noexec,nosuid,nodev options to temporary filesystems
    local mounts=(
        "/tmp"
        "/var/tmp"
        "/dev/shm"
    )
    
    for mount in "${mounts[@]}"; do
        if mountpoint -q "$mount"; then
            mount -o remount,noexec,nosuid,nodev "$mount"
        fi
    done
}

# -----------------------------------------------------------------------------
# Network Security
# -----------------------------------------------------------------------------

# Configure system network parameters
configure_network_security() {
    log "INFO" "Configuring network security..."
    
    # Backup sysctl.conf
    backup_file "$SYSCTL_CONF"
    
    # Network security settings
    cat >> "$SYSCTL_CONF" << EOF
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Disable IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
EOF
    
    # Apply settings
    sysctl -p
}

# Configure SSH security
configure_ssh_security() {
    log "INFO" "Configuring SSH security..."
    
    # Backup SSH config
    backup_file "$SSH_CONFIG"
    
    # SSH security settings
    cat > "$SSH_CONFIG" << EOF
# SSH Security Configuration
Protocol 2
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxStartups 10:30:60
LoginGraceTime 60
TCPKeepAlive yes
AllowTcpForwarding no
AllowAgentForwarding no
UseDNS no
EOF
    
    # Restart SSH service
    service sshd restart
}

# Configure TCP Wrappers
configure_tcp_wrappers() {
    log "INFO" "Configuring TCP Wrappers..."
    
    # Backup hosts.allow and hosts.deny
    backup_file "$HOSTS_ALLOW"
    backup_file "$HOSTS_DENY"
    
    # Allow only specific hosts
    echo "sshd: 192.168.1.0/24" > "$HOSTS_ALLOW"
    
    # Deny all other connections
    echo "ALL: ALL" > "$HOSTS_DENY"
}

# Configure firewall rules
configure_firewall() {
    log "INFO" "Configuring firewall rules..."
    
    # Backup firewall rules
    backup_file "$FIREWALL_RULES"
    
    # Basic PF firewall rules
    cat > "$FIREWALL_RULES" << EOF
# Macros
ext_if = "en0"
tcp_services = "{ ssh, http, https }"
udp_services = "{ domain }"
trusted_nets = "{ 192.168.1.0/24 }"

# Options
set block-policy drop
set fingerprints "/etc/pf.os"
set skip on lo0

# Normalization
scrub in all

# Queueing
queue on $ext_if bandwidth 100M max 100M

# Translation (NAT)
nat on $ext_if from !($ext_if) -> ($ext_if:0)

# Filtering
block in all
pass out quick modulate state

# Allow trusted networks
pass in quick from $trusted_nets to any keep state

# Allow specific services
pass in on $ext_if proto tcp to any port $tcp_services keep state
pass in on $ext_if proto udp to any port $udp_services keep state
EOF
    
    # Load firewall rules
    pfctl -f "$FIREWALL_RULES"
}

# -----------------------------------------------------------------------------
# System Monitoring
# -----------------------------------------------------------------------------

# Configure system auditing
configure_auditing() {
    log "INFO" "Configuring system auditing..."
    
    # Enable process accounting
    accton on
    
    # Configure auditd
    if [ -f "/etc/audit/auditd.conf" ]; then
        backup_file "/etc/audit/auditd.conf"
        
        cat > "/etc/audit/auditd.conf" << EOF
log_file = /var/log/audit/audit.log
log_format = RAW
log_group = root
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
num_logs = 5
disp_qos = lossy
dispatcher = /sbin/audispd
name_format = NONE
max_log_file = 8
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
EOF
        
        service auditd restart
    fi
}

# Configure system logging
configure_logging() {
    log "INFO" "Configuring system logging..."
    
    # Configure syslog
    if [ -f "/etc/syslog.conf" ]; then
        backup_file "/etc/syslog.conf"
        
        cat >> "/etc/syslog.conf" << EOF
# Send auth messages to secure log
auth,authpriv.*                 /var/log/secure

# Log all kernel messages
kern.*                         /var/log/kernel.log

# Log all mail messages
mail.*                         /var/log/maillog

# Log cron jobs
cron.*                         /var/log/cron

# Save boot messages
local7.*                       /var/log/boot.log
EOF
        
        # Restart syslog
        service syslog restart
    fi
}

# -----------------------------------------------------------------------------
# System Hardening
# -----------------------------------------------------------------------------

# Disable unnecessary services
disable_services() {
    log "INFO" "Disabling unnecessary services..."
    
    local services=(
        "telnet"
        "rsh"
        "rlogin"
        "rexec"
        "tftp"
        "talk"
        "ntalk"
    )
    
    for service in "${services[@]}"; do
        if launchctl list | grep -q "$service"; then
            launchctl disable "$service"
        fi
    done
}

# Configure password policies
configure_password_policy() {
    log "INFO" "Configuring password policies..."
    
    # Set password complexity requirements
    pwpolicy -setglobalpolicy "minChars=12 requiresAlpha=1 requiresNumeric=1 maxMinutesUntilChangePassword=129600"
}

# Secure user accounts
secure_user_accounts() {
    log "INFO" "Securing user accounts..."
    
    # Lock system accounts
    for user in daemon bin sys sync games man lp mail news uucp proxy www-data backup list irc gnats nobody; do
        passwd -l "$user" 2>/dev/null || true
    done
    
    # Set root account expiry
    passwd -x 90 -n 7 -w 7 root
}

# -----------------------------------------------------------------------------
# Security Verification
# -----------------------------------------------------------------------------

# Verify system security
verify_security() {
    log "INFO" "Verifying system security..."
    
    # Check file permissions
    verify_permissions "/etc/passwd" "644" || log "WARN" "Incorrect permissions on /etc/passwd"
    verify_permissions "/etc/shadow" "000" || log "WARN" "Incorrect permissions on /etc/shadow"
    verify_permissions "/etc/ssh/sshd_config" "600" || log "WARN" "Incorrect permissions on sshd_config"
    
    # Check running services
    log "INFO" "Checking running services:"
    launchctl list
    
    # Check open ports
    log "INFO" "Checking open ports:"
    netstat -an | grep LISTEN
    
    # Check system logs
    log "INFO" "Checking system logs for errors:"
    tail -n 100 /var/log/system.log | grep -i error
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR" "This script must be run as root"
        exit 1
    fi
    
    log "INFO" "Starting system hardening..."
    
    # File system security
    secure_file_permissions
    secure_mount_points
    
    # Network security
    configure_network_security
    configure_ssh_security
    configure_tcp_wrappers
    configure_firewall
    
    # System monitoring
    configure_auditing
    configure_logging
    
    # System hardening
    disable_services
    configure_password_policy
    secure_user_accounts
    
    # Verify security
    verify_security
    
    log "INFO" "System hardening completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
