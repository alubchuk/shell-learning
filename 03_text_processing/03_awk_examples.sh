#!/bin/bash

# Awk Examples
# -----------

SAMPLE_DIR="./sample_data"

echo "Awk Examples using sample files"
echo "-----------------------------"

# Basic field printing
echo -e "\n1. Basic field printing (print first and last fields of CSV):"
awk -F',' '{print "Name:", $2, "- Start Date:", $NF}' "$SAMPLE_DIR/data.csv"

# Line filtering
echo -e "\n2. Line filtering (show Engineering department entries):"
awk -F',' '$3 == "Engineering" {print $0}' "$SAMPLE_DIR/data.csv"

# Calculations
echo -e "\n3. Calculate average salary:"
awk -F',' 'NR>1 {sum += $4; count++} END {print "Average Salary:", sum/count}' "$SAMPLE_DIR/data.csv"

# Pattern matching
echo -e "\n4. Pattern matching (find lines containing 'example' in sample.txt):"
awk '/example/ {print NR ":", $0}' "$SAMPLE_DIR/sample.txt"

# Built-in variables
echo -e "\n5. Using built-in variables (line number, field count, etc.):"
awk -F',' 'BEGIN {print "File Analysis:"} 
    {print "Line", NR ":", NF, "fields"}
    END {print "Total lines:", NR}' "$SAMPLE_DIR/data.csv" | head -n 5

# Custom field separator with regular expression
echo -e "\n6. Parse log file entries:"
awk '{ split($4,date,"["); split($7,status," "); 
    print date[2], status[1] }' "$SAMPLE_DIR/access.log" | head -n 5

# Conditional statements
echo -e "\n7. Conditional processing (high salary employees):"
awk -F',' 'NR>1 && $4 > 75000 {print $2, "($" $4 ")"}' "$SAMPLE_DIR/data.csv"

# Multiple patterns and actions
echo -e "\n8. Department statistics:"
awk -F',' 'BEGIN {print "Department Statistics:"}
    NR>1 {
        dept[$3]++
        salary[$3] += $4
    }
    END {
        print "\nDepartment Counts:"
        for (d in dept) 
            print d ":", dept[d], "employees"
        print "\nAverage Salaries:"
        for (d in salary)
            printf "%s: $%.2f\n", d, salary[d]/dept[d]
    }' "$SAMPLE_DIR/data.csv"

# String manipulation
echo -e "\n9. String manipulation (extract domains from emails):"
awk '/email/ {
    for (i=1; i<=NF; i++) {
        if (match($i, /@[^[:space:]]+/)) {
            domain = substr($i, RSTART+1)
            print "Domain:", domain
        }
    }
}' "$SAMPLE_DIR/sample.txt"

# Custom functions
echo -e "\n10. Custom function (format currency):"
awk -F',' '
    function format_currency(amount) {
        return sprintf("$%\047d", amount)
    }
    NR>1 {print $2, format_currency($4)}
' "$SAMPLE_DIR/data.csv" | head -n 5

# Processing configuration files
echo -e "\n11. Parse INI file sections:"
awk '/^\[/ {
    section=$0
    next
}
/=/ {
    split($0,pair,"=")
    printf "%s: Parameter: %-20s Value: %s\n", 
        substr(section,2,length(section)-2),
        pair[1], pair[2]
}' "$SAMPLE_DIR/config.ini" | head -n 5

# Advanced log analysis
echo -e "\n12. Advanced log analysis (HTTP response codes summary):"
awk '{ 
    split($9,status," ")
    codes[status[1]]++
}
END {
    print "\nHTTP Response Codes Summary:"
    for (code in codes)
        printf "HTTP %s: %d requests\n", code, codes[code]
}' "$SAMPLE_DIR/access.log"

# Generate HTML report
echo -e "\n13. Generate HTML report of salary data:"
awk -F',' 'BEGIN {
    print "<table border=\"1\">"
    print "<tr><th>Name</th><th>Department</th><th>Salary</th></tr>"
}
NR>1 {
    printf "<tr><td>%s</td><td>%s</td><td>$%s</td></tr>\n",
        $2, $3, $4
}
END {
    print "</table>"
}' "$SAMPLE_DIR/data.csv" > /tmp/salary_report.html
echo "HTML report generated at /tmp/salary_report.html"

# Advanced data processing
echo -e "\n14. Salary statistics by department and date:"
awk -F',' 'NR>1 {
    # Parse date
    split($5,date,"-")
    month = date[2]
    
    # Accumulate statistics
    dept_month_count[sprintf("%s-%s",$3,month)]++
    dept_month_salary[sprintf("%s-%s",$3,month)] += $4
}
END {
    print "\nMonthly Department Statistics:"
    for (dm in dept_month_count) {
        split(dm,parts,"-")
        printf "%-12s Month %-2s: %2d employees, Avg Salary: $%.2f\n",
            parts[1],
            parts[2],
            dept_month_count[dm],
            dept_month_salary[dm]/dept_month_count[dm]
    }
}' "$SAMPLE_DIR/data.csv"
