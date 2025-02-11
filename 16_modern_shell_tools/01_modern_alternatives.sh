#!/bin/bash

# =============================================================================
# Modern CLI Tool Examples
# This script demonstrates usage of modern alternatives to traditional Unix tools,
# showing how they can improve productivity and provide better user experience.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: check_tools
# Purpose: Check if required modern tools are installed
# Arguments: None
# Returns: 0 if all tools are available, 1 otherwise
# -----------------------------------------------------------------------------
check_tools() {
    local -A tools=(
        ["fd"]="find alternative"
        ["rg"]="grep alternative"
        ["bat"]="cat alternative"
        ["exa"]="ls alternative"
        ["delta"]="diff alternative"
        ["fzf"]="fuzzy finder"
        ["zoxide"]="cd alternative"
    )
    
    local missing=0
    
    echo "Checking for modern CLI tools..."
    for tool in "${!tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "✓ $tool (${tools[$tool]}) is installed"
        else
            echo "✗ $tool (${tools[$tool]}) is NOT installed"
            missing=1
        fi
    done
    
    if ((missing)); then
        echo -e "\nSome tools are missing. Install them with:"
        echo "brew install fd ripgrep bat exa git-delta fzf zoxide  # macOS"
        echo "apt install fd-find ripgrep bat exa delta fzf  # Ubuntu/Debian"
        return 1
    fi
    
    return 0
}

# -----------------------------------------------------------------------------
# Function: demonstrate_fd
# Purpose: Show fd usage compared to find
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_fd() {
    echo -e "\n=== fd (Modern find) Examples ==="
    
    # Create test directory structure
    mkdir -p /tmp/fd_test/{src,docs}/{js,py,md}
    touch /tmp/fd_test/src/js/{app,utils,main}.js
    touch /tmp/fd_test/src/py/{app,utils,main}.py
    touch /tmp/fd_test/docs/md/{readme,guide,api}.md
    
    echo "1. Find all Python files"
    echo "Traditional find:"
    time find /tmp/fd_test -name "*.py"
    
    echo -e "\nModern fd:"
    time fd -t f "\.py$" /tmp/fd_test
    
    echo -e "\n2. Find files modified in the last day"
    echo "Traditional find:"
    time find /tmp/fd_test -type f -mtime -1
    
    echo -e "\nModern fd:"
    time fd -t f --changed-within 1d /tmp/fd_test
    
    # Clean up
    rm -rf /tmp/fd_test
}

# -----------------------------------------------------------------------------
# Function: demonstrate_ripgrep
# Purpose: Show ripgrep usage compared to grep
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_ripgrep() {
    echo -e "\n=== ripgrep (Modern grep) Examples ==="
    
    # Create test files
    mkdir -p /tmp/rg_test
    cat << 'EOF' > /tmp/rg_test/example.py
def hello_world():
    print("Hello, World!")
    # TODO: Add more features
EOF
    
    cat << 'EOF' > /tmp/rg_test/example.js
function helloWorld() {
    console.log("Hello, World!");
    // TODO: Add error handling
}
EOF
    
    echo "1. Search for pattern with context"
    echo "Traditional grep:"
    time grep -r -n -C 1 "TODO" /tmp/rg_test
    
    echo -e "\nModern ripgrep:"
    time rg -n -C 1 "TODO" /tmp/rg_test
    
    echo -e "\n2. Search only specific file types"
    echo "Traditional grep:"
    time find /tmp/rg_test -name "*.py" -exec grep -l "print" {} \;
    
    echo -e "\nModern ripgrep:"
    time rg -t py "print" /tmp/rg_test
    
    # Clean up
    rm -rf /tmp/rg_test
}

# -----------------------------------------------------------------------------
# Function: demonstrate_bat
# Purpose: Show bat usage compared to cat
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_bat() {
    echo -e "\n=== bat (Modern cat) Examples ==="
    
    # Create test file
    cat << 'EOF' > /tmp/example.py
#!/usr/bin/env python3
"""
Example module demonstrating bat features.
"""

def main():
    # Initialize variables
    count = 0
    
    # Main loop
    for i in range(10):
        count += i
        print(f"Count: {count}")

if __name__ == "__main__":
    main()
EOF
    
    echo "1. View file with syntax highlighting"
    echo "Traditional cat:"
    cat /tmp/example.py
    
    echo -e "\nModern bat:"
    bat --style=plain /tmp/example.py
    
    echo -e "\n2. Show non-printing characters"
    echo "Traditional cat:"
    cat -A /tmp/example.py
    
    echo -e "\nModern bat:"
    bat --show-all /tmp/example.py
    
    # Clean up
    rm /tmp/example.py
}

# -----------------------------------------------------------------------------
# Function: demonstrate_exa
# Purpose: Show exa usage compared to ls
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_exa() {
    echo -e "\n=== exa (Modern ls) Examples ==="
    
    # Create test directory structure
    mkdir -p /tmp/exa_test/{docs,src}/{js,css}
    touch /tmp/exa_test/docs/readme.md
    touch /tmp/exa_test/src/js/main.js
    touch /tmp/exa_test/src/css/style.css
    ln -s /tmp/exa_test/src/js/main.js /tmp/exa_test/src/js/link.js
    
    echo "1. List files with details"
    echo "Traditional ls:"
    ls -la /tmp/exa_test
    
    echo -e "\nModern exa:"
    exa -la /tmp/exa_test
    
    echo -e "\n2. Tree view"
    echo "Traditional tree:"
    tree /tmp/exa_test 2>/dev/null || echo "tree command not found"
    
    echo -e "\nModern exa:"
    exa --tree /tmp/exa_test
    
    # Clean up
    rm -rf /tmp/exa_test
}

# -----------------------------------------------------------------------------
# Function: demonstrate_delta
# Purpose: Show delta usage compared to diff
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_delta() {
    echo -e "\n=== delta (Modern diff) Examples ==="
    
    # Create test files
    cat << 'EOF' > /tmp/file1.txt
Hello World
This is a test
Line to change
Line to remove
Final line
EOF
    
    cat << 'EOF' > /tmp/file2.txt
Hello World
This is a test
Line that changed
Final line
Added line
EOF
    
    echo "1. Compare files"
    echo "Traditional diff:"
    diff /tmp/file1.txt /tmp/file2.txt
    
    echo -e "\nModern delta:"
    delta /tmp/file1.txt /tmp/file2.txt
    
    # Clean up
    rm /tmp/file{1,2}.txt
}

# -----------------------------------------------------------------------------
# Function: demonstrate_fzf
# Purpose: Show fzf fuzzy finder usage
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_fzf() {
    echo -e "\n=== fzf (Fuzzy Finder) Examples ==="
    
    # Create test files
    mkdir -p /tmp/fzf_test
    for i in {1..20}; do
        echo "Content for file $i" > "/tmp/fzf_test/example_$i.txt"
    done
    
    echo "1. Interactive file selection (press CTRL-C to exit):"
    find /tmp/fzf_test -type f | fzf --preview 'cat {}'
    
    echo -e "\n2. History search (press CTRL-C to exit):"
    history | fzf --tac --no-sort
    
    # Clean up
    rm -rf /tmp/fzf_test
}

# -----------------------------------------------------------------------------
# Function: demonstrate_zoxide
# Purpose: Show zoxide usage compared to cd
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_zoxide() {
    echo -e "\n=== zoxide (Modern cd) Examples ==="
    
    # Create test directories
    mkdir -p /tmp/zoxide_test/{project1,project2}/{src,docs}
    
    echo "1. Traditional cd navigation:"
    cd /tmp/zoxide_test/project1/src
    pwd
    cd ../..
    cd project2/docs
    pwd
    cd /tmp
    
    echo -e "\n2. Zoxide navigation (after learning):"
    echo "z project1  # Jump to project1"
    echo "z src      # Jump to src directory"
    echo "zi        # Interactive selection"
    
    # Clean up
    rm -rf /tmp/zoxide_test
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting modern CLI tools demonstration..."
    
    # Check for required tools
    if ! check_tools; then
        echo "Please install missing tools to see all demonstrations."
    fi
    
    # Run demonstrations
    demonstrate_fd
    demonstrate_ripgrep
    demonstrate_bat
    demonstrate_exa
    demonstrate_delta
    demonstrate_fzf
    demonstrate_zoxide
    
    echo -e "\nModern CLI tools demonstration completed."
}

# Run main function
main
