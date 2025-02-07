#!/bin/bash

# Process Management Examples
# ------------------------

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

# 1. Basic Process Information
print_header "Basic Process Information"

echo "Current script PID: $$"
echo "Parent process PID: $PPID"
echo "Shell: $SHELL"
echo "Current directory: $PWD"

# 2. Process Creation
print_header "Process Creation"

# Fork a background process
echo "Starting a background process..."
(
    echo "Background process started with PID: $$"
    simulate_work 5
    echo "Background process completed"
) &
bg_pid=$!
echo "Background process PID: $bg_pid"

# Wait for background process
echo "Waiting for background process to complete..."
wait $bg_pid
echo "Background process finished"

# 3. Process Groups and Sessions
print_header "Process Groups and Sessions"

echo "Process Group ID: $(ps -o pgid= -p $$)"
echo "Session ID: $(ps -o sid= -p $$)"

# 4. Background Jobs Management
print_header "Background Jobs Management"

# Start multiple background jobs
echo "Starting multiple background jobs..."
(sleep 3; echo "Job 1 done") &
(sleep 4; echo "Job 2 done") &
(sleep 5; echo "Job 3 done") &

echo "Active jobs:"
jobs

echo "Waiting for all jobs to complete..."
wait
echo "All jobs completed"

# 5. Process Priority
print_header "Process Priority"

# Show current priority
echo "Current process nice value: $(nice)"

# Start a low priority process
echo "Starting a low priority process..."
nice -n 19 bash -c 'echo "Low priority process (nice: $(nice))"'

# Start a high priority process (requires sudo)
echo "Note: Starting high priority process requires sudo"
echo "Example: sudo nice -n -20 command"

# 6. Resource Usage
print_header "Resource Usage"

# Function to show process resource usage
show_resources() {
    local pid=$1
    ps -o pid,ppid,pgid,%cpu,%mem,rss,command -p $pid
}

echo "Current process resources:"
show_resources $$

# 7. Process Monitoring
print_header "Process Monitoring"

# Start a process to monitor
(
    echo "Starting monitored process (PID: $$)"
    simulate_work 10
) &
monitored_pid=$!

# Monitor the process
echo "Monitoring process $monitored_pid..."
while kill -0 $monitored_pid 2>/dev/null; do
    show_resources $monitored_pid
    sleep 1
done

# 8. Process Environment
print_header "Process Environment"

# Show process limits
echo "Process limits:"
ulimit -a

# Show process environment
echo -e "\nProcess environment (first 5 variables):"
env | head -n 5

# 9. Subshell Demonstration
print_header "Subshell Demonstration"

# Variable in parent shell
PARENT_VAR="parent value"
echo "Parent shell PID: $$"
echo "Parent variable: $PARENT_VAR"

# Start a subshell
(
    echo "Subshell PID: $$"
    echo "Parent variable in subshell: $PARENT_VAR"
    SUBSHELL_VAR="subshell value"
    echo "Subshell variable: $SUBSHELL_VAR"
)

echo "Trying to access subshell variable: $SUBSHELL_VAR (should be empty)"

# 10. Process Substitution
print_header "Process Substitution"

echo "Comparing output of two commands:"
diff <(ls -l) <(ls -la)

# 11. Named Pipes (FIFOs)
print_header "Named Pipes"

# Create a named pipe
PIPE_FILE="/tmp/testpipe"
mkfifo $PIPE_FILE

# Start reader in background
(
    echo "Reader process started (PID: $$)"
    read line < $PIPE_FILE
    echo "Reader received: $line"
) &

# Write to pipe
echo "Writing to named pipe..."
echo "Hello through the pipe" > $PIPE_FILE

# Clean up
rm $PIPE_FILE

# 12. Process Termination
print_header "Process Termination"

# Start a process that we'll terminate
(
    echo "Starting process to terminate (PID: $$)"
    simulate_work 30
) &
term_pid=$!

# Let it run for a moment
sleep 2

# Terminate the process
echo "Terminating process $term_pid..."
kill $term_pid

# Wait for it to finish
wait $term_pid
echo "Process terminated"

# Clean up any remaining background processes
jobs -p | xargs -r kill

echo -e "\nProcess management demonstration completed"
