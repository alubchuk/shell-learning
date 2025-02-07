#!/bin/bash

# Advanced SSH Examples
# -------------------

# Database tunneling with monitoring
db_tunnel() {
    local db_host="$1"
    local db_port="$2"
    local ssh_host="$3"
    local local_port="$4"
    
    # Create tunnel with auto-reconnect
    while true; do
        echo "$(date): Establishing database tunnel..."
        ssh -o ServerAliveInterval=30 \
            -o ServerAliveCountMax=3 \
            -o ExitOnForwardFailure=yes \
            -L "$local_port:$db_host:$db_port" "$ssh_host" \
            "while true; do echo 'Tunnel active'; sleep 300; done"
        
        echo "$(date): Tunnel dropped. Reconnecting in 5 seconds..."
        sleep 5
    done
}

# Git over SSH with custom port
git_over_ssh() {
    local repo="$1"
    local port="$2"
    
    # Set up SSH configuration for Git
    cat << EOF >> ~/.ssh/config
Host github.com
    Hostname github.com
    Port $port
    User git
    IdentityFile ~/.ssh/github_key
    IdentitiesOnly yes
EOF
    
    # Test connection
    ssh -T git@github.com
}

# Multi-port forwarding
multi_port_forward() {
    local ssh_host="$1"
    shift
    local ports=("$@")
    
    # Build forwarding string
    local forwards=""
    for port in "${ports[@]}"; do
        forwards="$forwards -L $port:localhost:$port"
    done
    
    # Create tunnel
    echo "Forwarding ports: ${ports[*]}"
    ssh $forwards "$ssh_host"
}

# Reverse tunnel for remote access
reverse_tunnel() {
    local ssh_host="$1"
    local remote_port="$2"
    local local_port="$3"
    
    # Create persistent reverse tunnel
    autossh -M 0 \
        -o "ServerAliveInterval 30" \
        -o "ServerAliveCountMax 3" \
        -R "$remote_port:localhost:$local_port" \
        -N "$ssh_host"
}

# Load balancer tunnel
load_balancer_tunnel() {
    local lb_host="$1"
    local backends=("${@:2}")
    
    # Forward to multiple backend servers
    local forwards=""
    local port=8081
    for backend in "${backends[@]}"; do
        forwards="$forwards -L $port:$backend:80"
        ((port++))
    done
    
    # Create tunnel
    ssh $forwards "$lb_host"
}

# Kubernetes port forwarding
k8s_tunnel() {
    local bastion_host="$1"
    local cluster_host="$2"
    
    # Forward Kubernetes API and dashboard
    ssh -L 6443:$cluster_host:6443 \
        -L 8001:$cluster_host:8001 \
        -L 30000-30100:$cluster_host:30000-30100 \
        "$bastion_host"
}

# Development environment tunnel
dev_tunnel() {
    local dev_host="$1"
    
    # Forward common development ports
    ssh -L 3000:localhost:3000 \  # React
        -L 8080:localhost:8080 \  # Web server
        -L 5432:localhost:5432 \  # PostgreSQL
        -L 6379:localhost:6379 \  # Redis
        -L 27017:localhost:27017 \ # MongoDB
        -L 9229:localhost:9229 \  # Node.js debugger
        -N "$dev_host"
}

# Monitoring tunnel
monitoring_tunnel() {
    local monitor_host="$1"
    
    # Forward monitoring ports
    ssh -L 9090:localhost:9090 \  # Prometheus
        -L 3000:localhost:3000 \  # Grafana
        -L 9100:localhost:9100 \  # Node exporter
        -L 9115:localhost:9115 \  # Blackbox exporter
        -N "$monitor_host"
}

# SOCKS proxy with bandwidth limit
limited_socks_proxy() {
    local proxy_host="$1"
    local proxy_port="$2"
    local bandwidth_limit="$3"  # in KB/s
    
    # Create SOCKS proxy with bandwidth limit
    ssh -D "$proxy_port" \
        -o "IPQoS=throughput" \
        -o "TCPKeepAlive=yes" \
        -o "ServerAliveInterval=60" \
        -C "$proxy_host" \
        "trickle -d $bandwidth_limit -u $bandwidth_limit /bin/bash"
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "$1" in
        --db-tunnel)
            db_tunnel "db.internal" 5432 "bastion.example.com" 15432
            ;;
        --git-ssh)
            git_over_ssh "git@github.com:user/repo.git" 443
            ;;
        --multi-port)
            multi_port_forward "dev.example.com" 3000 8080 5432
            ;;
        --reverse)
            reverse_tunnel "public.example.com" 8080 3000
            ;;
        --lb)
            load_balancer_tunnel "lb.example.com" "web1:80" "web2:80" "web3:80"
            ;;
        --k8s)
            k8s_tunnel "bastion.example.com" "k8s-master.internal"
            ;;
        --dev)
            dev_tunnel "dev.example.com"
            ;;
        --monitor)
            monitoring_tunnel "monitor.example.com"
            ;;
        --proxy)
            limited_socks_proxy "proxy.example.com" 1080 100
            ;;
        *)
            echo "Please specify a command"
            ;;
    esac
fi
