#!/bin/bash

# =============================================================================
# Git Repository Maintenance Examples
# This script demonstrates various Git repository maintenance tasks,
# including cleanup, optimization, and health checks.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: setup_example_repo
# Purpose: Create an example repository for maintenance demonstrations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_example_repo() {
    echo "=== Setting Up Example Repository ==="
    
    # Create and initialize test repository
    local repo_path="/tmp/git_maintenance_demo"
    rm -rf "$repo_path"
    mkdir -p "$repo_path"
    cd "$repo_path"
    git init
    
    # Create some history
    for i in {1..10}; do
        echo "content $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "feat: add file $i"
        
        if ((i % 3 == 0)); then
            # Create some binary files
            dd if=/dev/urandom of="binary$i.bin" bs=1M count=1 2>/dev/null
            git add "binary$i.bin"
            git commit -m "chore: add binary file $i"
        fi
    done
    
    # Create some branches
    for i in {1..5}; do
        git checkout -b "feature/branch$i"
        echo "feature $i" > "feature$i.txt"
        git add "feature$i.txt"
        git commit -m "feat: add feature $i"
        git checkout main
    done
    
    echo "Repository created at $repo_path"
}

# -----------------------------------------------------------------------------
# Function: check_repo_health
# Purpose: Perform repository health checks
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
check_repo_health() {
    echo -e "\n=== Checking Repository Health ==="
    
    # Check for corruption
    echo "1. Checking for repository corruption..."
    git fsck --full
    
    # Check for dangling objects
    echo -e "\n2. Checking for dangling objects..."
    git fsck --dangling
    
    # Check for large files
    echo -e "\n3. Checking for large files..."
    git rev-list --objects --all | \
        git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | \
        awk '/^blob/ {print $3, $4}' | \
        sort -nr | \
        head -n 10
    
    # Check for binary files
    echo -e "\n4. Checking for binary files..."
    git ls-files | while read -r file; do
        if [ -f "$file" ] && file "$file" | grep -q "binary"; then
            echo "$file ($(du -h "$file" | cut -f1))"
        fi
    done
    
    # Check commit history
    echo -e "\n5. Analyzing commit history..."
    echo "Total commits: $(git rev-list --count HEAD)"
    echo "Contributors: $(git shortlog -sn --no-merges)"
    
    # Check for duplicate blobs
    echo -e "\n6. Checking for duplicate blobs..."
    git verify-pack -v .git/objects/pack/*.idx | \
        grep -v chain | \
        sort -k3nr | \
        head -n 10
}

# -----------------------------------------------------------------------------
# Function: cleanup_repository
# Purpose: Perform repository cleanup operations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
cleanup_repository() {
    echo -e "\n=== Cleaning Up Repository ==="
    
    # Remove untracked files
    echo "1. Removing untracked files..."
    git clean -n -d  # Dry run
    git clean -f -d  # Actually remove
    
    # Remove old branches
    echo -e "\n2. Removing old branches..."
    git branch --merged main | grep -v "main$" | xargs git branch -d || true
    
    # Prune remote branches
    echo -e "\n3. Pruning remote branches..."
    git remote prune origin || true
    
    # Remove old reflog entries
    echo -e "\n4. Cleaning reflog..."
    git reflog expire --expire=30.days.ago --all
    
    # Garbage collection
    echo -e "\n5. Running garbage collection..."
    git gc --aggressive --prune=now
}

# -----------------------------------------------------------------------------
# Function: optimize_repository
# Purpose: Perform repository optimization tasks
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
optimize_repository() {
    echo -e "\n=== Optimizing Repository ==="
    
    # Repack repository
    echo "1. Repacking repository..."
    git repack -a -d --depth=250 --window=250
    
    # Optimize local repository
    echo -e "\n2. Optimizing local repository..."
    git maintenance start
    
    # Configure maintenance schedule
    git config maintenance.auto true
    git config maintenance.strategy incremental
    
    # Show maintenance config
    echo -e "\n3. Current maintenance configuration:"
    git config --get-regexp maintenance
}

# -----------------------------------------------------------------------------
# Function: setup_git_lfs
# Purpose: Demonstrate Git LFS setup and usage
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_git_lfs() {
    echo -e "\n=== Setting Up Git LFS ==="
    
    # Check if Git LFS is installed
    if ! command -v git-lfs &>/dev/null; then
        echo "Git LFS not installed. Please install it first:"
        echo "brew install git-lfs  # macOS"
        echo "apt install git-lfs   # Ubuntu/Debian"
        return 1
    fi
    
    # Initialize Git LFS
    git lfs install
    
    # Configure LFS for binary files
    cat << 'EOF' > .gitattributes
*.bin filter=lfs diff=lfs merge=lfs -text
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.pdf filter=lfs diff=lfs merge=lfs -text
EOF
    
    # Add and commit .gitattributes
    git add .gitattributes
    git commit -m "chore: configure Git LFS"
    
    # Track existing binary files
    git lfs track "*.bin"
    git add .gitattributes
    
    # Show LFS status
    echo -e "\nGit LFS status:"
    git lfs status
}

# -----------------------------------------------------------------------------
# Function: create_maintenance_scripts
# Purpose: Create maintenance automation scripts
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_maintenance_scripts() {
    echo -e "\n=== Creating Maintenance Scripts ==="
    
    mkdir -p scripts
    
    # Create weekly maintenance script
    cat << 'EOF' > scripts/weekly-maintenance.sh
#!/bin/bash
set -euo pipefail

echo "Running weekly Git maintenance..."

# Fetch and prune
git fetch --all --prune

# Clean up merged branches
git branch --merged main | grep -v "main$" | xargs git branch -d || true

# Optimize repository
git maintenance run --task gc
git maintenance run --task commit-graph
git maintenance run --task prefetch

# Check repository health
git fsck --full

echo "Weekly maintenance completed"
EOF
    
    # Create LFS maintenance script
    cat << 'EOF' > scripts/lfs-maintenance.sh
#!/bin/bash
set -euo pipefail

echo "Running Git LFS maintenance..."

# Prune old LFS objects
git lfs prune

# Verify LFS objects
git lfs fsck

# Show LFS storage usage
git lfs ls-files | awk '{total += $4} END {print "Total LFS storage:", total/1024/1024, "MB"}'

echo "LFS maintenance completed"
EOF
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Add to git
    git add scripts
    git commit -m "chore: add maintenance scripts"
    
    echo "Created maintenance scripts in scripts directory"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_maintenance
# Purpose: Demonstrate all maintenance tasks
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_maintenance() {
    echo -e "\n=== Demonstrating Repository Maintenance ==="
    
    # Run health checks
    check_repo_health
    
    # Perform cleanup
    cleanup_repository
    
    # Optimize repository
    optimize_repository
    
    # Setup Git LFS
    setup_git_lfs
    
    # Create maintenance scripts
    create_maintenance_scripts
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting Git maintenance demonstration..."
    
    # Set up example repository
    setup_example_repo
    
    # Run demonstrations
    demonstrate_maintenance
    
    echo -e "\nGit maintenance demonstration completed."
    echo "Example repository is at /tmp/git_maintenance_demo"
}

# Run main function
main
