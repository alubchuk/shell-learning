#!/bin/bash

# Enhanced SSH Security Measures
# ----------------------------

# Function to display usage
show_help() {
    cat << EOF
Enhanced SSH Security Measures
Usage: $0 [options]

Options:
    -h, --help              Show this help message
    --full-audit           Run comprehensive security audit
    --harden-server        Apply server hardening
    --setup-2fa            Set up two-factor authentication
    --monitor              Set up SSH monitoring
EOF
}

# Comprehensive security audit
comprehensive_audit() {
    echo "Running comprehensive SSH security audit..."
    
    # Check SSH version
    echo "1. SSH Version:"
    ssh -V 2>&1
    
    # Check for vulnerable algorithms
    echo -e "\n2. Checking for vulnerable algorithms:"
    ssh -Q cipher | grep -E "arcfour|blowfish|cast128|3des"
    ssh -Q mac | grep -E "md5|ripemd"
    ssh -Q kex | grep -E "diffie-hellman-group1|diffie-hellman-group14"
    
    # Check SSH configuration
    echo -e "\n3. Checking SSH configuration:"
    grep -E "^[^#]" /etc/ssh/sshd_config 2>/dev/null || echo "No access to sshd_config"
    
    # Check for authorized keys
    echo -e "\n4. Checking authorized keys:"
    find /home -name "authorized_keys" -type f -exec ls -l {} \;
    
    # Check SSH agent
    echo -e "\n5. Checking SSH agent configuration:"
    env | grep SSH
    
    # Check for unusual SSH processes
    echo -e "\n6. Checking SSH processes:"
    ps aux | grep -i ssh
    
    # Check SSH logs
    echo -e "\n7. Recent SSH login attempts:"
    grep "sshd" /var/log/auth.log 2>/dev/null | tail -n 10
    
    # Check for known_hosts issues
    echo -e "\n8. Checking known_hosts:"
    find /home -name "known_hosts" -type f -exec ssh-keygen -l -f {} \;
    
    # Check for SSH port status
    echo -e "\n9. Checking SSH port status:"
    netstat -tuln | grep ":22"
}

# Enhanced server hardening
harden_server() {
    echo "Applying enhanced SSH server hardening..."
    
    # Create backup
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Generate strong moduli
    ssh-keygen -G moduli-2048.candidates -b 2048
    ssh-keygen -T moduli-2048 -f moduli-2048.candidates
    mv moduli-2048 /etc/ssh/moduli
    
    # Configure enhanced security settings
    cat << EOF > /etc/ssh/sshd_config.enhanced
# Enhanced Security Configuration

# Protocol and Cipher Settings
Protocol 2
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Authentication
PermitRootLogin no
MaxAuthTries 3
MaxSessions 2
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
AuthenticationMethods publickey

# Access Control
AllowUsers user1 user2
AllowGroups ssh-users
DenyUsers root admin
DenyGroups wheel

# Network
Port 22222
AddressFamily inet
ListenAddress 0.0.0.0
TCPKeepAlive no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxStartups 10:30:60
LoginGraceTime 30

# Features
X11Forwarding no
AllowTcpForwarding local
GatewayPorts no
PermitTunnel no
PermitUserEnvironment no
AllowAgentForwarding no
PrintMotd no
PrintLastLog yes
Banner /etc/ssh/banner

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Chroot
ChrootDirectory /home/%u
ForceCommand internal-sftp

# Security
StrictModes yes
Compression no
EOF
    
    echo "Enhanced configuration created at /etc/ssh/sshd_config.enhanced"
}

# Set up two-factor authentication
setup_2fa() {
    echo "Setting up two-factor authentication..."
    
    # Install required packages
    apt-get install -y libpam-google-authenticator
    
    # Configure PAM
    echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
    
    # Update SSH config
    sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/' /etc/ssh/sshd_config
    echo "AuthenticationMethods publickey,keyboard-interactive" >> /etc/ssh/sshd_config
    
    # Generate 2FA tokens
    google-authenticator -t -d -f -r 3 -R 30 -w 3
}

# Set up SSH monitoring
setup_monitoring() {
    echo "Setting up SSH monitoring..."
    
    # Create monitoring script
    cat << 'EOF' > /usr/local/bin/monitor_ssh.sh
#!/bin/bash

# Monitor SSH connections
watch_ssh() {
    while true; do
        # Monitor active connections
        netstat -tnpa | grep 'ESTABLISHED.*sshd' > /var/log/ssh_connections.log
        
        # Monitor failed attempts
        grep "Failed password" /var/log/auth.log | \
            awk '{print $11}' | sort | uniq -c | \
            sort -nr > /var/log/ssh_failures.log
        
        # Monitor successful logins
        grep "Accepted" /var/log/auth.log | \
            awk '{print $9,$11}' > /var/log/ssh_success.log
        
        # Check for unusual activity
        if grep -q "Failed password" /var/log/auth.log; then
            ip=$(grep "Failed password" /var/log/auth.log | tail -1 | awk '{print $11}')
            count=$(grep "$ip" /var/log/auth.log | wc -l)
            if [ $count -gt 5 ]; then
                echo "Warning: Multiple failed attempts from $ip" | \
                    logger -t ssh-monitor
                iptables -A INPUT -s $ip -p tcp --dport 22 -j DROP
            fi
        fi
        
        sleep 60
    done
}

# Start monitoring
watch_ssh &
EOF
    
    chmod +x /usr/local/bin/monitor_ssh.sh
    
    # Create systemd service
    cat << EOF > /etc/systemd/system/ssh-monitor.service
[Unit]
Description=SSH Monitoring Service
After=network.target

[Service]
ExecStart=/usr/local/bin/monitor_ssh.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    
    # Start monitoring service
    systemctl enable ssh-monitor
    systemctl start ssh-monitor
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --help|-h)
            show_help
            ;;
        --full-audit)
            comprehensive_audit
            ;;
        --harden-server)
            harden_server
            ;;
        --setup-2fa)
            setup_2fa
            ;;
        --monitor)
            setup_monitoring
            ;;
        *)
            echo "Use --help for usage information"
            ;;
    esac
fi
