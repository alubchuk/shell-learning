#!/bin/bash

# Coprocess Examples
# ---------------
# This script demonstrates various coprocess patterns
# and inter-process communication techniques.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly PIPE_DIR="$OUTPUT_DIR/pipes"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$PIPE_DIR"

# 1. Basic Coprocess
# --------------

basic_coprocess() {
    echo "Basic Coprocess:"
    echo "---------------"
    
    # Start a simple coprocess
    echo "1. Simple echo coprocess:"
    coproc BASIC { while read -r line; do echo "PROC: $line"; done; }
    
    # Send data to coprocess
    echo "test message" >&${BASIC[1]}
    
    # Read response
    read -r response <&${BASIC[0]}
    echo "Response: $response"
    
    # Clean up
    kill $BASIC_PID 2>/dev/null || true
    wait $BASIC_PID 2>/dev/null || true
}

# 2. Worker Pool
# ----------

worker_pool() {
    echo "Worker Pool:"
    echo "-----------"
    
    # Worker function
    worker() {
        local id=$1
        while read -r task; do
            case $task in
                quit) break ;;
                *)
                    echo "Worker $id processing: $task"
                    sleep 0.5  # Simulate work
                    ;;
            esac
        done
    }
    
    # Start worker pool
    declare -A workers
    for ((i=1; i<=3; i++)); do
        coproc "WORKER$i" { worker "$i"; }
        workers[$i]=$COPROC_PID
    done
    
    # Distribute tasks
    tasks=("task1" "task2" "task3" "task4" "task5" "task6")
    worker_idx=1
    
    echo "1. Distributing tasks:"
    for task in "${tasks[@]}"; do
        eval "echo '$task' >&\${WORKER${worker_idx}[1]}"
        ((worker_idx++))
        [[ $worker_idx -gt ${#workers[@]} ]] && worker_idx=1
    done
    
    # Wait for tasks to complete
    sleep 2
    
    # Shutdown workers
    echo -e "\n2. Shutting down workers:"
    for ((i=1; i<=3; i++)); do
        eval "echo 'quit' >&\${WORKER${i}[1]}"
        wait "${workers[$i]}" 2>/dev/null || true
    done
}

# 3. Data Pipeline
# ------------

data_pipeline() {
    echo "Data Pipeline:"
    echo "-------------"
    
    # Stage 1: Generate data
    coproc GENERATOR {
        for ((i=1; i<=5; i++)); do
            echo "data$i"
            sleep 0.2
        done
    }
    
    # Stage 2: Transform data
    coproc TRANSFORMER {
        while read -r line; do
            echo "${line^^}"  # Convert to uppercase
            sleep 0.1
        done
    }
    
    # Stage 3: Filter data
    coproc FILTER {
        while read -r line; do
            if [[ $line == *"3"* ]] || [[ $line == *"5"* ]]; then
                echo "$line"
            fi
        done
    }
    
    echo "1. Processing pipeline:"
    # Connect pipeline stages
    while read -r data <&${GENERATOR[0]}; do
        echo "$data" >&${TRANSFORMER[1]}
        read -r transformed <&${TRANSFORMER[0]}
        echo "$transformed" >&${FILTER[1]}
        read -r filtered <&${FILTER[0]} && echo "Result: $filtered"
    done
    
    # Clean up
    for pid in $GENERATOR_PID $TRANSFORMER_PID $FILTER_PID; do
        kill $pid 2>/dev/null || true
        wait $pid 2>/dev/null || true
    done
}

# 4. Bidirectional Communication
# -------------------------

bidirectional_comm() {
    echo "Bidirectional Communication:"
    echo "-------------------------"
    
    # Start server coprocess
    coproc SERVER {
        declare -A data
        while read -r cmd args; do
            case $cmd in
                SET)
                    key=${args%% *}
                    value=${args#* }
                    data[$key]=$value
                    echo "OK"
                    ;;
                GET)
                    key=$args
                    if [[ -v data[$key] ]]; then
                        echo "VALUE ${data[$key]}"
                    else
                        echo "NOT_FOUND"
                    fi
                    ;;
                LIST)
                    echo "KEYS ${!data[*]}"
                    ;;
                QUIT)
                    echo "BYE"
                    break
                    ;;
                *)
                    echo "ERROR Unknown command"
                    ;;
            esac
        done
    }
    
    # Helper function to send command and get response
    send_command() {
        echo "$1" >&${SERVER[1]}
        read -r response <&${SERVER[0]}
        echo "$response"
    }
    
    # Example usage
    echo "1. Setting values:"
    send_command "SET name John"
    send_command "SET age 30"
    
    echo -e "\n2. Getting values:"
    send_command "GET name"
    send_command "GET age"
    send_command "GET nonexistent"
    
    echo -e "\n3. Listing keys:"
    send_command "LIST"
    
    echo -e "\n4. Shutting down:"
    send_command "QUIT"
    
    # Clean up
    wait $SERVER_PID 2>/dev/null || true
}

# 5. Error Handling
# -------------

error_handling() {
    echo "Error Handling:"
    echo "--------------"
    
    # Start processor with error handling
    coproc PROCESSOR {
        trap 'echo "Processor terminated"; exit 1' TERM
        
        while read -r input; do
            if [[ $input == "error" ]]; then
                echo "ERROR Invalid input" >&2
                continue
            elif [[ $input == "quit" ]]; then
                break
            fi
            echo "Processed: $input"
        done
    }
    
    # Redirect stderr to capture errors
    exec 3>&2  # Save original stderr
    exec 2>"$OUTPUT_DIR/errors.log"
    
    echo "1. Normal processing:"
    echo "test1" >&${PROCESSOR[1]}
    read -r response <&${PROCESSOR[0]}
    echo "$response"
    
    echo -e "\n2. Error case:"
    echo "error" >&${PROCESSOR[1]}
    
    echo -e "\n3. Another normal case:"
    echo "test2" >&${PROCESSOR[1]}
    read -r response <&${PROCESSOR[0]}
    echo "$response"
    
    # Restore stderr
    exec 2>&3
    
    echo -e "\n4. Error log contents:"
    cat "$OUTPUT_DIR/errors.log"
    
    # Clean up
    echo "quit" >&${PROCESSOR[1]}
    wait $PROCESSOR_PID 2>/dev/null || true
}

# 6. Resource Management
# ------------------

resource_manager() {
    echo "Resource Management:"
    echo "------------------"
    
    # Create named pipes
    local pipe1="$PIPE_DIR/pipe1"
    local pipe2="$PIPE_DIR/pipe2"
    mkfifo "$pipe1" "$pipe2"
    
    # Start resource manager
    coproc MANAGER {
        declare -A resources
        local max_resources=3
        local active_resources=0
        
        cleanup() {
            echo "Cleaning up resources..."
            rm -f "$pipe1" "$pipe2"
            exit 0
        }
        trap cleanup EXIT
        
        while read -r cmd args; do
            case $cmd in
                ACQUIRE)
                    if ((active_resources >= max_resources)); then
                        echo "ERROR Resource limit reached"
                    else
                        id="res$((++active_resources))"
                        resources[$id]=1
                        echo "GRANTED $id"
                    fi
                    ;;
                RELEASE)
                    id=$args
                    if [[ -v resources[$id] ]]; then
                        unset "resources[$id]"
                        ((active_resources--))
                        echo "OK Released $id"
                    else
                        echo "ERROR Invalid resource id"
                    fi
                    ;;
                STATUS)
                    echo "INFO Active: $active_resources, Available: $((max_resources - active_resources))"
                    ;;
                QUIT)
                    break
                    ;;
            esac
        done
    }
    
    # Helper function
    send_manager() {
        echo "$1" >&${MANAGER[1]}
        read -r response <&${MANAGER[0]}
        echo "$response"
    }
    
    echo "1. Resource acquisition:"
    send_manager "ACQUIRE"
    send_manager "ACQUIRE"
    
    echo -e "\n2. Status check:"
    send_manager "STATUS"
    
    echo -e "\n3. Resource exhaustion:"
    send_manager "ACQUIRE"
    send_manager "ACQUIRE"
    
    echo -e "\n4. Resource release:"
    send_manager "RELEASE res1"
    send_manager "STATUS"
    
    # Clean up
    send_manager "QUIT"
    wait $MANAGER_PID 2>/dev/null || true
}

# Main execution
main() {
    # Run examples
    basic_coprocess
    echo -e "\n"
    worker_pool
    echo -e "\n"
    data_pipeline
    echo -e "\n"
    bidirectional_comm
    echo -e "\n"
    error_handling
    echo -e "\n"
    resource_manager
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
