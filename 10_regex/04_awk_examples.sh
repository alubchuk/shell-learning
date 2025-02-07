#!/bin/bash

# awk Examples
# ----------
# This script demonstrates various awk features and
# usage patterns for text processing.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly TEST_DIR="$OUTPUT_DIR/test_files"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$TEST_DIR"

# Create test files
create_test_files() {
    # Employee data
    cat > "$TEST_DIR/employees.txt" << 'EOF'
ID|Name|Department|Salary|StartDate
1|John Smith|Engineering|75000|2020-01-15
2|Jane Doe|Marketing|65000|2021-03-20
3|Bob Wilson|Engineering|80000|2019-11-10
4|Alice Brown|Sales|70000|2022-05-01
5|Charlie Davis|Marketing|62000|2021-08-15
6|Eve Wilson|Engineering|85000|2018-06-30
7|Frank Miller|Sales|72000|2020-09-22
8|Grace Lee|Marketing|68000|2021-11-05
EOF

    # Server log
    cat > "$TEST_DIR/server.log" << 'EOF'
2025-02-07 10:00:00 192.168.1.100 GET /index.html 200 2048
2025-02-07 10:00:01 192.168.1.101 POST /api/login 401 1024
2025-02-07 10:00:02 192.168.1.102 GET /images/logo.png 200 5120
2025-02-07 10:00:03 192.168.1.100 GET /css/style.css 200 1536
2025-02-07 10:00:04 192.168.1.103 GET /api/data 500 512
2025-02-07 10:00:05 192.168.1.101 GET /index.html 200 2048
2025-02-07 10:00:06 192.168.1.102 POST /api/upload 413 0
2025-02-07 10:00:07 192.168.1.100 GET /js/main.js 200 4096
EOF

    # Data file
    cat > "$TEST_DIR/data.txt" << 'EOF'
# Temperature readings
Location    Date        Time    Temp    Humidity
New York    2025-02-07  10:00   72.5    45
London      2025-02-07  15:00   68.0    55
Tokyo       2025-02-07  23:00   70.2    60
Paris       2025-02-07  16:00   71.8    50
Sydney      2025-02-07  06:00   75.5    65
EOF
}

# 1. Basic Operations
# ---------------

basic_operations() {
    echo "Basic Operations:"
    echo "----------------"
    
    # Print specific fields
    echo "1. Print name and salary:"
    awk -F'|' '{print $2, $4}' "$TEST_DIR/employees.txt"
    
    # Print with custom format
    echo -e "\n2. Format employee data:"
    awk -F'|' 'NR>1 {printf "Name: %-20s Salary: $%d\n", $2, $4}' "$TEST_DIR/employees.txt"
    
    # Line numbers
    echo -e "\n3. Add line numbers:"
    awk '{print NR ": " $0}' "$TEST_DIR/data.txt"
    
    # Field count
    echo -e "\n4. Show number of fields:"
    awk '{print "Line " NR " has " NF " fields"}' "$TEST_DIR/data.txt"
}

# 2. Pattern Matching
# ---------------

pattern_matching() {
    echo "Pattern Matching:"
    echo "----------------"
    
    # Simple pattern
    echo "1. Engineering department:"
    awk -F'|' '/Engineering/ {print $2}' "$TEST_DIR/employees.txt"
    
    # Multiple patterns
    echo -e "\n2. Marketing or Sales:"
    awk -F'|' '/Marketing|Sales/ {print $2, $3}' "$TEST_DIR/employees.txt"
    
    # Field matching
    echo -e "\n3. Salary > 75000:"
    awk -F'|' '$4 > 75000 {print $2, $4}' "$TEST_DIR/employees.txt"
    
    # Range patterns
    echo -e "\n4. Lines between patterns:"
    awk '/London/,/Tokyo/' "$TEST_DIR/data.txt"
}

# 3. Built-in Variables
# -----------------

builtin_variables() {
    echo "Built-in Variables:"
    echo "------------------"
    
    # File information
    echo "1. File processing info:"
    awk -F'|' '
        BEGIN {print "Starting processing..."}
        {total += $4}
        END {
            print "Records processed:", NR-1
            print "Average salary:", total/(NR-1)
            print "Done!"
        }
    ' "$TEST_DIR/employees.txt"
    
    # Field separator
    echo -e "\n2. Change separator:"
    awk 'BEGIN{FS="|"; OFS=","} {print $2, $3}' "$TEST_DIR/employees.txt"
    
    # Record number
    echo -e "\n3. Every other line:"
    awk 'NR % 2 == 0' "$TEST_DIR/data.txt"
    
    # Field count
    echo -e "\n4. Lines with 5 fields:"
    awk 'NF == 5' "$TEST_DIR/data.txt"
}

# 4. Calculations
# -----------

calculations() {
    echo "Calculations:"
    echo "-------------"
    
    # Sum and average
    echo "1. Salary statistics:"
    awk -F'|' '
        NR>1 {
            sum += $4
            if ($4 > max) max = $4
            if (min == 0 || $4 < min) min = $4
        }
        END {
            print "Total:", sum
            print "Average:", sum/(NR-1)
            print "Max:", max
            print "Min:", min
        }
    ' "$TEST_DIR/employees.txt"
    
    # Counting
    echo -e "\n2. Department counts:"
    awk -F'|' '
        NR>1 {count[$3]++}
        END {
            for (dept in count)
                print dept ":", count[dept]
        }
    ' "$TEST_DIR/employees.txt"
    
    # Percentage calculation
    echo -e "\n3. HTTP status distribution:"
    awk '
        {status[$6]++; total++}
        END {
            for (code in status)
                printf "%s: %.1f%%\n", code, (status[code]/total)*100
        }
    ' "$TEST_DIR/server.log"
}

# 5. Text Processing
# --------------

text_processing() {
    echo "Text Processing:"
    echo "---------------"
    
    # String functions
    echo "1. Name formatting:"
    awk -F'|' '
        NR>1 {
            split($2, name, " ")
            printf "%-10s %-15s\n", toupper(name[1]), tolower(name[2])
        }
    ' "$TEST_DIR/employees.txt"
    
    # Substring
    echo -e "\n2. Extract year from date:"
    awk -F'|' 'NR>1 {print substr($5, 1, 4)}' "$TEST_DIR/employees.txt"
    
    # String replacement
    echo -e "\n3. Replace department names:"
    awk -F'|' '{gsub("Engineering", "Eng."); print}' "$TEST_DIR/employees.txt"
    
    # Length functions
    echo -e "\n4. Name lengths:"
    awk -F'|' 'NR>1 {print $2, length($2)}' "$TEST_DIR/employees.txt"
}

# 6. Control Structures
# -----------------

control_structures() {
    echo "Control Structures:"
    echo "------------------"
    
    # If statement
    echo "1. Conditional processing:"
    awk -F'|' '
        NR>1 {
            if ($4 >= 80000)
                print $2, "- High salary"
            else if ($4 >= 70000)
                print $2, "- Medium salary"
            else
                print $2, "- Standard salary"
        }
    ' "$TEST_DIR/employees.txt"
    
    # For loop
    echo -e "\n2. Field iteration:"
    awk -F'|' '
        NR==1 {
            for (i=1; i<=NF; i++)
                print "Field", i ":", $i
        }
    ' "$TEST_DIR/employees.txt"
    
    # While loop
    echo -e "\n3. Temperature analysis:"
    awk '
        NR>2 {
            temp = $4
            sum += temp
            count++
            while (temp >= 70) {
                high_temps++
                break
            }
        }
        END {
            print "Average temp:", sum/count
            print "High temps:", high_temps
        }
    ' "$TEST_DIR/data.txt"
}

# 7. Arrays and Functions
# -------------------

arrays_and_functions() {
    echo "Arrays and Functions:"
    echo "-------------------"
    
    # Array operations
    echo "1. Department statistics:"
    awk -F'|' '
        function calc_avg(sum, count) {
            return sum/count
        }
        NR>1 {
            dept_count[$3]++
            dept_salary[$3] += $4
        }
        END {
            print "Department Statistics:"
            for (dept in dept_count) {
                avg = calc_avg(dept_salary[dept], dept_count[dept])
                printf "%-12s Count: %d  Avg Salary: $%.2f\n",
                    dept, dept_count[dept], avg
            }
        }
    ' "$TEST_DIR/employees.txt"
    
    # Multi-dimensional arrays
    echo -e "\n2. Employee tenure by department:"
    awk -F'|' '
        function years_employed(start_date) {
            split(start_date, date, "-")
            return 2025 - date[1]
        }
        NR>1 {
            dept = $3
            years = years_employed($5)
            dept_years[dept,years]++
        }
        END {
            print "Years of Service by Department:"
            for (key in dept_years) {
                split(key, parts, SUBSEP)
                printf "%-12s %d years: %d employees\n",
                    parts[1], parts[2], dept_years[key]
            }
        }
    ' "$TEST_DIR/employees.txt"
}

# 8. Practical Examples
# -----------------

# Generate employee report
generate_report() {
    local input="$1"
    awk -F'|' '
        BEGIN {
            print "Employee Report"
            print "==============="
            printf "%-20s %-15s %-12s %s\n",
                "Name", "Department", "Salary", "Years"
            print "------------------------------------------------"
        }
        NR>1 {
            split($5, date, "-")
            years = 2025 - date[1]
            printf "%-20s %-15s $%-11d %d\n",
                $2, $3, $4, years
        }
        END {
            print "------------------------------------------------"
        }
    ' "$input"
}

# Analyze log file
analyze_log() {
    local input="$1"
    awk '
        {
            # Count requests by IP
            ip_count[$3]++
            # Count status codes
            status[$6]++
            # Sum bytes by request type
            bytes[$4] += $7
        }
        END {
            print "Log Analysis Report"
            print "==================="
            
            print "\nRequests by IP:"
            for (ip in ip_count)
                printf "%-15s %d\n", ip, ip_count[ip]
            
            print "\nStatus Codes:"
            for (code in status)
                printf "%-5s %d\n", code, status[code]
            
            print "\nBytes by Request Type:"
            for (req in bytes)
                printf "%-6s %d\n", req, bytes[req]
        }
    ' "$input"
}

# Main execution
main() {
    # Create test files
    create_test_files
    
    # Run examples
    basic_operations
    echo -e "\n"
    pattern_matching
    echo -e "\n"
    builtin_variables
    echo -e "\n"
    calculations
    echo -e "\n"
    text_processing
    echo -e "\n"
    control_structures
    echo -e "\n"
    arrays_and_functions
    echo -e "\n"
    
    # Practical examples
    echo "Practical Examples:"
    echo "------------------"
    echo "1. Employee Report:"
    generate_report "$TEST_DIR/employees.txt"
    
    echo -e "\n2. Log Analysis:"
    analyze_log "$TEST_DIR/server.log"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
