#!/bin/bash

# Design Patterns Examples
# ----------------------
# This script demonstrates various design patterns implemented in shell scripting.

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
PLUGIN_DIR="$SCRIPT_DIR/plugins"
CONFIG_DIR="${HOME}/.config/taskmanager"
CONFIG_FILE="$CONFIG_DIR/config.ini"
LOCK_FILE="/tmp/taskmanager.lock"

# Ensure directories exist
mkdir -p "$CONFIG_DIR" "$LIB_DIR" "$PLUGIN_DIR"

# 1. Singleton Pattern
# ------------------
# Ensures only one instance of the script is running

acquire_lock() {
    if [ -e "$LOCK_FILE" ]; then
        pid=$(cat "$LOCK_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Another instance is running (PID: $pid)"
            exit 1
        fi
    fi
    echo $$ > "$LOCK_FILE"
    trap 'rm -f "$LOCK_FILE"' EXIT
}

# 2. Factory Pattern
# ----------------
# Creates objects based on configuration or input

# Task factory
create_task() {
    local type="$1"
    shift
    
    case "$type" in
        shell)
            create_shell_task "$@"
            ;;
        python)
            create_python_task "$@"
            ;;
        node)
            create_node_task "$@"
            ;;
        *)
            echo "Unknown task type: $type"
            return 1
            ;;
    esac
}

create_shell_task() {
    cat << EOF
{
    "type": "shell",
    "command": "$1",
    "working_dir": "${2:-$PWD}",
    "timeout": ${3:-30}
}
EOF
}

create_python_task() {
    cat << EOF
{
    "type": "python",
    "script": "$1",
    "args": ${2:-[]},
    "virtualenv": "${3:-}"
}
EOF
}

create_node_task() {
    cat << EOF
{
    "type": "node",
    "script": "$1",
    "package": "${2:-package.json}",
    "node_version": "${3:-}"
}
EOF
}

# 3. Observer Pattern
# -----------------
# Implements event handling and callbacks

# Event handlers storage
declare -A EVENT_HANDLERS

# Register event handler
on() {
    local event="$1"
    local handler="$2"
    
    if [ -z "${EVENT_HANDLERS[$event]}" ]; then
        EVENT_HANDLERS[$event]="$handler"
    else
        EVENT_HANDLERS[$event]="${EVENT_HANDLERS[$event]}:$handler"
    fi
}

# Emit event
emit() {
    local event="$1"
    shift
    
    if [ -n "${EVENT_HANDLERS[$event]}" ]; then
        IFS=':' read -ra handlers <<< "${EVENT_HANDLERS[$event]}"
        for handler in "${handlers[@]}"; do
            $handler "$@"
        done
    fi
}

# Example event handlers
task_started() {
    echo "Task started: $1"
}

task_completed() {
    echo "Task completed: $1 (status: $2)"
}

task_failed() {
    echo "Task failed: $1 (error: $2)"
}

# Register default handlers
on "task_started" task_started
on "task_completed" task_completed
on "task_failed" task_failed

# 4. Command Pattern
# ---------------
# Encapsulates commands as objects

# Command registry
declare -A COMMANDS

# Register command
register_command() {
    local name="$1"
    local description="$2"
    local handler="$3"
    
    COMMANDS[$name]="$description:$handler"
}

# Execute command
execute_command() {
    local name="$1"
    shift
    
    if [ -n "${COMMANDS[$name]}" ]; then
        IFS=':' read -r description handler <<< "${COMMANDS[$name]}"
        $handler "$@"
    else
        echo "Unknown command: $name"
        return 1
    fi
}

# Example commands
cmd_list() {
    echo "Available commands:"
    for name in "${!COMMANDS[@]}"; do
        IFS=':' read -r description _ <<< "${COMMANDS[$name]}"
        printf "  %-15s %s\n" "$name" "$description"
    done
}

cmd_create() {
    local type="$1"
    shift
    create_task "$type" "$@"
}

cmd_run() {
    local task_json="$1"
    emit "task_started" "$task_json"
    
    if eval "$(echo "$task_json" | jq -r '.command // empty')" ; then
        emit "task_completed" "$task_json" 0
    else
        emit "task_failed" "$task_json" "$?"
    fi
}

# Register commands
register_command "list" "List available commands" cmd_list
register_command "create" "Create a new task" cmd_create
register_command "run" "Run a task" cmd_run

# 5. Plugin System
# -------------
# Demonstrates dynamic loading of functionality

# Load plugins
load_plugins() {
    if [ -d "$PLUGIN_DIR" ]; then
        for plugin in "$PLUGIN_DIR"/*.sh; do
            if [ -f "$plugin" ]; then
                source "$plugin"
                plugin_name=$(basename "$plugin" .sh)
                if type "plugin_init_${plugin_name}" &>/dev/null; then
                    "plugin_init_${plugin_name}"
                fi
            fi
        done
    fi
}

# Example plugin (would normally be in separate file)
cat > "$PLUGIN_DIR/example_plugin.sh" << 'EOF'
#!/bin/bash

plugin_init_example() {
    register_command "plugin_cmd" "Example plugin command" plugin_cmd_handler
}

plugin_cmd_handler() {
    echo "Plugin command executed with args: $*"
}
EOF

# 6. Configuration Management
# ------------------------
# Manages application configuration

# Default configuration
create_default_config() {
    cat > "$CONFIG_FILE" << EOF
# Task Manager Configuration

# Task defaults
default_type=shell
default_timeout=30
max_retries=3

# Plugin settings
enable_plugins=true
plugin_autoload=true

# Logging
log_level=info
log_file=${CONFIG_DIR}/taskmanager.log
EOF
}

# Load configuration
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    source "$CONFIG_FILE"
}

# Main Script
# ----------

main() {
    # Initialize
    acquire_lock
    load_config
    
    if [ "$enable_plugins" = true ]; then
        load_plugins
    fi
    
    # Process commands
    case "${1:-}" in
        "")
            cmd_list
            ;;
        *)
            execute_command "$@"
            ;;
    esac
}

# Example Usage
# ------------

# Only run if script is executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
