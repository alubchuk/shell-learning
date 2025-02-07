#!/bin/bash

# Signal Handling Examples
# ----------------------

# Global variables for cleanup tracking
TEMP_FILES=()
TEMP_DIRS=()
BACKGROUND_PIDS=()

# Function to display section headers
print_header() {
    echo -e "\n=== $1 ==="
    echo "----------------"
}

# Function to simulate work
simulate_work() {
    local duration=$1
    local interval=${2:-1}
    local count=0
    while [ $count -lt $duration ]; do
        echo -n "."
        sleep $interval
        ((count++))
    done
    echo
}

# Cleanup function
cleanup() {
    print_header "Cleanup"
    echo "Performing cleanup..."

    # Remove temporary files
    if [ ${#TEMP_FILES[@]} -gt 0 ]; then
        echo "Removing temporary files..."
        rm -f "${TEMP_FILES[@]}"
    fi

    # Remove temporary directories
    if [ ${#TEMP_DIRS[@]} -gt 0 ]; then
        echo "Removing temporary directories..."
        rm -rf "${TEMP_DIRS[@]}"
    fi

    # Terminate background processes
    if [ ${#BACKGROUND_PIDS[@]} -gt 0 ]; then
        echo "Terminating background processes..."
        kill "${BACKGROUND_PIDS[@]}" 2>/dev/null
    fi

    echo "Cleanup completed"
}

# Function to create temporary resources
create_temp_resources() {
    # Create temporary files
    local temp_file=$(mktemp)
    TEMP_FILES+=("$temp_file")
    echo "Data for testing" > "$temp_file"
    echo "Created temporary file: $temp_file"

    # Create temporary directory
    local temp_dir=$(mktemp -d)
    TEMP_DIRS+=("$temp_dir")
    touch "$temp_dir/test_file"
    echo "Created temporary directory: $temp_dir"

    # Start background process
    (
        while true; do
            sleep 1
        done
    ) &
    BACKGROUND_PIDS+=($!)
    echo "Started background process: $!"
}

# 1. Basic Signal Trapping
print_header "Basic Signal Trapping"

# Trap multiple signals
trap 'echo "Caught SIGINT (Ctrl+C)"' SIGINT
trap 'echo "Caught SIGTERM"' SIGTERM
trap 'echo "Caught SIGHUP"' SIGHUP

echo "Basic signal traps set. Try these:"
echo "1. Press Ctrl+C"
echo "2. Run 'kill -TERM $$' from another terminal"
echo "3. Run 'kill -HUP $$' from another terminal"

# 2. Cleanup on Exit
print_header "Cleanup on Exit"

# Set exit trap
trap cleanup EXIT

# Create some resources to clean up
create_temp_resources

echo "Resources created. Script will clean them up on exit."
echo "Try: Ctrl+C or kill the script to see cleanup in action."

# 3. Custom Signal Handlers
print_header "Custom Signal Handlers"

# Counter for SIGUSR1
SIGUSR1_COUNT=0

# Custom handler for SIGUSR1
sigusr1_handler() {
    ((SIGUSR1_COUNT++))
    echo "Received SIGUSR1 signal (count: $SIGUSR1_COUNT)"
    if [ $SIGUSR1_COUNT -ge 3 ]; then
        echo "Received SIGUSR1 three times, exiting..."
        exit 0
    fi
}

# Set custom handler
trap 'sigusr1_handler' SIGUSR1

echo "Custom SIGUSR1 handler set."
echo "Try: kill -USR1 $$ (from another terminal)"

# 4. Ignoring Signals
print_header "Ignoring Signals"

# Ignore SIGTERM temporarily
trap '' SIGTERM
echo "SIGTERM ignored for 5 seconds..."
sleep 5
# Restore default SIGTERM handler
trap - SIGTERM
echo "SIGTERM handling restored"

# 5. Signal Propagation
print_header "Signal Propagation"

# Start a child process
(
    # Child process sets its own trap
    trap 'echo "Child process caught SIGTERM"' SIGTERM
    echo "Child process started (PID: $$)"
    while true; do
        sleep 1
    done
) &
child_pid=$!
BACKGROUND_PIDS+=($child_pid)

echo "Parent PID: $$"
echo "Child PID: $child_pid"
echo "Sending SIGTERM to parent (signals propagate to child)..."
kill -TERM $$

# 6. Critical Section Protection
print_header "Critical Section Protection"

# Function demonstrating critical section
critical_section() {
    # Save current traps
    old_trap=$(trap -p SIGINT)
    
    # Ignore SIGINT during critical section
    trap '' SIGINT
    
    echo "Starting critical section..."
    echo "Try Ctrl+C now (it will be ignored)"
    simulate_work 5
    echo "Critical section completed"
    
    # Restore original trap
    eval "$old_trap"
    echo "Normal signal handling restored"
}

critical_section

# 7. Timeout Implementation
print_header "Timeout Implementation"

# Function with timeout
run_with_timeout() {
    local timeout=$1
    shift
    local cmd="$@"
    
    # Start command in background
    ($cmd) &
    local cmd_pid=$!
    BACKGROUND_PIDS+=($cmd_pid)
    
    # Wait for command or timeout
    (
        sleep $timeout
        kill $cmd_pid 2>/dev/null
    ) &
    local timeout_pid=$!
    BACKGROUND_PIDS+=($timeout_pid)
    
    # Wait for command to finish
    wait $cmd_pid 2>/dev/null
    local status=$?
    
    # Kill timeout process if command finished
    kill $timeout_pid 2>/dev/null
    
    return $status
}

echo "Running command with 3-second timeout..."
if run_with_timeout 3 "sleep 5"; then
    echo "Command completed"
else
    echo "Command timed out"
fi

# 8. Graceful Shutdown
print_header "Graceful Shutdown"

# Variables for shutdown control
SHUTDOWN_REQUESTED=false
SHUTDOWN_COMPLETED=false

# Shutdown handler
shutdown_handler() {
    echo "Shutdown requested..."
    SHUTDOWN_REQUESTED=true
}

# Set shutdown trap
trap 'shutdown_handler' SIGTERM

# Main processing loop
echo "Starting main process loop..."
echo "Try: kill -TERM $$ (from another terminal)"

count=0
while [ $count -lt 10 ] && [ "$SHUTDOWN_REQUESTED" = false ]; do
    echo -n "."
    sleep 1
    ((count++))
done

if [ "$SHUTDOWN_REQUESTED" = true ]; then
    echo -e "\nPerforming graceful shutdown..."
    simulate_work 3
    SHUTDOWN_COMPLETED=true
fi

echo "Process loop ended"
if [ "$SHUTDOWN_COMPLETED" = true ]; then
    echo "Graceful shutdown completed"
else
    echo "Normal completion"
fi

# Keep script running to demonstrate signals
echo -e "\nScript will exit in 10 seconds..."
echo "Try different signals during this time:"
echo "1. SIGINT (Ctrl+C)"
echo "2. SIGTERM (kill -TERM $$)"
echo "3. SIGUSR1 (kill -USR1 $$)"
sleep 10
