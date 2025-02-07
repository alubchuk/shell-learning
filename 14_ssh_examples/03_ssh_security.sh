#!/bin/bash

# SSH Security Best Practices
# -------------------------

# Function to display usage
show_help() {
    cat << EOF
SSH Security Best Practices
Usage: $0 [options]

Options:
    -h, --help              Show this help message
    --audit                 Run SSH security audit
    --harden               Apply security hardening
    --backup               Backup SSH configuration
EOF
}

# Backup SSH configuration
backup_ssh_config() {
    local backup_dir="$HOME/ssh_backup_$(date +%Y%m%d)"
    
    echo "Backing up SSH configuration..."
    mkdir -p "$backup_dir"
    cp -r ~/.ssh "$backup_dir/"
    cp /etc/ssh/sshd_config "$backup_dir/" 2>/dev/null || echo "No sshd_config access"
    
    echo "Backup created in $backup_dir"
}

# Generate secure SSH config
generate_secure_config() {
    cat << EOF > ~/.ssh/config.secure
# Global Options
Host *
    Protocol 2
    HashKnownHosts yes
    IdentitiesOnly yes
    ServerAliveInterval 300
    ServerAliveCountMax 2
    ConnectTimeout 10
    StrictHostKeyChecking ask
    VerifyHostKeyDNS yes
    ForwardAgent no
    ForwardX11 no

# Example Host-specific Configuration
Host example
    HostName example.com
    User username
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    PasswordAuthentication no
    PubkeyAuthentication yes
EOF
    echo "Secure SSH config template created at ~/.ssh/config.secure"
}

# Generate secure sshd config (for servers)
generate_secure_sshd_config() {
    cat << EOF > ./sshd_config.secure
# Security Settings
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
AuthenticationMethods publickey

# Access Control
AllowUsers user1 user2
AllowGroups ssh-users
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30

# Network Settings
Port 22
AddressFamily inet
ListenAddress 0.0.0.0

# Cryptography Settings
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Features
X11Forwarding no
AllowTcpForwarding yes
GatewayPorts no
PermitTunnel no
PrintMotd no
EOF
    echo "Secure SSHd config template created at ./sshd_config.secure"
}

# Audit SSH security
audit_ssh_security() {
    echo "Performing SSH security audit..."
    
    # Check SSH client config
    echo "1. Checking SSH client configuration:"
    [ -f ~/.ssh/config ] && grep -E "Protocol|StrictHostKeyChecking|HashKnownHosts" ~/.ssh/config
    
    # Check SSH keys
    echo -e "\n2. Checking SSH keys:"
    for key in ~/.ssh/id_*; do
        if [ -f "$key" ]; then
            echo "Key: $key"
            if [[ "$key" != *.pub ]]; then
                ls -l "$key" | grep -E "^-[r,w]{2}-------"
                if [ $? -ne 0 ]; then
                    echo "WARNING: Key file has incorrect permissions"
                fi
            fi
        fi
    done
    
    # Check known_hosts file
    echo -e "\n3. Checking known_hosts:"
    [ -f ~/.ssh/known_hosts ] && ls -l ~/.ssh/known_hosts
    
    # Check for authorized_keys
    echo -e "\n4. Checking authorized_keys:"
    [ -f ~/.ssh/authorized_keys ] && ls -l ~/.ssh/authorized_keys
    
    # Check SSH agent
    echo -e "\n5. Checking SSH agent:"
    ssh-add -l 2>/dev/null || echo "No SSH agent running"
}

# Apply SSH security hardening
apply_security_hardening() {
    echo "Applying SSH security hardening..."
    
    # Fix permissions
    chmod 700 ~/.ssh
    chmod 600 ~/.ssh/config 2>/dev/null
    chmod 600 ~/.ssh/authorized_keys 2>/dev/null
    chmod 600 ~/.ssh/known_hosts 2>/dev/null
    find ~/.ssh -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
    find ~/.ssh -name "*.pub" -exec chmod 644 {} \;
    
    # Generate secure configs
    generate_secure_config
    generate_secure_sshd_config
    
    echo "Security hardening complete"
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --help|-h)
            show_help
            ;;
        --audit)
            audit_ssh_security
            ;;
        --harden)
            apply_security_hardening
            ;;
        --backup)
            backup_ssh_config
            ;;
        *)
            echo "Use --help for usage information"
            ;;
    esac
fi
