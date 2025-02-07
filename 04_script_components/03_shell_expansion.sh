#!/bin/bash

# Shell Expansion Examples
# ----------------------

# Function to display section headers
print_header() {
    echo -e "\n=== $1 ==="
    echo "----------------"
}

# 1. Brace Expansion
print_header "Brace Expansion"

echo "Simple sequence:"
echo {1..5}

echo -e "\nPadded sequence:"
echo {01..10}

echo -e "\nAlphabetic sequence:"
echo {a..e}

echo -e "\nStep sequence:"
echo {0..10..2}

echo -e "\nCombined sequences:"
echo {{A..C},{1..3}}

echo -e "\nString combinations:"
echo file{.txt,.pdf,.doc}

# 2. Tilde Expansion
print_header "Tilde Expansion"

echo "Home directory: ~"
echo "Current user's home: $HOME"
echo "Previous working directory: ~-"
echo "Current working directory: ~+"

# 3. Parameter Expansion
print_header "Parameter Expansion"

# Basic variable usage
NAME="John Doe"
echo "Basic variable: $NAME"
echo "With braces: ${NAME}"

# String length
echo "String length: ${#NAME}"

# Substring extraction
echo "First 4 characters: ${NAME:0:4}"
echo "From position 5: ${NAME:5}"
echo "Last 3 characters: ${NAME: -3}"

# Default values
unset UNDEFINED_VAR
echo "Default if unset: ${UNDEFINED_VAR:-default value}"
echo "Default if null or unset: ${EMPTY_VAR:-default value}"

# Assign default
echo "Assign default if unset: ${UNDEFINED_VAR:=new value}"
echo "UNDEFINED_VAR is now: $UNDEFINED_VAR"

# Error if unset
echo "Testing error if unset..."
# Commented out to avoid script termination
# echo ${REQUIRED_VAR:?must be set}

# Use alternate value
ALT_VAR="original"
echo "Alternate value: ${ALT_VAR:+replacement}"

# 4. Pattern Matching
print_header "Pattern Matching"

FILENAME="script.test.sh"

# Remove shortest match from beginning
echo "Remove .sh: ${FILENAME%.sh}"

# Remove longest match from beginning
echo "Remove everything after first dot: ${FILENAME%%.*}"

# Remove shortest match from end
echo "Remove first extension: ${FILENAME#*.}"

# Remove longest match from end
echo "Remove all extensions: ${FILENAME##*.}"

# 5. Search and Replace
print_header "Search and Replace"

TEXT="hello hello world"

# Replace first match
echo "Replace first 'hello': ${TEXT/hello/hi}"

# Replace all matches
echo "Replace all 'hello': ${TEXT//hello/hi}"

# Replace at beginning
echo "Replace at beginning: ${TEXT/#hello/hi}"

# Replace at end
echo "Replace at end: ${TEXT/%world/everyone}"

# 6. Case Modification
print_header "Case Modification"

MIXED="Hello World"

# Convert first character to uppercase/lowercase
echo "First char uppercase: ${MIXED^}"
echo "First char lowercase: ${MIXED,}"

# Convert all characters to uppercase/lowercase
echo "All uppercase: ${MIXED^^}"
echo "All lowercase: ${MIXED,,}"

# 7. Command Substitution
print_header "Command Substitution"

echo "Current date: $(date)"
echo "Files in current directory: $(ls | wc -l)"

# Difference between `` and $()
echo "Using backticks: `echo \`hostname\``"
echo "Using \$(): $(echo $(hostname))"

# 8. Arithmetic Expansion
print_header "Arithmetic Expansion"

A=5
B=3

echo "Addition: $((A + B))"
echo "Subtraction: $((A - B))"
echo "Multiplication: $((A * B))"
echo "Division: $((A / B))"
echo "Modulus: $((A % B))"
echo "Power: $((A ** B))"

# Complex arithmetic
echo "Complex: $(( (A + B) * 2 ))"

# Increment/Decrement
echo "Pre-increment: $((++A))"
echo "Post-decrement: $((B--))"

# 9. Word Splitting
print_header "Word Splitting"

# Default IFS behavior
echo "Default IFS splitting:"
WORDS="apple banana cherry"
for word in $WORDS; do
    echo "  Word: $word"
done

# Custom IFS
echo -e "\nCustom IFS splitting:"
OLD_IFS="$IFS"
IFS=","
FRUITS="apple,banana,cherry"
for fruit in $FRUITS; do
    echo "  Fruit: $fruit"
done
IFS="$OLD_IFS"

# 10. Pathname Expansion (Globbing)
print_header "Pathname Expansion"

# Create some test files
touch /tmp/test{1..3}.txt
touch /tmp/test{a..c}.log

echo "Text files:"
echo /tmp/test*.txt

echo -e "\nLog files:"
echo /tmp/test?.log

echo -e "\nAll test files:"
echo /tmp/test*

# Cleanup
rm /tmp/test{1..3}.txt /tmp/test{a..c}.log

# 11. Process Substitution
print_header "Process Substitution"

echo -e "Line 1\nLine 2\nLine 3" > /tmp/file1.txt
echo -e "Line 2\nLine 3\nLine 4" > /tmp/file2.txt

echo "Comparing two commands output:"
diff <(sort /tmp/file1.txt) <(sort /tmp/file2.txt)

# Cleanup
rm /tmp/file1.txt /tmp/file2.txt

# 12. Here Documents and Here Strings
print_header "Here Documents and Here Strings"

# Here document
cat << EOF
This is a here document.
It can span multiple lines.
Variables are expanded: $HOME
EOF

# Here document with quoted delimiter (no expansion)
cat << 'EOF'
This is a quoted here document.
Variables are not expanded: $HOME
EOF

# Here string
echo "Here string example:"
grep "world" <<< "hello world"
