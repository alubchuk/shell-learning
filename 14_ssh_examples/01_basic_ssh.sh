#!/bin/bash

# Basic SSH Operations Examples
# ---------------------------

# Function to display usage
show_help() {
    cat << EOF
SSH Basic Operations Examples
Usage: $0 [options]

Options:
    -h, --help          Show this help message
    -u, --user USER     Remote username
    -h, --host HOST     Remote hostname
    -p, --port PORT     SSH port (default: 22)
    -i, --identity FILE SSH identity file

Examples:
    $0 --user john --host example.com
    $0 --user john --host example.com --port 2222
EOF
}

# Basic SSH connection
basic_ssh() {
    local user="$1"
    local host="$2"
    local port="${3:-22}"
    
    echo "Connecting to $user@$host:$port..."
    ssh -p "$port" "$user@$host"
}

# SSH with identity file
ssh_with_key() {
    local user="$1"
    local host="$2"
    local key_file="$3"
    
    echo "Connecting using key file: $key_file"
    ssh -i "$key_file" "$user@$host"
}

# SSH with custom configuration
ssh_with_config() {
    local host="$1"
    cat << EOF > ~/.ssh/config.example
Host $host
    HostName $host
    User your_username
    Port 22
    IdentityFile ~/.ssh/id_rsa
    ServerAliveInterval 60
    ServerAliveCountMax 3
    ConnectTimeout 10
EOF
    echo "Example SSH config created at ~/.ssh/config.example"
}

# Generate SSH key pair
generate_ssh_key() {
    local key_file="$1"
    local comment="$2"
    
    ssh-keygen -t ed25519 -f "$key_file" -C "$comment"
}

# Copy SSH key to remote host
copy_ssh_key() {
    local user="$1"
    local host="$2"
    local key_file="${3:-~/.ssh/id_ed25519.pub}"
    
    ssh-copy-id -i "$key_file" "$user@$host"
}

# Test SSH connection
test_ssh_connection() {
    local user="$1"
    local host="$2"
    
    ssh -q "$user@$host" exit
    if [ $? -eq 0 ]; then
        echo "SSH connection successful"
    else
        echo "SSH connection failed"
    fi
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
