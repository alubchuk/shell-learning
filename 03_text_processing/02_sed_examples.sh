#!/bin/bash

# Sed Examples
# -----------

SAMPLE_DIR="./sample_data"

# Create temporary files for demonstrations
cp "$SAMPLE_DIR/sample.txt" /tmp/sed_test.txt
cp "$SAMPLE_DIR/config.ini" /tmp/config_test.ini

echo "Sed Examples using sample files"
echo "------------------------------"

# Basic substitution
echo -e "\n1. Basic substitution (replace 'example' with 'demo'):"
sed 's/example/demo/' /tmp/sed_test.txt | head -n 5

# Global substitution (all occurrences in each line)
echo -e "\n2. Global substitution (replace all occurrences of 'line' with 'row'):"
sed 's/line/row/g' /tmp/sed_test.txt | grep -i "row"

# Case-insensitive substitution
echo -e "\n3. Case-insensitive substitution (replace 'LINE' with 'row' regardless of case):"
sed 's/line/row/gi' /tmp/sed_test.txt | grep -i "row"

# Delete lines
echo -e "\n4. Delete lines (remove empty lines):"
sed '/^$/d' /tmp/sed_test.txt

# Delete specific lines by number
echo -e "\n5. Delete specific lines (remove lines 2-4):"
sed '2,4d' /tmp/sed_test.txt | head -n 5

# Insert text before a line
echo -e "\n6. Insert text before a line (add comment before lines with 'http'):"
sed '/http/i\# Website URL:' /tmp/sed_test.txt | grep -A 1 "Website"

# Append text after a line
echo -e "\n7. Append text after a line (add note after lines with 'email'):"
sed '/email/a\# End of email line' /tmp/sed_test.txt | grep -A 1 "email"

# Replace whole line
echo -e "\n8. Replace whole line (replace lines containing 'Comment' with new text):"
sed '/Comment/c\This is a new comment line' /tmp/sed_test.txt | grep "new comment"

# Multiple commands using -e
echo -e "\n9. Multiple commands (uppercase first line, lowercase second line):"
sed -e '1s/.*/\U&/' -e '2s/.*/\L&/' /tmp/sed_test.txt | head -n 2

# Using address ranges
echo -e "\n10. Address ranges (add prefix to lines 3-5):"
sed '3,5s/^/>>> /' /tmp/sed_test.txt | head -n 6

# Using regular expressions in patterns
echo -e "\n11. Regular expressions (format dates):"
sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\3\/\2\/\1/g' /tmp/sed_test.txt | grep "/"

# Practical example: Modifying configuration files
echo -e "\n12. Modifying configuration files (update port numbers):"
sed 's/port = [0-9]\+/port = 9999/' /tmp/config_test.ini | grep "port"

# Working with groups and back-references
echo -e "\n13. Groups and back-references (reformat URLs):"
sed 's/\(https\?:\/\/\)\(www\.\)\?\([^[:space:]]\+\)/URL: \1\2\3/g' /tmp/sed_test.txt | grep "URL:"

# Conditional replacement (replace only if pattern matches)
echo -e "\n14. Conditional replacement (update only Database port):"
sed '/\[Database\]/,/\[.*\]/ s/port = [0-9]\+/port = 5433/' /tmp/config_test.ini | grep -A 5 "Database"

# Multiple file processing
echo -e "\n15. Multiple file processing (add headers to all .txt files):"
for file in /tmp/sed_test.txt; do
    sed -i.bak '1i\# File: '$(basename $file)'\n# Generated: '$(date) $file
done
head -n 3 /tmp/sed_test.txt

# Advanced example: Comment stripping
echo -e "\n16. Comment stripping (remove different types of comments):"
sed -e 's/\/\/.*$//' -e 's/\/\*.*\*\///' -e '/^#/d' /tmp/sed_test.txt | grep -v "^$"

# Clean up temporary files
rm /tmp/sed_test.txt* /tmp/config_test.ini

echo -e "\nNote: These examples demonstrate sed commands without modifying original files."
echo "In real usage, add -i flag to modify files in-place: sed -i 's/old/new/g' file"
