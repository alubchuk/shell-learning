#!/bin/bash

# =============================================================================
# Git Automated Workflows Examples
# This script demonstrates automated Git workflows for common development tasks,
# including feature branches, releases, and maintenance operations.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: setup_example_repo
# Purpose: Create an example repository for workflow demonstrations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_example_repo() {
    echo "=== Setting Up Example Repository ==="
    
    # Create and initialize test repository
    local repo_path="/tmp/git_workflows_demo"
    rm -rf "$repo_path"
    mkdir -p "$repo_path"
    cd "$repo_path"
    git init
    
    # Create initial project structure
    mkdir -p src tests docs
    
    # Create sample files
    echo 'version = "1.0.0"' > src/version.py
    echo '# Project Documentation' > docs/README.md
    echo 'def test_version(): pass' > tests/test_version.py
    
    # Create initial commit
    git add .
    git commit -m "feat: initial commit"
    
    # Create development branch
    git checkout -b develop
    
    echo "Repository created at $repo_path"
}

# -----------------------------------------------------------------------------
# Function: create_feature_branch
# Purpose: Demonstrate feature branch workflow
# Arguments:
#   $1 - Feature name
# Returns: None
# -----------------------------------------------------------------------------
create_feature_branch() {
    local feature_name=$1
    echo -e "\n=== Creating Feature Branch ==="
    
    # Create feature branch
    git checkout -b "feature/$feature_name" develop
    
    # Make some changes
    echo "def new_feature(): pass" >> src/feature.py
    echo "def test_new_feature(): pass" >> tests/test_feature.py
    
    # Commit changes
    git add .
    git commit -m "feat($feature_name): implement new feature"
    
    # Simulate code review feedback
    echo "def new_feature_improved(): pass" >> src/feature.py
    git add .
    git commit -m "refactor($feature_name): improve implementation"
    
    # Merge back to develop
    git checkout develop
    git merge --no-ff "feature/$feature_name" -m "feat: merge $feature_name feature"
    
    echo "Feature branch workflow completed"
}

# -----------------------------------------------------------------------------
# Function: create_release
# Purpose: Demonstrate release branch workflow
# Arguments:
#   $1 - Version number
# Returns: None
# -----------------------------------------------------------------------------
create_release() {
    local version=$1
    echo -e "\n=== Creating Release Branch ==="
    
    # Create release branch
    git checkout -b "release/$version" develop
    
    # Update version
    sed -i.bak "s/version = .*/version = \"$version\"/" src/version.py
    rm -f src/version.py.bak
    
    # Commit version bump
    git add src/version.py
    git commit -m "chore(release): bump version to $version"
    
    # Simulate bug fixes
    echo "def bugfix(): pass" >> src/bugfix.py
    git add .
    git commit -m "fix: address release feedback"
    
    # Merge to main and develop
    git checkout main
    git merge --no-ff "release/$version" -m "chore(release): version $version"
    git tag -a "v$version" -m "Release version $version"
    
    git checkout develop
    git merge --no-ff "release/$version" -m "chore(release): merge release $version to develop"
    
    echo "Release workflow completed"
}

# -----------------------------------------------------------------------------
# Function: create_hotfix
# Purpose: Demonstrate hotfix workflow
# Arguments:
#   $1 - Hotfix version
# Returns: None
# -----------------------------------------------------------------------------
create_hotfix() {
    local version=$1
    echo -e "\n=== Creating Hotfix Branch ==="
    
    # Create hotfix branch from main
    git checkout -b "hotfix/$version" main
    
    # Fix critical bug
    echo "def critical_bugfix(): pass" >> src/hotfix.py
    git add .
    git commit -m "fix: critical production issue"
    
    # Update version
    sed -i.bak "s/version = .*/version = \"$version\"/" src/version.py
    rm -f src/version.py.bak
    git add src/version.py
    git commit -m "chore(release): bump version to $version"
    
    # Merge to main and develop
    git checkout main
    git merge --no-ff "hotfix/$version" -m "fix: merge hotfix $version"
    git tag -a "v$version" -m "Hotfix version $version"
    
    git checkout develop
    git merge --no-ff "hotfix/$version" -m "fix: merge hotfix $version to develop"
    
    echo "Hotfix workflow completed"
}

# -----------------------------------------------------------------------------
# Function: cleanup_branches
# Purpose: Demonstrate branch cleanup workflow
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
cleanup_branches() {
    echo -e "\n=== Cleaning Up Branches ==="
    
    # List all branches
    echo "Current branches:"
    git branch -a
    
    # Remove merged feature branches
    echo -e "\nRemoving merged feature branches..."
    git branch --merged develop | grep "feature/" | xargs git branch -d || true
    
    # Remove merged release branches
    echo "Removing merged release branches..."
    git branch --merged main | grep "release/" | xargs git branch -d || true
    
    # Remove merged hotfix branches
    echo "Removing merged hotfix branches..."
    git branch --merged main | grep "hotfix/" | xargs git branch -d || true
    
    # List remaining branches
    echo -e "\nRemaining branches:"
    git branch -a
}

# -----------------------------------------------------------------------------
# Function: create_automation_scripts
# Purpose: Create automation scripts for common workflows
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_automation_scripts() {
    echo -e "\n=== Creating Automation Scripts ==="
    
    # Create scripts directory
    mkdir -p scripts
    
    # Create feature start script
    cat << 'EOF' > scripts/feature-start.sh
#!/bin/bash
set -euo pipefail

feature_name=$1
git checkout develop
git pull
git checkout -b "feature/$feature_name"
echo "Created feature branch: feature/$feature_name"
EOF
    
    # Create feature finish script
    cat << 'EOF' > scripts/feature-finish.sh
#!/bin/bash
set -euo pipefail

feature_name=$1
current_branch=$(git rev-parse --abbrev-ref HEAD)

if [[ $current_branch != feature/* ]]; then
    echo "Not on a feature branch!"
    exit 1
fi

git checkout develop
git pull
git merge --no-ff "$current_branch" -m "feat: merge $feature_name feature"
git branch -d "$current_branch"
EOF
    
    # Create release script
    cat << 'EOF' > scripts/release.sh
#!/bin/bash
set -euo pipefail

version=$1

git checkout develop
git pull
git checkout -b "release/$version"

# Update version files
find . -name version.py -exec sed -i.bak "s/version = .*/version = \"$version\"/" {} \;
find . -name "*.bak" -delete

git add .
git commit -m "chore(release): bump version to $version"

echo "Created release branch: release/$version"
EOF
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Add to git
    git add scripts
    git commit -m "chore: add automation scripts"
    
    echo "Created automation scripts in scripts directory"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_workflows
# Purpose: Demonstrate all workflows in action
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_workflows() {
    echo -e "\n=== Demonstrating Git Workflows ==="
    
    # Create main branch and initial release
    git checkout -b main
    git commit --allow-empty -m "chore: initialize main branch"
    
    # Feature workflow
    create_feature_branch "user-auth"
    
    # Release workflow
    create_release "1.1.0"
    
    # Hotfix workflow
    create_hotfix "1.1.1"
    
    # Cleanup
    cleanup_branches
    
    # Create automation scripts
    create_automation_scripts
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting Git workflows demonstration..."
    
    # Set up example repository
    setup_example_repo
    
    # Run demonstrations
    demonstrate_workflows
    
    echo -e "\nGit workflows demonstration completed."
    echo "Example repository is at /tmp/git_workflows_demo"
}

# Run main function
main
