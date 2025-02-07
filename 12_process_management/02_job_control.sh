#!/bin/bash

# Job Control Examples
# ----------------
# This script demonstrates job control features including
# background/foreground jobs and job monitoring.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly LOG_DIR="$OUTPUT_DIR/logs"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"

# 1. Job Status Functions
# ------------------

show_jobs() {
    echo "Current Jobs:"
    echo "------------"
    jobs -l
}

job_exists() {
    local job_id="$1"
    jobs -l "%$job_id" &>/dev/null
}

get_job_pid() {
    local job_id="$1"
    jobs -l "%$job_id" | awk '{print $2}'
}

# 2. Background Jobs
# -------------

run_background_jobs() {
    echo "Background Jobs:"
    echo "---------------"
    
    # Start some background jobs
    echo "1. Starting background jobs:"
    sleep 30 &
    echo "Started sleep 30 (Job 1)"
    
    sleep 25 &
    echo "Started sleep 25 (Job 2)"
    
    sleep 20 &
    echo "Started sleep 20 (Job 3)"
    
    # Show jobs
    echo -e "\n2. Current jobs:"
    show_jobs
}

# 3. Job Control
# ----------

control_jobs() {
    echo "Job Control:"
    echo "-----------"
    
    # Start a job
    echo "1. Starting a job:"
    sleep 100 &
    job_pid=$!
    echo "Started job (PID: $job_pid)"
    
    # Suspend job
    echo -e "\n2. Suspending job:"
    kill -STOP "$job_pid"
    sleep 1
    show_jobs
    
    # Continue job
    echo -e "\n3. Continuing job:"
    kill -CONT "$job_pid"
    sleep 1
    show_jobs
    
    # Terminate job
    echo -e "\n4. Terminating job:"
    kill -TERM "$job_pid"
    sleep 1
    show_jobs
}

# 4. Job Scheduling
# ------------

schedule_job() {
    local delay="$1"
    local command="$2"
    
    echo "Job Scheduling:"
    echo "--------------"
    
    # Schedule with at
    echo "1. Scheduling with 'at':"
    echo "$command" | at now + "$delay" minutes
    
    # Show scheduled jobs
    echo -e "\n2. Scheduled jobs:"
    atq
}

# 5. Job Priority
# ----------

set_job_priority() {
    local command="$1"
    local priority="${2:-10}"  # Nice value (higher = lower priority)
    
    echo "Job Priority:"
    echo "------------"
    
    # Start job with nice
    echo "1. Starting job with nice value $priority:"
    nice -n "$priority" "$command" &
    job_pid=$!
    
    # Show process priority
    echo -e "\n2. Process priority:"
    ps -o pid,nice,cmd -p "$job_pid"
}

# 6. Job Monitoring
# ------------

monitor_jobs() {
    echo "Job Monitoring:"
    echo "--------------"
    
    # Start test jobs
    echo "1. Starting test jobs:"
    sleep 30 &
    job1_pid=$!
    sleep 20 &
    job2_pid=$!
    
    # Monitor loop
    echo -e "\n2. Monitoring jobs:"
    local end=$((SECONDS + 10))
    while ((SECONDS < end)); do
        echo "=== $(date) ==="
        jobs -l
        ps -o pid,ppid,%cpu,%mem,cmd -p "$job1_pid" "$job2_pid" 2>/dev/null
        sleep 2
    done
}

# 7. Practical Examples
# ----------------

# Batch job processor
process_batch_jobs() {
    local job_file="$1"
    local max_jobs="${2:-3}"
    
    echo "Batch Job Processing:"
    echo "-------------------"
    
    # Read and execute jobs
    while IFS= read -r job; do
        # Wait if too many jobs
        while (($(jobs -r | wc -l) >= max_jobs)); do
            sleep 1
        done
        
        # Execute job
        (eval "$job") &
        echo "Started job: $job"
    done < "$job_file"
    
    # Wait for all jobs
    wait
    echo "All jobs completed"
}

# Job status monitor
monitor_job_status() {
    local duration="$1"
    local log_file="$2"
    
    echo "Job Status Monitoring:"
    echo "--------------------"
    
    {
        echo "=== Job Monitor Start: $(date) ==="
        
        local end=$((SECONDS + duration))
        while ((SECONDS < end)); do
            echo "--- $(date) ---"
            jobs -l
            sleep 1
        done
        
        echo "=== Job Monitor End: $(date) ==="
    } > "$log_file"
    
    echo "Monitoring complete. Check $log_file for details"
}

# Job completion checker
wait_for_jobs() {
    local timeout="$1"
    shift
    local job_ids=("$@")
    
    echo "Waiting for Jobs:"
    echo "---------------"
    
    local end=$((SECONDS + timeout))
    while ((SECONDS < end)); do
        local all_done=true
        for job_id in "${job_ids[@]}"; do
            if job_exists "$job_id"; then
                all_done=false
                break
            fi
        done
        
        if $all_done; then
            echo "All jobs completed"
            return 0
        fi
        
        sleep 1
    done
    
    echo "Timeout waiting for jobs"
    return 1
}

# Main execution
main() {
    # Create test job file
    cat > "$OUTPUT_DIR/jobs.txt" << 'EOF'
sleep 5 && echo "Job 1 done"
sleep 3 && echo "Job 2 done"
sleep 4 && echo "Job 3 done"
sleep 6 && echo "Job 4 done"
EOF
    
    # Run examples
    run_background_jobs
    echo -e "\n"
    
    control_jobs
    echo -e "\n"
    
    schedule_job 5 "echo 'Scheduled job executed'"
    echo -e "\n"
    
    set_job_priority "sleep 10" 15
    echo -e "\n"
    
    monitor_jobs
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    
    # Process batch jobs
    process_batch_jobs "$OUTPUT_DIR/jobs.txt" 2
    
    # Monitor job status
    monitor_job_status 10 "$LOG_DIR/job_status.log"
    
    # Wait for specific jobs
    sleep 10 &
    job1=%1
    sleep 15 &
    job2=%2
    wait_for_jobs 20 "$job1" "$job2"
}

# Run if executed directly
# Only run if script is executed directly
# This check is necessary because the script is meant to be sourced
# by other scripts, and we don't want to run the examples when sourced.
# When sourced, the value of $BASH_SOURCE[0] is the name of the script
# that sourced this one, so we need to check if it matches the name of
# this script ($0).
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
