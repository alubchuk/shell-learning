# Module 14: SSH Examples and Best Practices

This module provides comprehensive examples and best practices for working with SSH (Secure Shell).

## Basic SSH Operations

### Connection Methods
- Basic SSH connection
- Key-based authentication
- Custom SSH configuration
- Connection testing
- Agent forwarding

### Key Management
- Generating SSH keys (RSA, Ed25519)
- Key distribution
- Managing known hosts
- Using ssh-agent
- Key rotation

## SSH Tunneling

### Port Forwarding
1. Local Port Forwarding
   ```bash
   ssh -L local_port:remote_host:remote_port user@ssh_host
   ```
   - Access remote services through local ports
   - Bypass firewalls securely
   - Example: Access remote database locally

2. Remote Port Forwarding
   ```bash
   ssh -R remote_port:local_host:local_port user@ssh_host
   ```
   - Share local services with remote hosts
   - Create reverse tunnels
   - Example: Share development server

3. Dynamic Port Forwarding (SOCKS Proxy)
   ```bash
   ssh -D proxy_port user@ssh_host
   ```
   - Create SOCKS proxy for applications
   - Browse through SSH tunnel
   - Access multiple services

### Advanced Tunneling
1. Jump Hosts
   ```bash
   ssh -J jump_host user@target_host
   ```
   - Multi-hop SSH connections
   - Bastion host configuration
   - ProxyJump configuration

2. VPN-over-SSH
   ```bash
   ssh -w 0:0 user@remote_host
   ```
   - Create TUN/TAP devices
   - Route traffic through SSH
   - Secure network access

## Common Use Cases

### Development
1. Remote Development
   ```bash
   # Forward local editor to remote server
   ssh -L 3000:localhost:3000 user@dev-server
   ```

2. Database Access
   ```bash
   # Access remote database locally
   ssh -L 5432:localhost:5432 user@db-server
   ```

### System Administration
1. Remote Management
   ```bash
   # Secure file copy
   scp -r local_dir user@remote:/path
   
   # Remote command execution
   ssh user@remote 'command'
   ```

2. Monitoring
   ```bash
   # Remote system monitoring
   ssh user@remote 'top -b -n 1'
   ```

### Network Access
1. SOCKS Proxy
   ```bash
   # Create SOCKS proxy
   ssh -D 1080 -q -C -N user@proxy-host
   ```

2. Remote Access
   ```bash
   # Access internal network
   ssh -L 3389:internal-host:3389 user@gateway
   ```

## Advanced Use Cases

### Database Management
```bash
# Persistent database tunnel with monitoring
db_tunnel db.internal 5432 bastion.example.com 15432
```

### Development Workflows
```bash
# Forward all development ports
dev_tunnel dev.example.com

# Git over SSH through custom port
git_over_ssh git@github.com:user/repo.git 443
```

### Load Balancing
```bash
# Forward to multiple backend servers
load_balancer_tunnel lb.example.com web1:80 web2:80 web3:80
```

### Kubernetes Access
```bash
# Forward Kubernetes API and dashboard
k8s_tunnel bastion.example.com k8s-master.internal
```

## Enhanced Security Measures

### Comprehensive Auditing
```bash
# Full security audit
comprehensive_audit

# Check for vulnerable algorithms
ssh -Q cipher | grep -E "arcfour|blowfish|cast128|3des"
```

### Advanced Hardening
```bash
# Generate strong moduli
ssh-keygen -G moduli-2048.candidates -b 2048
ssh-keygen -T moduli-2048 -f moduli-2048.candidates

# Apply enhanced security configuration
harden_server
```

### Two-Factor Authentication
```bash
# Set up Google Authenticator
google-authenticator -t -d -f -r 3 -R 30 -w 3

# Configure PAM and SSH
setup_2fa
```

### Real-time Monitoring
```bash
# Monitor SSH connections
watch_ssh

# Set up monitoring service
setup_monitoring
```

### Intrusion Prevention
```bash
# Block suspicious IPs
if [ $failed_attempts -gt 5 ]; then
    iptables -A INPUT -s $ip -p tcp --dport 22 -j DROP
fi
```

## Security Best Practices

### Configuration Hardening
1. SSH Client Configuration
   ```config
   Host *
       Protocol 2
       HashKnownHosts yes
       StrictHostKeyChecking ask
       VerifyHostKeyDNS yes
   ```

2. SSH Server Configuration
   ```config
   PermitRootLogin no
   PasswordAuthentication no
   PubkeyAuthentication yes
   AuthenticationMethods publickey
   ```

### Security Measures
1. Key Security
   - Use strong key types (Ed25519, RSA 4096)
   - Protect private keys
   - Regular key rotation
   - Proper permissions

2. Access Control
   - Allow/deny lists
   - Rate limiting
   - Fail2ban integration
   - Logging and monitoring

3. Network Security
   - Custom ports
   - Firewall rules
   - Connection timeouts
   - Bastion hosts


## Examples in this Module

1. `01_basic_ssh.sh`: Basic SSH operations
   - Connection examples
   - Key management
   - Configuration templates
   - Testing utilities

2. `02_ssh_tunneling.sh`: SSH tunneling examples
   - Port forwarding
   - SOCKS proxy
   - Jump hosts
   - VPN setup

3. `03_ssh_security.sh`: Security best practices
   - Configuration hardening
   - Security audit
   - Key management
   - Access control

4. `04_advanced_examples.sh`: Advanced use cases
   - Database tunneling with auto-reconnect
   - Git over SSH with custom ports
   - Multi-port forwarding
   - Load balancer tunneling
   - Kubernetes port forwarding
   - Development environment setup
   - Monitoring system tunnels
   - Bandwidth-limited SOCKS proxy

5. `05_enhanced_security.sh`: Enhanced security measures
   - Comprehensive security auditing
   - Advanced server hardening
   - Two-factor authentication setup
   - SSH connection monitoring
   - Intrusion detection
   - Real-time alerts

## Additional Resources

### Documentation
- [OpenSSH Manual](https://www.openssh.com/manual.html)
- [SSH.com Security](https://www.ssh.com/ssh/protocol/)
- [Arch Linux SSH Guide](https://wiki.archlinux.org/index.php/SSH)

### Security Resources
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [SSH Audit Tool](https://github.com/jtesta/ssh-audit)
- [SSH Best Practices](https://www.ssh.com/ssh/best-practices/)
