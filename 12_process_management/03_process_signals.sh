#!/bin/bash

# Process Signals
# ------------
# This script demonstrates signal handling and
# process communication using signals.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Signal Handlers
# -------------

# Log file for signal handling
readonly SIGNAL_LOG="$LOG_DIR/signals.log"

# Signal handler function
handle_signal() {
    local signal="$1"
    echo "$(date): Received signal $signal" >> "$SIGNAL_LOG"
    
    case "$signal" in
        SIGINT)
            echo "Interrupt signal received"
            ;;
        SIGTERM)
            echo "Termination signal received"
            exit 0
            ;;
        SIGUSR1)
            echo "User signal 1 received"
            ;;
        SIGUSR2)
            echo "User signal 2 received"
            ;;
        *)
            echo "Unknown signal received: $signal"
            ;;
    esac
}

# Setup signal handlers
setup_signal_handlers() {
    echo "Setting up signal handlers..."
    
    # Common signals
    trap 'handle_signal SIGINT' INT
    trap 'handle_signal SIGTERM' TERM
    trap 'handle_signal SIGUSR1' USR1
    trap 'handle_signal SIGUSR2' USR2
    
    # Ignore some signals
    trap '' HUP
    
    echo "Signal handlers configured"
    echo "Process ID: $$"
}

# 2. Signal Generation
# ---------------

generate_signals() {
    local pid="$1"
    
    echo "Generating Signals:"
    echo "-----------------"
    
    # Send various signals
    echo "1. Sending SIGUSR1"
    kill -USR1 "$pid"
    sleep 1
    
    echo "2. Sending SIGUSR2"
    kill -USR2 "$pid"
    sleep 1
    
    echo "3. Sending SIGTERM"
    kill -TERM "$pid"
    sleep 1
}

# 3. Signal Masking
# ------------

mask_signals() {
    echo "Signal Masking:"
    echo "--------------"
    
    # Save current signal mask
    trap 'echo "Signal mask restored"' RETURN
    
    # Block signals
    echo "1. Blocking signals"
    trap '' USR1 USR2
    
    # Critical section
    echo "2. In critical section"
    sleep 5
    
    # Restore original handlers
    trap 'handle_signal SIGUSR1' USR1
    trap 'handle_signal SIGUSR2' USR2
    
    echo "3. Signals unblocked"
}

# 4. Process Communication
# -------------------

# Signal-based communication between processes
communicate_processes() {
    echo "Process Communication:"
    echo "--------------------"
    
    # Start receiver process
    (
        echo "Receiver starting (PID: $$)"
        trap 'echo "Receiver: Signal 1 received"' USR1
        trap 'echo "Receiver: Signal 2 received"' USR2
        trap 'echo "Receiver: Terminating"; exit 0' TERM
        
        while true; do
            sleep 1
        done
    ) &
    receiver_pid=$!
    
    # Start sender process
    (
        echo "Sender starting (PID: $$)"
        sleep 2
        echo "Sending signal 1"
        kill -USR1 "$receiver_pid"
        sleep 2
        echo "Sending signal 2"
        kill -USR2 "$receiver_pid"
        sleep 2
        echo "Sending termination"
        kill -TERM "$receiver_pid"
    ) &
    sender_pid=$!
    
    # Wait for completion
    wait "$sender_pid"
    wait "$receiver_pid" 2>/dev/null || true
}

# 5. Signal Patterns
# -------------

# Graceful shutdown pattern
graceful_shutdown() {
    echo "Graceful Shutdown Pattern:"
    echo "-----------------------"
    
    # Cleanup function
    cleanup() {
        echo "Cleaning up resources..."
        sleep 1
        echo "Cleanup complete"
    }
    
    # Setup handlers
    trap cleanup EXIT
    trap 'echo "Interrupted - starting cleanup"; exit 1' INT TERM
    
    # Main work
    echo "Starting work..."
    sleep 10
}

# Parent-child signaling pattern
parent_child_signaling() {
    echo "Parent-Child Signaling:"
    echo "---------------------"
    
    # Start child process
    (
        echo "Child process starting (PID: $$)"
        trap 'echo "Child: Processing data"; sleep 2; kill -USR2 "$PPID"' USR1
        trap 'echo "Child: Terminating"; exit 0' TERM
        
        while true; do
            sleep 1
        done
    ) &
    child_pid=$!
    
    # Parent process
    trap 'echo "Parent: Received completion signal"' USR2
    
    echo "Parent sending work signal"
    kill -USR1 "$child_pid"
    sleep 5
    
    echo "Parent terminating child"
    kill -TERM "$child_pid"
}

# 6. Practical Examples
# ----------------

# Process supervisor
supervise_process() {
    local command="$1"
    local max_restarts="${2:-3}"
    local restart_delay="${3:-5}"
    
    echo "Process Supervisor:"
    echo "-----------------"
    
    local restarts=0
    while ((restarts < max_restarts)); do
        echo "Starting process (attempt $((restarts + 1)))"
        
        # Start process
        $command &
        pid=$!
        
        # Wait for process
        wait "$pid" 2>/dev/null
        status=$?
        
        if ((status == 0)); then
            echo "Process completed successfully"
            break
        else
            echo "Process failed with status $status"
            ((restarts++))
            
            if ((restarts < max_restarts)); then
                echo "Restarting in $restart_delay seconds..."
                sleep "$restart_delay"
            fi
        fi
    done
    
    if ((restarts >= max_restarts)); then
        echo "Maximum restart attempts reached"
        return 1
    fi
}

# Signal-based state machine
state_machine() {
    echo "Signal-based State Machine:"
    echo "-------------------------"
    
    # States
    declare -A states=(
        [INIT]="Initializing"
        [RUNNING]="Running"
        [PAUSED]="Paused"
        [SHUTDOWN]="Shutting down"
    )
    
    current_state="INIT"
    
    # State handlers
    trap 'current_state="RUNNING"; echo "State: ${states[$current_state]}"' USR1
    trap 'current_state="PAUSED"; echo "State: ${states[$current_state]}"' USR2
    trap 'current_state="SHUTDOWN"; echo "State: ${states[$current_state]}"; exit 0' TERM
    
    # Main loop
    echo "Initial state: ${states[$current_state]}"
    while true; do
        case "$current_state" in
            INIT)
                sleep 1
                kill -USR1 $$  # Transition to RUNNING
                ;;
            RUNNING)
                echo "Processing..."
                sleep 2
                ;;
            PAUSED)
                echo "Paused..."
                sleep 1
                ;;
            SHUTDOWN)
                echo "Shutting down..."
                break
                ;;
        esac
    done
}

# Main execution
main() {
    # Setup handlers
    setup_signal_handlers
    echo -e "\n"
    
    # Test signal masking
    mask_signals
    echo -e "\n"
    
    # Test process communication
    communicate_processes
    echo -e "\n"
    
    # Test graceful shutdown
    graceful_shutdown &
    shutdown_pid=$!
    sleep 2
    kill -INT "$shutdown_pid"
    echo -e "\n"
    
    # Test parent-child signaling
    parent_child_signaling
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Process supervision
    supervise_process "sleep 2" 2 1
    
    # State machine (runs for 10 seconds)
    state_machine &
    state_pid=$!
    sleep 2
    kill -USR2 "$state_pid"  # Pause
    sleep 2
    kill -USR1 "$state_pid"  # Resume
    sleep 2
    kill -TERM "$state_pid"  # Shutdown
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
