#!/bin/bash

# tmux Automation
# -------------
# This script demonstrates tmux automation and
# configuration management patterns.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$SCRIPT_DIR/config"
readonly SESSION_NAME="dev-workspace"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# 1. Session Management
# -----------------

create_session() {
    local name="$1"
    local dir="${2:-$PWD}"
    
    echo "Creating tmux session: $name"
    
    # Check if session exists
    if tmux has-session -t "$name" 2>/dev/null; then
        echo "Session '$name' already exists"
        return 1
    fi
    
    # Create new session
    tmux new-session -d -s "$name" -c "$dir"
    echo "Created session: $name"
}

kill_session() {
    local name="$1"
    
    echo "Killing tmux session: $name"
    
    # Check if session exists
    if ! tmux has-session -t "$name" 2>/dev/null; then
        echo "Session '$name' does not exist"
        return 1
    fi
    
    # Kill session
    tmux kill-session -t "$name"
    echo "Killed session: $name"
}

list_sessions() {
    echo "Active tmux sessions:"
    tmux list-sessions 2>/dev/null || echo "No active sessions"
}

# 2. Window Management
# ----------------

create_window() {
    local session="$1"
    local name="$2"
    local dir="${3:-$PWD}"
    local cmd="${4:-}"
    
    echo "Creating window '$name' in session '$session'"
    
    # Create new window
    tmux new-window -d -t "$session:" -n "$name" -c "$dir"
    
    # Execute command if provided
    if [[ -n "$cmd" ]]; then
        tmux send-keys -t "$session:$name" "$cmd" C-m
    fi
}

rename_window() {
    local session="$1"
    local old_name="$2"
    local new_name="$3"
    
    echo "Renaming window '$old_name' to '$new_name'"
    tmux rename-window -t "$session:$old_name" "$new_name"
}

list_windows() {
    local session="$1"
    echo "Windows in session '$session':"
    tmux list-windows -t "$session" 2>/dev/null || echo "Session not found"
}

# 3. Pane Management
# --------------

split_window() {
    local session="$1"
    local window="$2"
    local direction="${3:-h}"  # h for horizontal, v for vertical
    local size="${4:-50}"     # percentage
    
    echo "Splitting window '$window' in session '$session'"
    
    if [[ "$direction" == "h" ]]; then
        tmux split-window -h -t "$session:$window" -p "$size"
    else
        tmux split-window -v -t "$session:$window" -p "$size"
    fi
}

send_command() {
    local session="$1"
    local window="$2"
    local pane="${3:-0}"
    local cmd="$4"
    
    echo "Sending command to $session:$window.$pane"
    tmux send-keys -t "$session:$window.$pane" "$cmd" C-m
}

# 4. Layout Management
# ----------------

save_layout() {
    local session="$1"
    local name="$2"
    local file="$CONFIG_DIR/${name}_layout.conf"
    
    echo "Saving layout for session '$session' to '$file'"
    tmux list-windows -t "$session" -F "#{window_index} #{window_name} #{window_layout}" > "$file"
}

load_layout() {
    local session="$1"
    local name="$2"
    local file="$CONFIG_DIR/${name}_layout.conf"
    
    echo "Loading layout for session '$session' from '$file'"
    
    if [[ ! -f "$file" ]]; then
        echo "Layout file not found: $file"
        return 1
    fi
    
    while read -r window_index window_name layout; do
        tmux select-layout -t "$session:$window_index" "$layout"
    done < "$file"
}

# 5. Project Workspace
# ----------------

create_dev_workspace() {
    local project_dir="$1"
    local project_name="${2:-$(basename "$project_dir")}"
    
    echo "Creating development workspace for $project_name"
    
    # Create main session
    create_session "$project_name" "$project_dir"
    
    # Create windows
    create_window "$project_name" "editor" "$project_dir" "vim ."
    create_window "$project_name" "git" "$project_dir" "git status"
    create_window "$project_name" "tests" "$project_dir" "echo 'Ready to run tests'"
    create_window "$project_name" "logs" "$project_dir" "tail -f /var/log/system.log"
    
    # Split windows
    split_window "$project_name" "editor" "v" 30
    split_window "$project_name" "git" "h" 50
    
    # Send commands
    send_command "$project_name" "editor.1" "0" "ls -la"
    
    # Save layout
    save_layout "$project_name" "dev"
    
    echo "Workspace created. Attach with: tmux attach -t $project_name"
}

# 6. Status Line Configuration
# -----------------------

configure_status_line() {
    # Status line colors
    tmux set-option -g status-style fg=white,bg=black
    
    # Window list colors
    tmux set-window-option -g window-status-style fg=cyan,bg=default
    tmux set-window-option -g window-status-current-style fg=white,bold,bg=red
    
    # Status line content
    tmux set-option -g status-left '#[fg=green]#S #[fg=yellow]#I #[fg=cyan]#P'
    tmux set-option -g status-right '#[fg=cyan]%Y-%m-%d #[fg=white]%H:%M'
    
    # Update interval
    tmux set-option -g status-interval 1
    
    echo "Status line configured"
}

# 7. Custom Key Bindings
# ------------------

configure_key_bindings() {
    # Use C-a as prefix
    tmux set-option -g prefix C-a
    tmux unbind-key C-b
    tmux bind-key C-a send-prefix
    
    # Vim-style pane navigation
    tmux bind-key h select-pane -L
    tmux bind-key j select-pane -D
    tmux bind-key k select-pane -U
    tmux bind-key l select-pane -R
    
    # Window management
    tmux bind-key -n M-1 select-window -t 1
    tmux bind-key -n M-2 select-window -t 2
    tmux bind-key -n M-3 select-window -t 3
    tmux bind-key -n M-4 select-window -t 4
    
    # Split windows
    tmux bind-key v split-window -h
    tmux bind-key s split-window -v
    
    echo "Key bindings configured"
}

# 8. Practical Examples
# ----------------

# Development environment
setup_dev_env() {
    local project_dir="$1"
    
    echo "Setting up development environment"
    
    # Create session
    create_session "dev" "$project_dir"
    
    # Configure windows
    create_window "dev" "code" "$project_dir" "vim"
    create_window "dev" "shell" "$project_dir"
    create_window "dev" "logs" "$project_dir"
    
    # Split windows
    split_window "dev" "code" "v" 30
    split_window "dev" "shell" "h" 50
    
    # Configure appearance
    configure_status_line
    configure_key_bindings
    
    # Save layout
    save_layout "dev" "default"
    
    echo "Development environment ready"
}

# Server monitoring
setup_monitoring() {
    echo "Setting up monitoring environment"
    
    # Create session
    create_session "monitor"
    
    # Create monitoring windows
    create_window "monitor" "system" "" "top"
    create_window "monitor" "disk" "" "df -h"
    create_window "monitor" "network" "" "netstat -an"
    create_window "monitor" "logs" "" "tail -f /var/log/system.log"
    
    # Split system window
    split_window "monitor" "system" "v" 50
    send_command "monitor" "system.1" "0" "ps aux | sort -rn -k 3 | head"
    
    echo "Monitoring environment ready"
}

# Main execution
main() {
    local command="${1:-help}"
    shift || true
    
    case "$command" in
        create)
            create_session "$SESSION_NAME"
            ;;
        kill)
            kill_session "$SESSION_NAME"
            ;;
        list)
            list_sessions
            ;;
        dev)
            local project_dir="${1:-$PWD}"
            setup_dev_env "$project_dir"
            ;;
        monitor)
            setup_monitoring
            ;;
        workspace)
            local project_dir="${1:-$PWD}"
            create_dev_workspace "$project_dir"
            ;;
        help|--help|-h)
            echo "Usage: $0 <command> [options]"
            echo "Commands:"
            echo "  create              Create new session"
            echo "  kill                Kill existing session"
            echo "  list                List sessions"
            echo "  dev <dir>           Setup development environment"
            echo "  monitor             Setup monitoring environment"
            echo "  workspace <dir>     Create project workspace"
            echo "  help                Show this help message"
            ;;
        *)
            echo "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
