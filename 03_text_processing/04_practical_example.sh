#!/bin/bash

# Log Analysis and Reporting Tool
# -----------------------------
# This script demonstrates practical usage of grep, sed, and awk
# to analyze log files and generate reports

SAMPLE_DIR="./sample_data"
REPORT_DIR="/tmp/log_analysis"
mkdir -p "$REPORT_DIR"

# Function to display script usage
show_help() {
    cat << EOF
Log Analysis and Reporting Tool
Usage: $0 [option]
Options:
    -a, --access     : Analyze web server access logs
    -c, --config     : Analyze configuration files
    -d, --data       : Analyze CSV data
    -h, --help       : Show this help message
EOF
}

# Function to analyze access logs
analyze_access_log() {
    local log_file="$SAMPLE_DIR/access.log"
    local report_file="$REPORT_DIR/access_report.txt"

    echo "Analyzing access log: $log_file"
    echo "Generating report: $report_file"
    
    {
        echo "=== Access Log Analysis Report ==="
        echo "Generated: $(date)"
        echo "================================="
        echo
        
        # HTTP Response Code Summary
        echo "1. HTTP Response Code Summary:"
        echo "-----------------------------"
        awk '{ 
            split($9,status," ")
            codes[status[1]]++
        }
        END {
            for (code in codes)
                printf "HTTP %s: %d requests\n", code, codes[code]
        }' "$log_file"
        echo
        
        # Top IP Addresses
        echo "2. Top 5 IP Addresses:"
        echo "---------------------"
        awk '{print $1}' "$log_file" | sort | uniq -c | sort -nr | head -n 5
        echo
        
        # Most Requested URLs
        echo "3. Top 5 Requested URLs:"
        echo "-----------------------"
        awk '{print $7}' "$log_file" | sort | uniq -c | sort -nr | head -n 5
        echo
        
        # Error Requests
        echo "4. Error Requests (HTTP 4xx, 5xx):"
        echo "--------------------------------"
        grep -E 'HTTP/1.1\" [45][0-9]{2}' "$log_file"
        echo
        
        # Traffic by Hour
        echo "5. Traffic Distribution by Hour:"
        echo "------------------------------"
        awk '{
            split($4,datetime,":")
            hour[datetime[2]]++
        }
        END {
            for (h in hour)
                printf "%s:00 - %d requests\n", h, hour[h]
        }' "$log_file" | sort
        
    } > "$report_file"
    
    echo "Access log analysis complete. Report generated at: $report_file"
}

# Function to analyze configuration files
analyze_config() {
    local config_file="$SAMPLE_DIR/config.ini"
    local report_file="$REPORT_DIR/config_report.txt"

    echo "Analyzing configuration: $config_file"
    echo "Generating report: $report_file"
    
    {
        echo "=== Configuration Analysis Report ==="
        echo "Generated: $(date)"
        echo "==================================="
        echo
        
        # Extract and format sections
        echo "1. Configuration Sections:"
        echo "------------------------"
        grep '^\[.*\]' "$config_file" | sed 's/[][]//g'
        echo
        
        # Security settings
        echo "2. Security-related Settings:"
        echo "---------------------------"
        sed -n '/\[Security\]/,/\[/p' "$config_file" | grep -v '^\['
        echo
        
        # Port configurations
        echo "3. Port Configurations:"
        echo "---------------------"
        grep -i "port" "$config_file"
        echo
        
        # Detailed section analysis
        echo "4. Section Details:"
        echo "-----------------"
        awk '
        /^\[/ {
            section=$0
            print "\nSection:", substr(section,2,length(section)-2)
            next
        }
        /=/ {
            split($0,pair,"=")
            printf "  %-20s = %s\n", pair[1], pair[2]
        }' "$config_file"
        
    } > "$report_file"
    
    echo "Configuration analysis complete. Report generated at: $report_file"
}

# Function to analyze CSV data
analyze_data() {
    local data_file="$SAMPLE_DIR/data.csv"
    local report_file="$REPORT_DIR/data_report.txt"

    echo "Analyzing data: $data_file"
    echo "Generating report: $report_file"
    
    {
        echo "=== Data Analysis Report ==="
        echo "Generated: $(date)"
        echo "=========================="
        echo
        
        # Department Summary
        echo "1. Department Summary:"
        echo "--------------------"
        awk -F',' '
        NR>1 {
            dept[$3]++
            salary[$3] += $4
        }
        END {
            printf "\nDepartment Statistics:\n"
            for (d in dept) {
                printf "%-12s: %d employees, Average Salary: $%.2f\n",
                    d, dept[d], salary[d]/dept[d]
            }
        }' "$data_file"
        echo
        
        # Salary Ranges
        echo "2. Salary Distribution:"
        echo "---------------------"
        awk -F',' '
        NR>1 {
            if ($4 < 70000) range["<70k"]++
            else if ($4 < 80000) range["70k-80k"]++
            else range[">80k"]++
        }
        END {
            for (r in range)
                printf "%-8s: %d employees\n", r, range[r]
        }' "$data_file"
        echo
        
        # Recent Hires
        echo "3. Most Recent Hires:"
        echo "-------------------"
        sort -t',' -k5 -r "$data_file" | head -n 6 | sed 1d | 
            awk -F',' '{printf "%-20s %-12s %s\n", $2, $3, $5}'
        echo
        
        # Generate HTML Summary
        echo "4. Generating HTML Summary..."
        awk -F',' '
        BEGIN {
            print "<html><body>"
            print "<h2>Employee Data Summary</h2>"
            print "<table border=\"1\">"
            print "<tr><th>Name</th><th>Department</th><th>Salary</th><th>Start Date</th></tr>"
        }
        NR>1 {
            printf "<tr><td>%s</td><td>%s</td><td>$%s</td><td>%s</td></tr>\n",
                $2, $3, $4, $5
        }
        END {
            print "</table></body></html>"
        }' "$data_file" > "$REPORT_DIR/data_summary.html"
        echo "HTML summary generated at: $REPORT_DIR/data_summary.html"
        
    } > "$report_file"
    
    echo "Data analysis complete. Report generated at: $report_file"
}

# Main script logic
case "$1" in
    -a|--access)
        analyze_access_log
        ;;
    -c|--config)
        analyze_config
        ;;
    -d|--data)
        analyze_data
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Error: Invalid option"
        show_help
        exit 1
        ;;
esac
