#!/bin/bash

# Networking Commands Examples
# -------------------------
# This script demonstrates various networking commands
# for system administration and troubleshooting.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly LOG_FILE="network_tests.log"
readonly TEST_HOST="example.com"
readonly TEST_IP="93.184.216.34"  # example.com IP
readonly TEST_PORT=80
readonly TEST_FILE="test_download.txt"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# 1. Basic Network Testing
# ---------------------

basic_network_tests() {
    log "INFO" "Running basic network tests..."
    
    # Ping test
    echo "Testing ping:"
    if ping -c 4 "$TEST_HOST"; then
        log "INFO" "Ping to $TEST_HOST successful"
    else
        log "ERROR" "Ping to $TEST_HOST failed"
    fi
    
    # DNS lookup
    echo -e "\nDNS lookup:"
    if host "$TEST_HOST"; then
        log "INFO" "DNS lookup for $TEST_HOST successful"
    else
        log "ERROR" "DNS lookup for $TEST_HOST failed"
    fi
    
    # Traceroute
    echo -e "\nTraceroute:"
    traceroute "$TEST_HOST"
}

# 2. Network Interface Information
# ----------------------------

network_interface_info() {
    log "INFO" "Checking network interfaces..."
    
    # Interface list and status
    echo "Network interfaces:"
    ifconfig || ip addr show
    
    # Routing table
    echo -e "\nRouting table:"
    netstat -rn || ip route show
    
    # ARP cache
    echo -e "\nARP cache:"
    arp -a || ip neigh show
}

# 3. Network Statistics
# ------------------

network_statistics() {
    log "INFO" "Gathering network statistics..."
    
    # Active connections
    echo "Active connections:"
    netstat -an | grep ESTABLISHED
    
    # Listening ports
    echo -e "\nListening ports:"
    netstat -tuln
    
    # Interface statistics
    echo -e "\nInterface statistics:"
    netstat -i
}

# 4. Web Operations
# --------------

web_operations() {
    log "INFO" "Testing web operations..."
    
    # HTTP HEAD request
    echo "HTTP HEAD request:"
    curl -I "http://$TEST_HOST"
    
    # Download file
    echo -e "\nDownloading test file:"
    if wget -O "$TEST_FILE" "http://$TEST_HOST"; then
        log "INFO" "File download successful"
        rm "$TEST_FILE"
    else
        log "ERROR" "File download failed"
    fi
    
    # Custom HTTP request
    echo -e "\nCustom HTTP request:"
    curl -X GET "http://$TEST_HOST" \
         -H "User-Agent: NetworkTest/1.0" \
         -H "Accept: text/html"
}

# 5. Port Testing
# ------------

port_testing() {
    log "INFO" "Testing ports..."
    
    # Test specific port
    echo "Testing port $TEST_PORT on $TEST_HOST:"
    nc -zv "$TEST_HOST" "$TEST_PORT" 2>&1
    
    # Scan common ports
    echo -e "\nScanning common ports:"
    for port in 80 443 22 25; do
        if nc -z -w1 "$TEST_HOST" "$port" 2>/dev/null; then
            log "INFO" "Port $port is open on $TEST_HOST"
        else
            log "INFO" "Port $port is closed on $TEST_HOST"
        fi
    done
}

# 6. Network Monitoring
# ------------------

network_monitoring() {
    log "INFO" "Starting network monitoring..."
    
    # Monitor network traffic (brief)
    echo "Monitoring network traffic (5 seconds):"
    timeout 5 tcpdump -i any -n
    
    # Monitor specific host
    echo -e "\nMonitoring specific host (5 seconds):"
    timeout 5 tcpdump -i any "host $TEST_IP"
    
    # Monitor specific port
    echo -e "\nMonitoring specific port (5 seconds):"
    timeout 5 tcpdump -i any "port $TEST_PORT"
}

# 7. SSH Examples
# ------------

ssh_examples() {
    log "INFO" "Demonstrating SSH commands..."
    
    # Generate SSH key (for demonstration)
    echo "Generating SSH key:"
    ssh-keygen -t rsa -f test_key -N "" -q
    
    # Show SSH key fingerprint
    echo -e "\nSSH key fingerprint:"
    ssh-keygen -lf test_key
    
    # Clean up
    rm -f test_key test_key.pub
}

# 8. Network Troubleshooting
# -----------------------

network_troubleshooting() {
    log "INFO" "Running network diagnostics..."
    
    # Check DNS resolution
    echo "DNS resolution:"
    dig "$TEST_HOST" +short
    
    # Check reverse DNS
    echo -e "\nReverse DNS:"
    dig -x "$TEST_IP" +short
    
    # MTU discovery
    echo -e "\nMTU discovery:"
    ping -D -s 1472 -c 1 "$TEST_HOST"
}

# 9. Practical Examples
# -----------------

# Monitor network latency
monitor_latency() {
    log "INFO" "Monitoring network latency..."
    
    echo "Monitoring latency to $TEST_HOST (5 pings):"
    ping -c 5 "$TEST_HOST" | tail -1
}

# Check service availability
check_service() {
    log "INFO" "Checking service availability..."
    
    local service_host="$1"
    local service_port="$2"
    
    if nc -z -w1 "$service_host" "$service_port" 2>/dev/null; then
        log "INFO" "Service $service_host:$service_port is available"
        return 0
    else
        log "ERROR" "Service $service_host:$service_port is not available"
        return 1
    fi
}

# Main execution
main() {
    # Initialize log file
    : > "$LOG_FILE"
    
    # Run examples
    basic_network_tests
    echo -e "\n"
    network_interface_info
    echo -e "\n"
    network_statistics
    echo -e "\n"
    web_operations
    echo -e "\n"
    port_testing
    echo -e "\n"
    network_monitoring
    echo -e "\n"
    ssh_examples
    echo -e "\n"
    network_troubleshooting
    echo -e "\n"
    monitor_latency
    echo -e "\n"
    check_service "$TEST_HOST" "$TEST_PORT"
    
    # Show log location
    echo -e "\nDetailed logs available in: $LOG_FILE"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
