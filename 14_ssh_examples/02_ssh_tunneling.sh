#!/bin/bash

# SSH Tunneling Examples
# --------------------

# Function to display usage
show_help() {
    cat << EOF
SSH Tunneling Examples
Usage: $0 [options]

Options:
    -h, --help              Show this help message
    -u, --user USER         Remote username
    -h, --host HOST         Remote hostname
    --local-port PORT       Local port for forwarding
    --remote-port PORT      Remote port for forwarding
    --proxy-port PORT       Port for SOCKS proxy

Examples:
    # Local port forwarding
    $0 --user john --host example.com --local-port 8080 --remote-port 80

    # Remote port forwarding
    $0 --user john --host example.com --local-port 3000 --remote-port 3000

    # Dynamic SOCKS proxy
    $0 --user john --host example.com --proxy-port 1080
EOF
}

# Local port forwarding
# Forward local port to remote server
local_port_forward() {
    local user="$1"
    local host="$2"
    local local_port="$3"
    local remote_port="$4"
    
    echo "Setting up local port forwarding..."
    echo "Local port $local_port -> Remote port $remote_port"
    ssh -L "$local_port:localhost:$remote_port" "$user@$host"
}

# Remote port forwarding
# Forward remote port to local machine
remote_port_forward() {
    local user="$1"
    local host="$2"
    local local_port="$3"
    local remote_port="$4"
    
    echo "Setting up remote port forwarding..."
    echo "Remote port $remote_port -> Local port $local_port"
    ssh -R "$remote_port:localhost:$local_port" "$user@$host"
}

# Dynamic port forwarding (SOCKS proxy)
create_socks_proxy() {
    local user="$1"
    local host="$2"
    local proxy_port="$3"
    
    echo "Creating SOCKS proxy on port $proxy_port..."
    ssh -D "$proxy_port" -C -q -N "$user@$host"
}

# Jump host configuration
use_jump_host() {
    local jump_user="$1"
    local jump_host="$2"
    local target_user="$3"
    local target_host="$4"
    
    echo "Connecting through jump host..."
    ssh -J "$jump_user@$jump_host" "$target_user@$target_host"
}

# Multi-hop SSH tunnel
create_multi_hop_tunnel() {
    local proxy_port="$1"
    local host1="$2"
    local host2="$3"
    local host3="$4"
    
    echo "Creating multi-hop tunnel..."
    ssh -L "$proxy_port:localhost:$proxy_port" "$host1" ssh -L "$proxy_port:localhost:$proxy_port" "$host2" ssh -D "$proxy_port" "$host3"
}

# X11 forwarding
enable_x11_forwarding() {
    local user="$1"
    local host="$2"
    
    echo "Enabling X11 forwarding..."
    ssh -X "$user@$host"
}

# Agent forwarding
enable_agent_forwarding() {
    local user="$1"
    local host="$2"
    
    echo "Enabling SSH agent forwarding..."
    ssh -A "$user@$host"
}

# VPN-over-SSH using tun device
create_ssh_vpn() {
    local user="$1"
    local host="$2"
    
    echo "Creating VPN-over-SSH (requires root on both sides)..."
    ssh -w 0:0 "$user@$host"
    # Note: Additional setup required on both sides:
    # Local: ip addr add 10.0.0.1/24 dev tun0
    # Remote: ip addr add 10.0.0.2/24 dev tun0
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --help|-h)
            show_help
            ;;
        *)
            echo "Use --help for usage information"
            ;;
    esac
fi
