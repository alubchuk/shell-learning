#!/bin/bash

# =============================================================================
# Git Hooks Examples
# This script demonstrates various Git hooks for automating workflows,
# enforcing standards, and improving code quality.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: setup_example_repo
# Purpose: Create an example repository for hook demonstrations
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
setup_example_repo() {
    echo "=== Setting Up Example Repository ==="
    
    # Create and initialize test repository
    local repo_path="/tmp/git_hooks_demo"
    rm -rf "$repo_path"
    mkdir -p "$repo_path"
    cd "$repo_path"
    git init
    
    # Create example project structure
    mkdir -p src tests
    
    # Create sample files
    cat << 'EOF' > src/main.py
def main():
    print("Hello, World!")

if __name__ == "__main__":
    main()
EOF
    
    cat << 'EOF' > tests/test_main.py
def test_main():
    assert True
EOF
    
    # Create initial commit
    git add .
    git commit -m "Initial commit"
    
    echo "Repository created at $repo_path"
}

# -----------------------------------------------------------------------------
# Function: create_pre_commit_hook
# Purpose: Create a pre-commit hook for code quality checks
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_pre_commit_hook() {
    echo -e "\n=== Creating pre-commit Hook ==="
    
    mkdir -p .git/hooks
    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/bash

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

echo "Running pre-commit checks..."

# Get list of Python files that are staged for commit
files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.py$' || true)
if [ -z "$files" ]; then
    echo "No Python files to check"
    exit 0
fi

# Function to run checks
check_python_file() {
    local file=$1
    
    echo "Checking $file..."
    
    # Check for syntax errors
    python3 -m py_compile "$file" || {
        echo "Syntax error in $file"
        return 1
    }
    
    # Run pylint if available
    if command -v pylint &>/dev/null; then
        pylint --disable=all --enable=E,F "$file" || {
            echo "Linting errors in $file"
            return 1
        }
    fi
    
    # Check for debug statements
    if grep -n "print(" "$file"; then
        echo "Warning: Found print statements in $file"
    fi
    
    # Check line length
    if grep -l '.\{80\}' "$file"; then
        echo "Error: Lines longer than 80 characters in $file"
        return 1
    fi
    
    return 0
}

# Run checks on all staged Python files
failed=0
for file in $files; do
    if ! check_python_file "$file"; then
        failed=1
    fi
done

if [ $failed -eq 1 ]; then
    echo "Pre-commit checks failed!"
    exit 1
fi

echo "All checks passed!"
EOF
    
    chmod +x .git/hooks/pre-commit
    echo "Created pre-commit hook"
}

# -----------------------------------------------------------------------------
# Function: create_commit_msg_hook
# Purpose: Create a commit-msg hook for commit message standards
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_commit_msg_hook() {
    echo -e "\n=== Creating commit-msg Hook ==="
    
    cat << 'EOF' > .git/hooks/commit-msg
#!/bin/bash

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

commit_msg_file=$1
commit_msg=$(cat "$commit_msg_file")

# Define message format rules
format_regex="^(feat|fix|docs|style|refactor|test|chore)(\([a-z]+\))?: .+"
max_length=72

echo "Checking commit message format..."

# Check message format
if ! [[ $commit_msg =~ $format_regex ]]; then
    echo "Error: Commit message format is incorrect"
    echo "Format should be: <type>(<scope>): <description>"
    echo "Types: feat, fix, docs, style, refactor, test, chore"
    echo "Example: feat(auth): add OAuth support"
    exit 1
fi

# Check message length
if [ ${#commit_msg} -gt $max_length ]; then
    echo "Error: Commit message is too long (max $max_length characters)"
    exit 1
fi

# Check for trailing period
if [[ $commit_msg =~ \.$  ]]; then
    echo "Error: Commit message should not end with a period"
    exit 1
fi

echo "Commit message format is valid!"
EOF
    
    chmod +x .git/hooks/commit-msg
    echo "Created commit-msg hook"
}

# -----------------------------------------------------------------------------
# Function: create_pre_push_hook
# Purpose: Create a pre-push hook for running tests
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_pre_push_hook() {
    echo -e "\n=== Creating pre-push Hook ==="
    
    cat << 'EOF' > .git/hooks/pre-push
#!/bin/bash

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

echo "Running pre-push checks..."

# Run tests
if [ -d "tests" ]; then
    if command -v pytest &>/dev/null; then
        echo "Running pytest..."
        pytest tests/ || {
            echo "Tests failed!"
            exit 1
        }
    else
        echo "Warning: pytest not found, skipping tests"
    fi
fi

# Check for sensitive data
echo "Checking for sensitive data..."
sensitive_patterns=(
    "password"
    "secret"
    "api[_-]key"
    "token"
    "credentials"
)

for pattern in "${sensitive_patterns[@]}"; do
    if git diff --cached -i --name-only | xargs grep -i "$pattern"; then
        echo "Error: Found potential sensitive data ($pattern)"
        exit 1
    fi
done

echo "All pre-push checks passed!"
EOF
    
    chmod +x .git/hooks/pre-push
    echo "Created pre-push hook"
}

# -----------------------------------------------------------------------------
# Function: create_post_checkout_hook
# Purpose: Create a post-checkout hook for environment setup
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
create_post_checkout_hook() {
    echo -e "\n=== Creating post-checkout Hook ==="
    
    cat << 'EOF' > .git/hooks/post-checkout
#!/bin/bash

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

prev_head=$1
new_head=$2
checkout_type=$3

echo "Running post-checkout tasks..."

# Check if this is a branch checkout
if [ "$checkout_type" -eq 1 ]; then
    # Check for new dependencies
    if [ -f "requirements.txt" ]; then
        if ! diff <(git show "$prev_head:requirements.txt" 2>/dev/null || echo "") \
                 <(git show "$new_head:requirements.txt" 2>/dev/null || echo "") >/dev/null; then
            echo "Dependencies changed! You may need to update your virtual environment"
        fi
    fi
    
    # Check for database migrations
    if [ -d "migrations" ]; then
        echo "Checking for new database migrations..."
        new_migrations=$(git diff --name-only "$prev_head" "$new_head" -- migrations/)
        if [ -n "$new_migrations" ]; then
            echo "New migrations detected! You may need to run migrations"
        fi
    fi
    
    # Check for configuration changes
    if git diff --name-only "$prev_head" "$new_head" | grep -q "config/"; then
        echo "Configuration files changed! Review your local settings"
    fi
fi

echo "Post-checkout tasks completed!"
EOF
    
    chmod +x .git/hooks/post-checkout
    echo "Created post-checkout hook"
}

# -----------------------------------------------------------------------------
# Function: demonstrate_hooks
# Purpose: Demonstrate the hooks in action
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_hooks() {
    echo -e "\n=== Demonstrating Git Hooks ==="
    
    # Demonstrate pre-commit hook
    echo -e "\n1. Testing pre-commit hook..."
    echo 'print("Bad code - line too long.............................................................")' > src/main.py
    git add src/main.py
    if ! git commit -m "feat: add long line" 2>/dev/null; then
        echo "Pre-commit hook caught the long line!"
    fi
    
    # Fix the file and try again
    echo 'print("Good code")' > src/main.py
    git add src/main.py
    
    # Demonstrate commit-msg hook
    echo -e "\n2. Testing commit-msg hook..."
    if ! git commit -m "bad commit message" 2>/dev/null; then
        echo "Commit-msg hook caught the bad format!"
    fi
    
    # Try with correct format
    git commit -m "feat(core): add print statement"
    
    # Demonstrate pre-push hook
    echo -e "\n3. Testing pre-push hook..."
    echo "password = 'secret123'" >> src/main.py
    git add src/main.py
    if ! git commit -m "feat: add config" 2>/dev/null; then
        echo "Pre-push hook caught the sensitive data!"
    fi
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting Git hooks demonstration..."
    
    # Set up example repository
    setup_example_repo
    
    # Create hooks
    create_pre_commit_hook
    create_commit_msg_hook
    create_pre_push_hook
    create_post_checkout_hook
    
    # Demonstrate hooks
    demonstrate_hooks
    
    echo -e "\nGit hooks demonstration completed."
    echo "Example repository is at /tmp/git_hooks_demo"
}

# Run main function
main
