#!/bin/bash

# =============================================================================
# Security Audit Examples
# This script demonstrates security auditing techniques, including system
# configuration checks, compliance testing, and security reporting.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# Ensure secure path
PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Report settings
readonly REPORT_DIR="/var/log/security/audit"
readonly HTML_REPORT="${REPORT_DIR}/audit_report.html"
readonly JSON_REPORT="${REPORT_DIR}/audit_report.json"

# Compliance standards
readonly CIS_LEVEL=2  # CIS Benchmark level (1 or 2)
readonly PCI_DSS=true # Enable PCI DSS checks

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------

# Initialize audit
init_audit() {
    # Create report directory
    mkdir -p "$REPORT_DIR"
    
    # Initialize JSON report
    cat > "$JSON_REPORT" << EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "hostname": "$(hostname)",
    "os": "$(uname -s)",
    "os_version": "$(uname -r)",
    "checks": []
}
EOF
}

# Add check result to JSON report
add_check_result() {
    local category=$1
    local check=$2
    local result=$3
    local details=$4
    local severity=${5:-high}
    
    local json_entry
    json_entry=$(jq -n \
        --arg category "$category" \
        --arg check "$check" \
        --arg result "$result" \
        --arg details "$details" \
        --arg severity "$severity" \
        '{category: $category, check: $check, result: $result, details: $details, severity: $severity}')
    
    # Append to checks array
    jq --arg entry "$json_entry" '.checks += [$entry|fromjson]' "$JSON_REPORT" > "${JSON_REPORT}.tmp"
    mv "${JSON_REPORT}.tmp" "$JSON_REPORT"
}

# Generate HTML report
generate_html_report() {
    # Convert JSON to HTML using jq and HTML template
    {
        cat << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Security Audit Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 20px; background: #f5f5f5; }
        .check { margin: 10px 0; padding: 10px; border: 1px solid #ddd; }
        .pass { border-left: 5px solid #4CAF50; }
        .fail { border-left: 5px solid #f44336; }
        .warning { border-left: 5px solid #ff9800; }
        .severity-high { color: #f44336; }
        .severity-medium { color: #ff9800; }
        .severity-low { color: #4CAF50; }
    </style>
</head>
<body>
EOF
        
        # Add report header
        jq -r '"<h1>Security Audit Report</h1>
        <div class=\"summary\">
            <p>Timestamp: \(.timestamp)</p>
            <p>Hostname: \(.hostname)</p>
            <p>OS: \(.os) \(.os_version)</p>
        </div>
        <h2>Audit Results</h2>
        <div class=\"results\">"' "$JSON_REPORT"
        
        # Add check results
        jq -r '.checks[] | "<div class=\"check \(.result)\">
            <h3>\(.category): \(.check)</h3>
            <p>Result: <strong>\(.result)</strong></p>
            <p>Severity: <span class=\"severity-\(.severity)\">\(.severity)</span></p>
            <pre>\(.details)</pre>
        </div>"' "$JSON_REPORT"
        
        # Add report footer
        cat << 'EOF'
        </div>
    </body>
</html>
EOF
    } > "$HTML_REPORT"
}

# -----------------------------------------------------------------------------
# System Configuration Checks
# -----------------------------------------------------------------------------

# Check file permissions
check_file_permissions() {
    echo "Checking file permissions..."
    
    local critical_files=(
        "/etc/passwd:644"
        "/etc/shadow:600"
        "/etc/group:644"
        "/etc/gshadow:600"
        "/etc/ssh/sshd_config:600"
        "/etc/hosts:644"
    )
    
    local results=""
    for entry in "${critical_files[@]}"; do
        local file=${entry%:*}
        local expected=${entry#*:}
        
        if [ -f "$file" ]; then
            local actual
            actual=$(stat -f "%Lp" "$file")
            
            if [ "$actual" != "$expected" ]; then
                results+="$file: Expected $expected, got $actual\n"
            fi
        else
            results+="$file: File not found\n"
        fi
    done
    
    if [ -n "$results" ]; then
        add_check_result "File System" "Critical File Permissions" "fail" "$results"
    else
        add_check_result "File System" "Critical File Permissions" "pass" "All files have correct permissions"
    fi
}

# Check system accounts
check_system_accounts() {
    echo "Checking system accounts..."
    
    local results=""
    
    # Check for empty passwords
    local empty_pass
    empty_pass=$(awk -F: '($2 == "") {print}' /etc/shadow)
    if [ -n "$empty_pass" ]; then
        results+="Accounts with empty passwords found:\n$empty_pass\n"
    fi
    
    # Check for UID 0 accounts
    local root_accounts
    root_accounts=$(awk -F: '($3 == 0) {print}' /etc/passwd)
    if [ "$(echo "$root_accounts" | wc -l)" -gt 1 ]; then
        results+="Multiple UID 0 accounts found:\n$root_accounts\n"
    fi
    
    if [ -n "$results" ]; then
        add_check_result "Authentication" "System Accounts" "fail" "$results"
    else
        add_check_result "Authentication" "System Accounts" "pass" "No issues found"
    fi
}

# Check network configuration
check_network_config() {
    echo "Checking network configuration..."
    
    local results=""
    
    # Check open ports
    local open_ports
    open_ports=$(netstat -an | grep LISTEN)
    results+="Open ports:\n$open_ports\n\n"
    
    # Check firewall status
    if ! pfctl -sa >/dev/null 2>&1; then
        results+="Firewall is not enabled\n"
    fi
    
    # Check SSH configuration
    if [ -f "/etc/ssh/sshd_config" ]; then
        local ssh_config
        ssh_config=$(grep -E '^(PermitRootLogin|PasswordAuthentication|Protocol)' /etc/ssh/sshd_config)
        results+="SSH Configuration:\n$ssh_config\n"
    fi
    
    add_check_result "Network" "Network Configuration" "info" "$results"
}

# -----------------------------------------------------------------------------
# Compliance Checks
# -----------------------------------------------------------------------------

# Check CIS compliance
check_cis_compliance() {
    echo "Checking CIS compliance..."
    
    local results=""
    
    if [ "$CIS_LEVEL" -ge 1 ]; then
        # Level 1 checks
        results+="=== CIS Level 1 Checks ===\n"
        
        # Check filesystem configuration
        if mount | grep -E '\s/tmp\s' | grep -q 'noexec'; then
            results+="✓ /tmp mounted with noexec\n"
        else
            results+="✗ /tmp should be mounted with noexec\n"
        fi
        
        # Check system file permissions
        if [ "$(stat -f "%Lp" /etc/passwd)" = "644" ]; then
            results+="✓ /etc/passwd has correct permissions\n"
        else
            results+="✗ /etc/passwd has incorrect permissions\n"
        fi
    fi
    
    if [ "$CIS_LEVEL" -ge 2 ]; then
        # Level 2 checks
        results+="\n=== CIS Level 2 Checks ===\n"
        
        # Check password policies
        local pass_max_days
        pass_max_days=$(pwpolicy -getglobalpolicy | grep maxMinutesUntilChangePassword)
        if [ -n "$pass_max_days" ]; then
            results+="✓ Password expiration policy configured\n"
        else
            results+="✗ Password expiration policy not configured\n"
        fi
        
        # Check audit logging
        if [ -f "/etc/security/audit_control" ]; then
            results+="✓ Audit logging configured\n"
        else
            results+="✗ Audit logging not configured\n"
        fi
    fi
    
    add_check_result "Compliance" "CIS Benchmark" "info" "$results"
}

# Check PCI DSS compliance
check_pci_compliance() {
    if [ "$PCI_DSS" = true ]; then
        echo "Checking PCI DSS compliance..."
        
        local results=""
        
        # Requirement 2: Do not use vendor-supplied defaults
        results+="=== PCI DSS Requirement 2 ===\n"
        if grep -q '^PermitRootLogin' /etc/ssh/sshd_config; then
            results+="✓ SSH root login configuration present\n"
        else
            results+="✗ SSH root login not configured\n"
        fi
        
        # Requirement 7: Restrict access
        results+="\n=== PCI DSS Requirement 7 ===\n"
        if [ -f "/etc/sudoers" ]; then
            results+="✓ Sudo configuration present\n"
            results+="$(grep -v '^#' /etc/sudoers | grep -v '^$')\n"
        else
            results+="✗ Sudo not configured\n"
        fi
        
        # Requirement 10: Track and monitor access
        results+="\n=== PCI DSS Requirement 10 ===\n"
        if [ -d "/var/log/audit" ]; then
            results+="✓ Audit logging enabled\n"
        else
            results+="✗ Audit logging not configured\n"
        fi
        
        add_check_result "Compliance" "PCI DSS" "info" "$results"
    fi
}

# -----------------------------------------------------------------------------
# Security Testing
# -----------------------------------------------------------------------------

# Check for common vulnerabilities
check_vulnerabilities() {
    echo "Checking for vulnerabilities..."
    
    local results=""
    
    # Check for world-writable files
    results+="World-writable files:\n"
    results+="$(find / -type f -perm -0002 -ls 2>/dev/null)\n\n"
    
    # Check for SUID/SGID files
    results+="SUID/SGID files:\n"
    results+="$(find / -type f \( -perm -4000 -o -perm -2000 \) -ls 2>/dev/null)\n\n"
    
    # Check for unowned files
    results+="Unowned files:\n"
    results+="$(find / -nouser -o -nogroup -ls 2>/dev/null)\n"
    
    add_check_result "Security" "Vulnerability Scan" "info" "$results"
}

# Check system integrity
check_system_integrity() {
    echo "Checking system integrity..."
    
    local results=""
    
    # Check running processes
    results+="Running processes:\n"
    results+="$(ps aux)\n\n"
    
    # Check loaded kernel modules
    results+="Loaded kernel modules:\n"
    results+="$(kextstat)\n\n"
    
    # Check startup items
    results+="Startup items:\n"
    results+="$(ls -la /Library/StartupItems /System/Library/StartupItems 2>/dev/null)\n"
    
    add_check_result "Security" "System Integrity" "info" "$results"
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    # Check if running as root
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root" >&2
        exit 1
    fi
    
    echo "Starting security audit..."
    
    # Initialize audit
    init_audit
    
    # System configuration checks
    check_file_permissions
    check_system_accounts
    check_network_config
    
    # Compliance checks
    check_cis_compliance
    check_pci_compliance
    
    # Security testing
    check_vulnerabilities
    check_system_integrity
    
    # Generate reports
    generate_html_report
    
    echo "Security audit completed. Reports available in $REPORT_DIR"
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
