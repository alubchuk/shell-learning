#!/bin/bash

# Network Inspection Tools
# -------------------
# This script demonstrates various tools and techniques
# for analyzing network stack and connections.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Protocol Statistics
# ----------------

show_protocol_stats() {
    echo "Protocol Statistics:"
    echo "------------------"
    
    # TCP statistics
    echo "1. TCP statistics:"
    netstat -st || echo "netstat not available"
    
    # UDP statistics
    echo -e "\n2. UDP statistics:"
    netstat -su || echo "netstat not available"
    
    # IP statistics
    echo -e "\n3. IP statistics:"
    netstat -s | grep -A 5 "^Ip:" || echo "netstat not available"
    
    # ICMP statistics
    echo -e "\n4. ICMP statistics:"
    netstat -s | grep -A 5 "^Icmp:" || echo "netstat not available"
}

# 2. Socket Information
# ----------------

analyze_sockets() {
    echo "Socket Analysis:"
    echo "---------------"
    
    # Active connections
    echo "1. Active connections:"
    lsof -i | head -n 10
    
    # Listening ports
    echo -e "\n2. Listening ports:"
    netstat -an | grep LISTEN
    
    # Socket statistics
    echo -e "\n3. Socket statistics:"
    ss -s || echo "ss not available"
    
    # Unix domain sockets
    echo -e "\n4. Unix domain sockets:"
    netstat -x | head -n 5
}

# 3. Network Interfaces
# ----------------

analyze_interfaces() {
    echo "Network Interface Analysis:"
    echo "------------------------"
    
    # Interface list
    echo "1. Network interfaces:"
    ifconfig -a || echo "ifconfig not available"
    
    # Interface statistics
    echo -e "\n2. Interface statistics:"
    netstat -i
    
    # Link status
    echo -e "\n3. Link status:"
    networksetup -listallhardwareports
    
    # Interface configuration
    echo -e "\n4. Interface configuration:"
    networksetup -getinfo "Wi-Fi"
}

# 4. Routing Information
# -----------------

analyze_routing() {
    echo "Routing Analysis:"
    echo "----------------"
    
    # Routing table
    echo "1. Routing table:"
    netstat -rn
    
    # Default gateway
    echo -e "\n2. Default gateway:"
    route -n get default
    
    # ARP cache
    echo -e "\n3. ARP cache:"
    arp -an
    
    # Interface routes
    echo -e "\n4. Interface routes:"
    route get 0.0.0.0
}

# 5. Network Services
# --------------

analyze_services() {
    echo "Network Services Analysis:"
    echo "-----------------------"
    
    # Listening services
    echo "1. Listening services:"
    lsof -i -P | grep LISTEN
    
    # Service ports
    echo -e "\n2. Service ports:"
    grep -v "^#" /etc/services | head -n 5
    
    # Active services
    echo -e "\n3. Active services:"
    netstat -an | grep ESTABLISHED
}

# 6. Packet Analysis
# -------------

analyze_packets() {
    echo "Packet Analysis:"
    echo "---------------"
    
    # TCP dump (requires sudo)
    echo "1. Packet capture (requires sudo):"
    {
        sudo tcpdump -i any -c 5 2>/dev/null
    } || echo "tcpdump not available or permission denied"
    
    # Network statistics
    echo -e "\n2. Network statistics:"
    netstat -s | head -n 10
    
    # Interface packets
    echo -e "\n3. Interface packets:"
    netstat -i | grep -v "^lo"
}

# 7. Practical Examples
# ----------------

# Network connection monitor
monitor_connections() {
    local duration="$1"
    local interval="${2:-5}"
    local log_file="$LOG_DIR/connections.log"
    
    echo "Network Connection Monitor:"
    echo "------------------------"
    
    {
        echo "=== Network Connection Monitor ==="
        echo "Start time: $(date)"
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            
            # Active connections
            echo "Active connections:"
            netstat -an | grep ESTABLISHED
            
            # Listening ports
            echo -e "\nListening ports:"
            netstat -an | grep LISTEN
            
            sleep "$interval"
        done
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Interface traffic monitor
monitor_interface_traffic() {
    local interface="$1"
    local duration="$2"
    local log_file="$LOG_DIR/interface_traffic.log"
    
    echo "Interface Traffic Monitor:"
    echo "----------------------"
    
    {
        echo "=== Interface Traffic Monitor ==="
        echo "Interface: $interface"
        echo "Start time: $(date)"
        
        # Initial statistics
        echo -e "\nInitial statistics:"
        netstat -I "$interface"
        
        # Monitor traffic
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo -e "\n--- $(date) ---"
            netstat -I "$interface"
            sleep 1
        done
        
        # Final statistics
        echo -e "\nFinal statistics:"
        netstat -I "$interface"
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Network service analyzer
analyze_network_service() {
    local port="$1"
    local log_file="$LOG_DIR/service_analysis.log"
    
    echo "Network Service Analysis:"
    echo "----------------------"
    
    {
        echo "=== Network Service Analysis ==="
        echo "Port: $port"
        echo "Start time: $(date)"
        
        # Service information
        echo -e "\n1. Service identification:"
        grep -w "$port" /etc/services
        
        # Listening process
        echo -e "\n2. Listening process:"
        lsof -i :"$port"
        
        # Connection statistics
        echo -e "\n3. Connection statistics:"
        netstat -an | grep :"$port"
        
        # Process details
        echo -e "\n4. Process details:"
        if pid=$(lsof -ti :"$port"); then
            ps -p "$pid" -o pid,ppid,user,%cpu,%mem,command
        else
            echo "No process found listening on port $port"
        fi
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Analysis complete. Check $log_file for details"
}

# Network latency tester
test_network_latency() {
    local target="$1"
    local count="${2:-5}"
    local log_file="$LOG_DIR/latency_test.log"
    
    echo "Network Latency Test:"
    echo "------------------"
    
    {
        echo "=== Network Latency Test ==="
        echo "Target: $target"
        echo "Start time: $(date)"
        
        # DNS resolution
        echo -e "\n1. DNS resolution:"
        dig "$target" +short
        
        # Traceroute
        echo -e "\n2. Route to target:"
        traceroute "$target"
        
        # Ping test
        echo -e "\n3. Ping test:"
        ping -c "$count" "$target"
        
        echo "End time: $(date)"
    } > "$log_file"
    
    echo "Testing complete. Check $log_file for details"
}

# Main execution
main() {
    # Basic analysis
    show_protocol_stats
    echo -e "\n"
    
    analyze_sockets
    echo -e "\n"
    
    analyze_interfaces
    echo -e "\n"
    
    analyze_routing
    echo -e "\n"
    
    analyze_services
    echo -e "\n"
    
    analyze_packets
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    monitor_connections 10 2
    
    # Get default interface
    default_interface=$(route -n get default | grep interface | awk '{print $2}')
    monitor_interface_traffic "$default_interface" 10
    
    analyze_network_service 80
    
    test_network_latency "www.google.com" 3
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
