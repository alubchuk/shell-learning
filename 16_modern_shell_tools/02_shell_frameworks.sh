#!/bin/bash

# =============================================================================
# Shell Framework Examples
# This script demonstrates setup and usage of modern shell frameworks and plugins,
# including Oh My Zsh, Antigen, and popular plugins for enhanced productivity.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: check_shell_type
# Purpose: Determine current shell and its version
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
check_shell_type() {
    echo "=== Current Shell Information ==="
    
    # Check current shell
    echo "Current shell: $SHELL"
    
    # Check if running in Zsh
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "Zsh version: $(zsh --version)"
    # Check if running in Bash
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "Bash version: $BASH_VERSION"
    fi
}

# -----------------------------------------------------------------------------
# Function: demonstrate_oh_my_zsh
# Purpose: Show Oh My Zsh setup and features
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_oh_my_zsh() {
    echo -e "\n=== Oh My Zsh Setup and Usage ==="
    
    # Check if Oh My Zsh is installed
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo "Oh My Zsh is installed"
        echo "Installation directory: $HOME/.oh-my-zsh"
        
        # Show current theme
        if [[ -n "${ZSH_THEME:-}" ]]; then
            echo "Current theme: $ZSH_THEME"
        fi
        
        # Show enabled plugins
        if [[ -n "${plugins:-}" ]]; then
            echo "Enabled plugins: ${plugins[*]}"
        fi
    else
        echo "Oh My Zsh is not installed"
        echo "To install, run:"
        echo 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
    fi
    
    # Show example .zshrc configuration
    cat << 'EOF'

Example .zshrc configuration:
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"  # or "agnoster", "powerlevel10k", etc.

# Recommended plugins
plugins=(
    git
    docker
    docker-compose
    kubectl
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
)

source $ZSH/oh-my-zsh.sh
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_antigen
# Purpose: Show Antigen plugin manager setup and usage
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_antigen() {
    echo -e "\n=== Antigen Plugin Manager ==="
    
    # Check if Antigen is installed
    if [[ -f "$HOME/antigen.zsh" ]]; then
        echo "Antigen is installed"
    else
        echo "Antigen is not installed"
        echo "To install, run:"
        echo 'curl -L git.io/antigen > ~/antigen.zsh'
    fi
    
    # Show example Antigen configuration
    cat << 'EOF'

Example Antigen configuration:
source ~/antigen.zsh

# Load Oh My Zsh library
antigen use oh-my-zsh

# Load bundles from the default repo (oh-my-zsh)
antigen bundle git
antigen bundle command-not-found
antigen bundle docker
antigen bundle docker-compose

# Load bundles from external repos
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions

# Select theme
antigen theme robbyrussell

# Apply configuration
antigen apply
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_plugins
# Purpose: Show usage of popular Zsh plugins
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_plugins() {
    echo -e "\n=== Popular Zsh Plugins Examples ==="
    
    # Git plugin examples
    echo "1. Git Plugin Aliases:"
    cat << 'EOF'
gst       # git status
ga        # git add
gcmsg     # git commit -m
gp        # git push
gpl       # git pull
gco       # git checkout
gcb       # git checkout -b
gbd       # git branch -d
EOF
    
    # Docker plugin examples
    echo -e "\n2. Docker Plugin Aliases:"
    cat << 'EOF'
dps       # docker ps
dpa       # docker ps -a
di        # docker images
drm       # docker rm
drmi      # docker rmi
dex       # docker exec -it
dcup      # docker-compose up
dcdown    # docker-compose down
EOF
    
    # Kubectl plugin examples
    echo -e "\n3. Kubectl Plugin Aliases:"
    cat << 'EOF'
k         # kubectl
kg        # kubectl get
kd        # kubectl describe
kdel      # kubectl delete
kgp       # kubectl get pods
kgn       # kubectl get nodes
kgs       # kubectl get services
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_completions
# Purpose: Show advanced command completion features
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_completions() {
    echo -e "\n=== Advanced Command Completions ==="
    
    # Show completion features
    cat << 'EOF'
1. Path Completion:
cd /u/l/b<TAB>           # Expands to /usr/local/bin

2. Command History:
<UP>                     # Previous command
CTRL+R                   # Reverse history search

3. Git Completions:
git che<TAB>             # Shows checkout, cherry, cherry-pick
git checkout ma<TAB>     # Completes branch names

4. Docker Completions:
docker r<TAB>            # Shows run, rm, rmi, etc.
docker run ubun<TAB>     # Completes image names

5. SSH Completions:
ssh user@hos<TAB>        # Completes hostnames from ~/.ssh/config

6. Kill Completion:
kill <TAB>               # Shows process IDs and names
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_themes
# Purpose: Show popular Zsh themes and customization
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_themes() {
    echo -e "\n=== Zsh Theme Examples ==="
    
    # Show popular themes
    cat << 'EOF'
1. Popular Themes:
- robbyrussell (default)
- agnoster
- powerlevel10k
- spaceship
- pure

2. Powerlevel10k Configuration:
# Install:
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Set in .zshrc:
ZSH_THEME="powerlevel10k/powerlevel10k"

# Configure:
p10k configure

3. Custom Theme Elements:
- Command execution time
- Git status
- Python virtual environment
- Node.js version
- Docker context
- Kubernetes context
- AWS profile
EOF
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting shell framework demonstrations..."
    
    # Run all demonstrations
    check_shell_type
    demonstrate_oh_my_zsh
    demonstrate_antigen
    demonstrate_plugins
    demonstrate_completions
    demonstrate_themes
    
    echo -e "\nShell framework demonstrations completed."
    echo "Note: Most features require interactive shell and proper installation."
}

# Run main function
main
