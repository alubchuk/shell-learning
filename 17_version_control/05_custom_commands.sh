#!/bin/bash

# =============================================================================
# Custom Git Commands Examples
# This script demonstrates how to create and use custom Git commands
# to enhance Git functionality and improve workflow efficiency.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: setup_example_repo
# Purpose: Create an example repository for custom command demonstrations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_example_repo() {
    echo "=== Setting Up Example Repository ==="
    
    # Create and initialize test repository
    local repo_path="/tmp/git_custom_demo"
    rm -rf "$repo_path"
    mkdir -p "$repo_path"
    cd "$repo_path"
    git init
    
    # Create some sample files and history
    for i in {1..5}; do
        echo "content $i" > "file$i.txt"
        git add "file$i.txt"
        git commit -m "feat: add file $i"
    done
    
    echo "Repository created at $repo_path"
}

# -----------------------------------------------------------------------------
# Function: create_custom_commands
# Purpose: Create custom Git commands
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_custom_commands() {
    echo -e "\n=== Creating Custom Git Commands ==="
    
    # Create bin directory for custom commands
    mkdir -p ~/.local/bin
    
    # 1. git-summary: Show repository summary
    cat << 'EOF' > ~/.local/bin/git-summary
#!/bin/bash
set -euo pipefail

echo "=== Repository Summary ==="
echo "Current branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Last commit: $(git log -1 --pretty=format:'%h - %s (%cr)' HEAD)"
echo "Modified files: $(git status --porcelain | wc -l)"
echo "Branches: $(git branch | wc -l)"
echo "Contributors: $(git shortlog -sn --no-merges | wc -l)"
echo "Total commits: $(git rev-list --count HEAD)"
EOF

    # 2. git-cleanup: Clean up branches and objects
    cat << 'EOF' > ~/.local/bin/git-cleanup
#!/bin/bash
set -euo pipefail

echo "=== Cleaning Repository ==="

# Remove merged branches
echo "Removing merged branches..."
git branch --merged main | grep -v "main$" | xargs git branch -d || true

# Remove squashed branches
for branch in $(git branch -r | grep -v "main$"); do
    commit=$(git rev-parse "$branch")
    if git cherry main "$commit" >/dev/null 2>&1; then
        git branch -D "${branch##*/}" || true
    fi
done

# Clean up objects
echo "Cleaning up objects..."
git gc --prune=now --aggressive

echo "Cleanup complete!"
EOF

    # 3. git-feature: Manage feature branches
    cat << 'EOF' > ~/.local/bin/git-feature
#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: git feature <start|finish|list> [name]"
    exit 1
}

case "${1:-}" in
    start)
        [ $# -eq 2 ] || usage
        git checkout -b "feature/$2" develop
        ;;
    finish)
        [ $# -eq 2 ] || usage
        git checkout develop
        git merge --no-ff "feature/$2"
        git branch -d "feature/$2"
        ;;
    list)
        git branch | grep "feature/"
        ;;
    *)
        usage
        ;;
esac
EOF

    # 4. git-standup: Show your recent work
    cat << 'EOF' > ~/.local/bin/git-standup
#!/bin/bash
set -euo pipefail

# Get author name from git config
AUTHOR=$(git config user.name)

# Get date range
SINCE="yesterday"
if [ "${1:-}" = "week" ]; then
    SINCE="last week"
fi

echo "=== Your Work Since $SINCE ==="
git log --all --since="$SINCE" --author="$AUTHOR" --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr)%Creset' --abbrev-commit
EOF

    # 5. git-review: Setup pull request review
    cat << 'EOF' > ~/.local/bin/git-review
#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: git review <branch> [remote]"
    exit 1
}

[ $# -ge 1 ] || usage

BRANCH=$1
REMOTE=${2:-origin}

# Fetch latest changes
git fetch "$REMOTE"

# Create review branch
REVIEW_BRANCH="review/$BRANCH"
git checkout -b "$REVIEW_BRANCH" "$REMOTE/$BRANCH"

# Show changes to review
echo "=== Changes to Review ==="
git log --pretty=format:'%Cred%h%Creset - %s %Cgreen(%cr)%Creset' --abbrev-commit main.."$REVIEW_BRANCH"
echo -e "\nFiles changed:"
git diff --stat main.."$REVIEW_BRANCH"
EOF

    # Make commands executable
    chmod +x ~/.local/bin/git-*
    
    echo "Custom commands installed in ~/.local/bin"
    echo "Add this directory to your PATH if not already added"
}

# -----------------------------------------------------------------------------
# Function: create_git_aliases
# Purpose: Create useful Git aliases
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_git_aliases() {
    echo -e "\n=== Creating Git Aliases ==="
    
    # Navigation
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.st status
    
    # Logging
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    git config --global alias.timeline "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
    
    # Branch management
    git config --global alias.bclean "!f() { git branch --merged \${1-main} | grep -v \" \${1-main}$\" | xargs git branch -d; }; f"
    git config --global alias.bdone "!f() { git checkout \${1-main} && git up && git bclean \${1-main}; }; f"
    
    # Shortcuts
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.visual "!gitk"
    
    # Advanced
    git config --global alias.undo "reset --soft HEAD^"
    git config --global alias.stash-all "stash save --include-untracked"
    git config --global alias.glog "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative"
    
    echo "Git aliases created"
    echo "View all aliases with: git config --get-regexp alias"
}

# -----------------------------------------------------------------------------
# Function: create_git_scripts
# Purpose: Create Git utility scripts
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_git_scripts() {
    echo -e "\n=== Creating Git Utility Scripts ==="
    
    mkdir -p scripts/git
    
    # 1. Branch status script
    cat << 'EOF' > scripts/git/branch-status.sh
#!/bin/bash
set -euo pipefail

# Show status of all branches
for branch in $(git branch --format="%(refname:short)"); do
    echo "=== $branch ==="
    echo "Last commit: $(git log -1 --pretty=format:'%h - %s (%cr)' "$branch")"
    echo "Author: $(git log -1 --pretty=format:'%an <%ae>' "$branch")"
    echo "Status vs main:"
    git rev-list --left-right --count main..."$branch" | \
        awk '{print "Behind by: "$1" commits\nAhead by: "$2" commits"}'
    echo
done
EOF

    # 2. Commit analysis script
    cat << 'EOF' > scripts/git/analyze-commits.sh
#!/bin/bash
set -euo pipefail

echo "=== Commit Analysis ==="

echo "Commits by author:"
git shortlog -sn --no-merges

echo -e "\nCommits by day of week:"
git log --format='%ad' --date=format:'%A' | sort | uniq -c | sort -nr

echo -e "\nCommits by hour:"
git log --format='%ad' --date=format:'%H' | sort | uniq -c | sort -nr

echo -e "\nMost modified files:"
git log --pretty=format: --name-only | sort | uniq -c | sort -rn | head -10
EOF

    # 3. Code review helper script
    cat << 'EOF' > scripts/git/review-helper.sh
#!/bin/bash
set -euo pipefail

target_branch=${1:-main}

echo "=== Code Review Helper ==="

# Show changes summary
echo "Changes overview:"
git diff --stat "$target_branch"

# Show potential issues
echo -e "\nPotential issues:"

# Check for large files
echo "Large files (>100KB):"
git diff --numstat "$target_branch" | awk '$1 > 100000 || $2 > 100000 {print $3}'

# Check for TODO/FIXME
echo -e "\nTODO/FIXME comments:"
git diff "$target_branch" | grep -i "todo\|fixme"

# Check for debugging statements
echo -e "\nDebugging statements:"
git diff "$target_branch" | grep -i "console.log\|print\|debug"
EOF

    # Make scripts executable
    chmod +x scripts/git/*.sh
    
    # Add to git
    git add scripts/git
    git commit -m "chore: add git utility scripts"
    
    echo "Created Git utility scripts in scripts/git directory"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_custom_commands
# Purpose: Demonstrate usage of custom commands
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_custom_commands() {
    echo -e "\n=== Demonstrating Custom Commands ==="
    
    # Create some changes
    echo "new content" > newfile.txt
    git add newfile.txt
    git commit -m "feat: add new file"
    
    # Show repository summary
    echo -e "\n1. Repository Summary:"
    git summary
    
    # Create and finish feature branch
    echo -e "\n2. Feature Branch Management:"
    git feature start test-feature
    echo "feature content" > feature.txt
    git add feature.txt
    git commit -m "feat: add feature"
    git feature finish test-feature
    
    # Show standup report
    echo -e "\n3. Standup Report:"
    git standup
    
    # Clean up repository
    echo -e "\n4. Repository Cleanup:"
    git cleanup
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting custom Git commands demonstration..."
    
    # Set up example repository
    setup_example_repo
    
    # Create custom commands and configurations
    create_custom_commands
    create_git_aliases
    create_git_scripts
    
    # Demonstrate usage
    demonstrate_custom_commands
    
    echo -e "\nCustom Git commands demonstration completed."
    echo "Example repository is at /tmp/git_custom_demo"
}

# Run main function
main
