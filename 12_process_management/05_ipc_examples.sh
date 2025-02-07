#!/bin/bash

# IPC (Inter-Process Communication) Examples
# ------------------------------------
# This script demonstrates various IPC mechanisms
# including pipes, named pipes (FIFOs), and signals.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"
readonly FIFO_DIR="$OUTPUT_DIR/fifos"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR" "$FIFO_DIR"

# 1. Anonymous Pipes
# -------------

demonstrate_pipes() {
    echo "Anonymous Pipes:"
    echo "---------------"
    
    # Basic pipe
    echo "1. Basic pipe example:"
    echo "Hello, World!" | tr '[:lower:]' '[:upper:]'
    
    # Multiple pipes
    echo -e "\n2. Multiple pipe example:"
    cat /etc/passwd | grep "sh$" | cut -d: -f1
    
    # Process substitution
    echo -e "\n3. Process substitution:"
    diff <(ls "$OUTPUT_DIR") <(ls "$LOG_DIR")
}

# 2. Named Pipes (FIFOs)
# -----------------

setup_named_pipe() {
    local pipe_name="$1"
    local pipe_path="$FIFO_DIR/$pipe_name"
    
    # Create named pipe
    if [[ ! -p "$pipe_path" ]]; then
        mkfifo "$pipe_path"
    fi
    
    echo "$pipe_path"
}

demonstrate_named_pipes() {
    echo "Named Pipes (FIFOs):"
    echo "------------------"
    
    # Create named pipe
    local pipe_path
    pipe_path=$(setup_named_pipe "test_pipe")
    
    # Reader process
    {
        echo "Reader process starting..."
        while read -r line; do
            echo "Received: $line"
        done < "$pipe_path"
    } &
    reader_pid=$!
    
    # Writer process
    {
        echo "Writer process starting..."
        sleep 1
        echo "Message 1" > "$pipe_path"
        sleep 1
        echo "Message 2" > "$pipe_path"
        sleep 1
        echo "Message 3" > "$pipe_path"
    } &
    writer_pid=$!
    
    # Wait for processes
    wait "$writer_pid"
    kill "$reader_pid" 2>/dev/null || true
    
    # Cleanup
    rm -f "$pipe_path"
}

# 3. Signal-based Communication
# -----------------------

demonstrate_signal_comm() {
    echo "Signal-based Communication:"
    echo "-------------------------"
    
    # Start receiver
    {
        echo "Receiver starting (PID: $$)"
        
        # Signal handlers
        trap 'echo "Received data signal"' USR1
        trap 'echo "Received completion signal"; exit 0' USR2
        
        while true; do
            sleep 1
        done
    } &
    receiver_pid=$!
    
    # Send signals
    sleep 1
    echo "Sending data signal..."
    kill -USR1 "$receiver_pid"
    
    sleep 1
    echo "Sending completion signal..."
    kill -USR2 "$receiver_pid"
    
    # Wait for receiver
    wait "$receiver_pid" 2>/dev/null || true
}

# 4. Shared Memory (using files)
# ------------------------

demonstrate_shared_memory() {
    echo "Shared Memory (via files):"
    echo "------------------------"
    
    local shared_file="$OUTPUT_DIR/shared_data"
    
    # Initialize shared file
    echo "0" > "$shared_file"
    
    # Reader process
    {
        echo "Reader process starting..."
        for _ in {1..5}; do
            local value
            value=$(<"$shared_file")
            echo "Read value: $value"
            sleep 1
        done
    } &
    reader_pid=$!
    
    # Writer process
    {
        echo "Writer process starting..."
        for i in {1..5}; do
            echo "$i" > "$shared_file"
            echo "Wrote value: $i"
            sleep 1
        done
    } &
    writer_pid=$!
    
    # Wait for completion
    wait "$writer_pid"
    wait "$reader_pid"
    
    # Cleanup
    rm -f "$shared_file"
}

# 5. Message Queue (using files)
# ------------------------

demonstrate_message_queue() {
    echo "Message Queue (via files):"
    echo "-----------------------"
    
    local queue_dir="$OUTPUT_DIR/queue"
    mkdir -p "$queue_dir"
    
    # Producer process
    {
        echo "Producer starting..."
        for i in {1..5}; do
            local msg_file="$queue_dir/msg_$i"
            echo "Message $i content" > "$msg_file"
            echo "Produced message $i"
            sleep 1
        done
    } &
    producer_pid=$!
    
    # Consumer process
    {
        echo "Consumer starting..."
        while true; do
            # Process all messages
            for msg_file in "$queue_dir"/msg_*; do
                if [[ -f "$msg_file" ]]; then
                    echo "Processing: $(basename "$msg_file")"
                    cat "$msg_file"
                    rm "$msg_file"
                fi
            done
            sleep 1
        done
    } &
    consumer_pid=$!
    
    # Wait for producer
    wait "$producer_pid"
    sleep 2
    
    # Cleanup
    kill "$consumer_pid" 2>/dev/null || true
    rm -rf "$queue_dir"
}

# 6. Practical Examples
# ----------------

# Data pipeline using pipes
process_data_pipeline() {
    echo "Data Pipeline Example:"
    echo "--------------------"
    
    # Create test data
    local data_file="$OUTPUT_DIR/data.txt"
    {
        echo "apple,5,red"
        echo "banana,3,yellow"
        echo "orange,4,orange"
        echo "grape,2,purple"
        echo "apple,2,green"
    } > "$data_file"
    
    # Process pipeline
    echo "Processing data pipeline:"
    cat "$data_file" |
        sort |
        awk -F',' '{sum[$1]+=$2} END {for (item in sum) print item,sum[item]}' |
        sort -k2nr
    
    # Cleanup
    rm -f "$data_file"
}

# Client-server using named pipes
demonstrate_client_server() {
    echo "Client-Server Example:"
    echo "-------------------"
    
    # Setup pipes
    local request_pipe
    request_pipe=$(setup_named_pipe "request_pipe")
    local response_pipe
    response_pipe=$(setup_named_pipe "response_pipe")
    
    # Server process
    {
        echo "Server starting..."
        while true; do
            if read -r request < "$request_pipe"; then
                echo "Server received: $request"
                # Process request
                response="Response to: $request"
                echo "$response" > "$response_pipe"
            fi
        done
    } &
    server_pid=$!
    
    # Client process
    {
        echo "Client starting..."
        for i in {1..3}; do
            request="Request $i"
            echo "Client sending: $request"
            echo "$request" > "$request_pipe"
            response=$(cat "$response_pipe")
            echo "Client received: $response"
            sleep 1
        done
    } &
    client_pid=$!
    
    # Wait for client
    wait "$client_pid"
    
    # Cleanup
    kill "$server_pid" 2>/dev/null || true
    rm -f "$request_pipe" "$response_pipe"
}

# Distributed counter using shared file
demonstrate_distributed_counter() {
    echo "Distributed Counter Example:"
    echo "-------------------------"
    
    local counter_file="$OUTPUT_DIR/counter"
    echo "0" > "$counter_file"
    
    # Start multiple increment processes
    for i in {1..3}; do
        {
            echo "Increment process $i starting..."
            for _ in {1..5}; do
                # Read current value
                local value
                value=$(<"$counter_file")
                # Increment
                echo $((value + 1)) > "$counter_file"
                echo "Process $i: incremented to $((value + 1))"
                sleep 0.5
            done
        } &
    done
    
    # Wait for all processes
    wait
    
    # Show final value
    echo "Final counter value: $(<"$counter_file")"
    
    # Cleanup
    rm -f "$counter_file"
}

# Main execution
main() {
    # Basic IPC mechanisms
    demonstrate_pipes
    echo -e "\n"
    
    demonstrate_named_pipes
    echo -e "\n"
    
    demonstrate_signal_comm
    echo -e "\n"
    
    demonstrate_shared_memory
    echo -e "\n"
    
    demonstrate_message_queue
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    process_data_pipeline
    echo -e "\n"
    
    demonstrate_client_server
    echo -e "\n"
    
    demonstrate_distributed_counter
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
