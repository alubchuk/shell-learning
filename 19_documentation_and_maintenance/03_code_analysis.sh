#!/bin/bash

# =============================================================================
# Shell Script Analysis Examples
# This script demonstrates tools and techniques for analyzing shell scripts,
# including static analysis, performance profiling, and monitoring.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Static Analysis Tools
# -----------------------------------------------------------------------------

# Run static analysis using shellcheck
analyze_script() {
    local script_path=$1
    local report_dir=${2:-"reports"}
    
    echo "=== Analyzing script: $script_path ==="
    
    # Create reports directory
    mkdir -p "$report_dir"
    
    # Run shellcheck with all checks enabled
    echo "Running shellcheck analysis..."
    shellcheck \
        --shell=bash \
        --severity=style \
        --format=json \
        --enable=all \
        "$script_path" > "${report_dir}/shellcheck.json"
    
    # Generate HTML report if available
    if command -v pandoc >/dev/null 2>&1; then
        {
            echo "# ShellCheck Analysis Report"
            echo "## Script: $script_path"
            echo "## Date: $(date)"
            echo
            echo "## Findings"
            echo
            jq -r '.[] | "### " + .level + ": " + .message + "\n" +
                "- File: " + .file + "\n" +
                "- Line: " + (.line | tostring) + "\n" +
                "- Column: " + (.column | tostring) + "\n" +
                "- Code: " + .code + "\n" +
                "```bash\n" + .fix.replacements[0].original + "```\n"' \
                "${report_dir}/shellcheck.json"
        } > "${report_dir}/shellcheck.md"
        
        pandoc "${report_dir}/shellcheck.md" \
            -f markdown \
            -t html \
            -s \
            --metadata title="ShellCheck Analysis Report" \
            --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css \
            -o "${report_dir}/shellcheck.html"
    fi
}

# Analyze script complexity
analyze_complexity() {
    local script_path=$1
    local report_dir=${2:-"reports"}
    
    echo -e "\n=== Analyzing script complexity: $script_path ==="
    
    mkdir -p "$report_dir"
    
    # Count lines of code
    echo "Lines of code statistics:"
    {
        echo "Category,Count"
        echo "Total lines,$(wc -l < "$script_path")"
        echo "Code lines,$(grep -v '^[[:space:]]*#' "$script_path" | grep -v '^[[:space:]]*$' | wc -l)"
        echo "Comment lines,$(grep '^[[:space:]]*#' "$script_path" | wc -l)"
        echo "Blank lines,$(grep '^[[:space:]]*$' "$script_path" | wc -l)"
        echo "Function count,$(grep -c '^[[:space:]]*[a-zA-Z0-9_]\+()' "$script_path")"
    } > "${report_dir}/complexity.csv"
    
    # Analyze function complexity
    {
        echo "# Function Complexity Analysis"
        echo "## Script: $script_path"
        echo "## Date: $(date)"
        echo
        echo "| Function | Lines | Parameters | Conditionals | Loops |"
        echo "|----------|-------|------------|--------------|-------|"
        
        # Extract and analyze each function
        awk '/^[a-zA-Z0-9_]+\(\)/ {
            if (func_name) {
                print func_body
            }
            func_name = $1
            func_body = ""
            next
        }
        /^}/ {
            if (func_name) {
                print func_body
                func_name = ""
            }
            next
        }
        func_name {
            func_body = func_body "\n" $0
        }' "$script_path" | while read -r func; do
            name=$(echo "$func" | head -n1 | cut -d'(' -f1)
            lines=$(echo "$func" | wc -l)
            params=$(echo "$func" | grep -c '\$[0-9]\+')
            conditionals=$(echo "$func" | grep -c '\<if\>|\<case\>')
            loops=$(echo "$func" | grep -c '\<while\>|\<for\>|\<until\>')
            echo "| $name | $lines | $params | $conditionals | $loops |"
        done
    } > "${report_dir}/complexity.md"
    
    # Convert to HTML if pandoc is available
    if command -v pandoc >/dev/null 2>&1; then
        pandoc "${report_dir}/complexity.md" \
            -f markdown \
            -t html \
            -s \
            --metadata title="Script Complexity Analysis" \
            --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css \
            -o "${report_dir}/complexity.html"
    fi
}

# -----------------------------------------------------------------------------
# Performance Profiling
# -----------------------------------------------------------------------------

# Profile script execution
profile_script() {
    local script_path=$1
    local report_dir=${2:-"reports"}
    
    echo -e "\n=== Profiling script: $script_path ==="
    
    mkdir -p "$report_dir"
    
    # Use 'time' for basic timing
    echo "Basic timing analysis:"
    /usr/bin/time -p bash "$script_path" 2> "${report_dir}/time.txt"
    
    # Use PS4 to trace execution with timestamps
    echo -e "\nDetailed execution trace:"
    {
        echo "timestamp command"
        PS4='$(date "+%s.%N") ' bash -x "$script_path" 2>&1 | grep '^[0-9]'
    } > "${report_dir}/trace.csv"
    
    # Generate flame graph if available
    if command -v flamegraph.pl >/dev/null 2>&1; then
        perf record -F 99 -g -- bash "$script_path"
        perf script | stackcollapse-perf.pl | flamegraph.pl > "${report_dir}/flamegraph.svg"
    fi
}

# -----------------------------------------------------------------------------
# Runtime Monitoring
# -----------------------------------------------------------------------------

# Monitor script execution
monitor_script() {
    local script_path=$1
    local report_dir=${2:-"reports"}
    local interval=${3:-1}
    
    echo -e "\n=== Monitoring script execution: $script_path ==="
    
    mkdir -p "$report_dir"
    
    # Start monitoring in background
    {
        echo "timestamp,cpu,memory,disk_read,disk_write,open_files"
        while true; do
            # Get process ID of running script
            pid=$(pgrep -f "bash $script_path" || true)
            if [ -n "$pid" ]; then
                # Collect metrics
                timestamp=$(date +%s)
                cpu=$(ps -p "$pid" -o %cpu | tail -n1)
                memory=$(ps -p "$pid" -o rss | tail -n1)
                read_bytes=$(awk '/read_bytes/{print $2}' "/proc/$pid/io" 2>/dev/null || echo 0)
                write_bytes=$(awk '/write_bytes/{print $2}' "/proc/$pid/io" 2>/dev/null || echo 0)
                open_files=$(lsof -p "$pid" | wc -l)
                
                echo "$timestamp,$cpu,$memory,$read_bytes,$write_bytes,$open_files"
            else
                break
            fi
            sleep "$interval"
        done
    } > "${report_dir}/metrics.csv" &
    monitor_pid=$!
    
    # Run the script
    bash "$script_path"
    
    # Stop monitoring
    kill "$monitor_pid" 2>/dev/null || true
    
    # Generate monitoring report
    {
        echo "# Script Monitoring Report"
        echo "## Script: $script_path"
        echo "## Date: $(date)"
        echo
        echo "## Resource Usage Summary"
        echo
        echo "### CPU Usage"
        echo "\`\`\`"
        awk -F, 'NR>1 {sum+=$2; count++} END {print "Average CPU: " sum/count "%"}' "${report_dir}/metrics.csv"
        echo "\`\`\`"
        echo
        echo "### Memory Usage"
        echo "\`\`\`"
        awk -F, 'NR>1 {sum+=$3; count++} END {print "Average Memory: " sum/count/1024 " MB"}' "${report_dir}/metrics.csv"
        echo "\`\`\`"
        echo
        echo "### I/O Activity"
        echo "\`\`\`"
        awk -F, 'NR>1 {read=$4; write=$5} END {print "Total Read: " read/1024/1024 " MB\nTotal Write: " write/1024/1024 " MB"}' "${report_dir}/metrics.csv"
        echo "\`\`\`"
    } > "${report_dir}/monitoring.md"
    
    # Convert to HTML if pandoc is available
    if command -v pandoc >/dev/null 2>&1; then
        pandoc "${report_dir}/monitoring.md" \
            -f markdown \
            -t html \
            -s \
            --metadata title="Script Monitoring Report" \
            --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css \
            -o "${report_dir}/monitoring.html"
    fi
}

# -----------------------------------------------------------------------------
# Code Quality Metrics
# -----------------------------------------------------------------------------

# Calculate code quality metrics
analyze_quality() {
    local script_path=$1
    local report_dir=${2:-"reports"}
    
    echo -e "\n=== Analyzing code quality: $script_path ==="
    
    mkdir -p "$report_dir"
    
    # Calculate various metrics
    {
        echo "# Code Quality Analysis"
        echo "## Script: $script_path"
        echo "## Date: $(date)"
        echo
        echo "## Metrics"
        echo
        echo "### Style Compliance"
        echo "- ShellCheck violations: $(shellcheck "$script_path" | wc -l)"
        echo "- Incorrect indentation: $(grep -c '^[ ]' "$script_path")"
        echo "- Long lines (>80 chars): $(awk 'length>80' "$script_path" | wc -l)"
        echo
        echo "### Documentation"
        echo "- Comment ratio: $(awk 'NF{c++}END{print c}' "$script_path") lines of code / $(grep -c '^[[:space:]]*#' "$script_path") comments"
        echo "- Undocumented functions: $(grep -c '^[a-zA-Z0-9_]\+()' "$script_path")"
        echo
        echo "### Complexity"
        echo "- Maximum function length: $(awk '/^[a-zA-Z0-9_]+\(\)/{count=0;while(getline && !/^}/){count++}if(count>max){max=count}}END{print max}' "$script_path")"
        echo "- Nested conditions: $(grep -c '  if\|  case' "$script_path")"
        echo
        echo "### Best Practices"
        echo "- Use of 'eval': $(grep -c '\<eval\>' "$script_path")"
        echo "- Use of 'exit' in functions: $(grep -c '\<exit\>' "$script_path")"
        echo "- Hardcoded paths: $(grep -c '/[a-zA-Z]' "$script_path")"
    } > "${report_dir}/quality.md"
    
    # Convert to HTML if pandoc is available
    if command -v pandoc >/dev/null 2>&1; then
        pandoc "${report_dir}/quality.md" \
            -f markdown \
            -t html \
            -s \
            --metadata title="Code Quality Analysis" \
            --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css \
            -o "${report_dir}/quality.html"
    fi
}

# -----------------------------------------------------------------------------
# Main Script
# -----------------------------------------------------------------------------

main() {
    echo "Starting code analysis demonstration..."
    
    # Create reports directory
    local report_dir="reports/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$report_dir"
    
    # Analyze this script
    analyze_script "$0" "$report_dir"
    analyze_complexity "$0" "$report_dir"
    profile_script "$0" "$report_dir"
    analyze_quality "$0" "$report_dir"
    
    echo -e "\nCode analysis demonstration completed."
    echo "Reports available in $report_dir"
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
