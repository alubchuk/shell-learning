#!/bin/bash

# =============================================================================
# Terminal Multiplexer Examples
# This script demonstrates usage of modern terminal multiplexers (tmux),
# including session management, window/pane operations, and customization.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Function: check_tmux
# Purpose: Check if tmux is installed and print version
# Arguments: None
# Returns: 0 if tmux is available, 1 otherwise
# -----------------------------------------------------------------------------
check_tmux() {
    echo "=== Checking tmux Installation ==="
    
    if command -v tmux &>/dev/null; then
        echo "tmux is installed"
        echo "Version: $(tmux -V)"
        return 0
    else
        echo "tmux is not installed"
        echo "To install on macOS: brew install tmux"
        echo "To install on Ubuntu/Debian: apt install tmux"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Function: demonstrate_session_management
# Purpose: Show tmux session management commands
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_session_management() {
    echo -e "\n=== tmux Session Management ==="
    
    cat << 'EOF'
1. Starting New Sessions:
tmux                      # Start new unnamed session
tmux new -s dev          # Start new session named "dev"
tmux new -s proj -n code # Start session "proj" with window named "code"

2. Session Management:
tmux ls                  # List active sessions
tmux attach -t dev       # Attach to session named "dev"
tmux kill-session -t dev # Kill session named "dev"
tmux rename-session -t 0 dev  # Rename session 0 to "dev"

3. Session Navigation:
PREFIX d                 # Detach from current session
PREFIX s                 # Show session list
PREFIX $                 # Rename current session
PREFIX (                 # Switch to previous session
PREFIX )                 # Switch to next session

Note: PREFIX is CTRL+b by default
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_window_management
# Purpose: Show tmux window management commands
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_window_management() {
    echo -e "\n=== tmux Window Management ==="
    
    cat << 'EOF'
1. Window Operations:
PREFIX c                 # Create new window
PREFIX ,                 # Rename current window
PREFIX &                 # Kill current window
PREFIX p                 # Previous window
PREFIX n                 # Next window
PREFIX 0-9              # Switch to window number

2. Window Navigation:
PREFIX w                 # List windows
PREFIX f                 # Find window by name
PREFIX .                 # Move window to different number
PREFIX :swap-window -t 0 # Move current window to position 0

3. Window Layouts:
PREFIX Space            # Cycle through layouts
PREFIX M-1              # Even horizontal layout
PREFIX M-2              # Even vertical layout
PREFIX M-3              # Main horizontal layout
PREFIX M-4              # Main vertical layout
PREFIX M-5              # Tiled layout
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_pane_management
# Purpose: Show tmux pane management commands
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_pane_management() {
    echo -e "\n=== tmux Pane Management ==="
    
    cat << 'EOF'
1. Creating Panes:
PREFIX %                 # Split pane horizontally
PREFIX "                 # Split pane vertically
PREFIX !                 # Convert pane to window

2. Navigating Panes:
PREFIX ←,↑,→,↓          # Move between panes
PREFIX o                 # Next pane
PREFIX ;                 # Last active pane
PREFIX q                 # Show pane numbers

3. Resizing Panes:
PREFIX CTRL+←,↑,→,↓     # Resize pane by 1 cell
PREFIX ALT+←,↑,→,↓      # Resize pane by 5 cells
PREFIX z                 # Toggle pane zoom

4. Managing Panes:
PREFIX x                 # Kill current pane
PREFIX {                 # Move pane left
PREFIX }                 # Move pane right
PREFIX SPACE            # Cycle through pane layouts
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_copy_mode
# Purpose: Show tmux copy mode and scrolling
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_copy_mode() {
    echo -e "\n=== tmux Copy Mode ==="
    
    cat << 'EOF'
1. Entering Copy Mode:
PREFIX [                 # Enter copy mode
PREFIX PgUp              # Enter copy mode and scroll up

2. Navigation in Copy Mode:
h, j, k, l              # Vim-style movement
←, ↓, ↑, →              # Arrow key movement
w, b                    # Forward/backward word
CTRL+u                  # Scroll up
CTRL+d                  # Scroll down
g                       # Go to top
G                       # Go to bottom

3. Selection and Copying:
SPACE                   # Start selection
ENTER                   # Copy selection
PREFIX ]                # Paste selection
v                       # Toggle block selection (in vi mode)

4. Search in Copy Mode:
/                       # Forward search
?                       # Backward search
n                       # Next search match
N                       # Previous search match
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_configuration
# Purpose: Show tmux configuration examples
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_configuration() {
    echo -e "\n=== tmux Configuration Examples ==="
    
    cat << 'EOF'
Example ~/.tmux.conf configuration:

# Change prefix key to CTRL+a
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Start window numbering at 1
set -g base-index 1
setw -g pane-base-index 1

# Improve colors
set -g default-terminal "screen-256color"

# Set vi mode keys
setw -g mode-keys vi

# Customize status bar
set -g status-style bg=black,fg=white
set -g window-status-current-style bg=white,fg=black
set -g status-right "#[fg=green]#H #[fg=yellow]%H:%M %d-%b-%y"

# Custom key bindings
bind-key | split-window -h  # Split horizontally
bind-key - split-window -v  # Split vertically
bind-key r source-file ~/.tmux.conf \; display "Config reloaded!"

# Smart pane switching with awareness of Vim splits
bind -n C-h run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-h) || tmux select-pane -L"
bind -n C-j run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-j) || tmux select-pane -D"
bind -n C-k run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-k) || tmux select-pane -U"
bind -n C-l run "(tmux display-message -p '#{pane_current_command}' | grep -iq vim && tmux send-keys C-l) || tmux select-pane -R"

# Plugin management with TPM (Tmux Plugin Manager)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Initialize TPM
run '~/.tmux/plugins/tpm/tpm'
EOF
}

# -----------------------------------------------------------------------------
# Function: demonstrate_scripting
# Purpose: Show tmux scripting examples
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
demonstrate_scripting() {
    echo -e "\n=== tmux Scripting Examples ==="
    
    cat << 'EOF'
1. Development Environment Setup:
#!/bin/bash
# Create new session in detached mode
tmux new-session -d -s dev

# Split window horizontally
tmux split-window -h -t dev:0

# Split right pane vertically
tmux split-window -v -t dev:0.1

# Send commands to panes
tmux send-keys -t dev:0.0 'vim' C-m
tmux send-keys -t dev:0.1 'git status' C-m
tmux send-keys -t dev:0.2 'npm test' C-m

# Select first pane
tmux select-pane -t dev:0.0

# Attach to session
tmux attach-session -t dev

2. Server Monitoring Setup:
#!/bin/bash
tmux new-session -d -s monitor

# Create windows for different servers
tmux new-window -t monitor:1 -n 'web'
tmux new-window -t monitor:2 -n 'db'
tmux new-window -t monitor:3 -n 'logs'

# Setup commands in each window
tmux send-keys -t monitor:1 'ssh web-server top' C-m
tmux send-keys -t monitor:2 'ssh db-server htop' C-m
tmux send-keys -t monitor:3 'tail -f /var/log/syslog' C-m

# Select first window and attach
tmux select-window -t monitor:1
tmux attach-session -t monitor
EOF
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting terminal multiplexer demonstrations..."
    
    # Check for tmux installation
    check_tmux
    
    # Run all demonstrations
    demonstrate_session_management
    demonstrate_window_management
    demonstrate_pane_management
    demonstrate_copy_mode
    demonstrate_configuration
    demonstrate_scripting
    
    echo -e "\nTerminal multiplexer demonstrations completed."
    echo "Note: Most commands require an active tmux session to work."
}

# Run main function
main
