#!/bin/bash

# Task Automation Framework
# ----------------------
# A practical example combining design patterns, best practices,
# and testing into a complete task automation framework.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${HOME}/.config/taskframework"
readonly PLUGIN_DIR="$CONFIG_DIR/plugins"
readonly TASK_DIR="$CONFIG_DIR/tasks"
readonly LOG_DIR="$CONFIG_DIR/logs"
readonly LOCK_FILE="/tmp/taskframework.lock"

# Load core modules
for module in "$SCRIPT_DIR"/lib/*.sh; do
    if [ -f "$module" ]; then
        # shellcheck source=/dev/null
        source "$module"
    fi
done

# Ensure required directories exist
mkdir -p "$CONFIG_DIR" "$PLUGIN_DIR" "$TASK_DIR" "$LOG_DIR"

# 1. Plugin System
# -------------

# Plugin registry
declare -A PLUGINS
declare -A COMMANDS
declare -A EVENT_HANDLERS

register_plugin() {
    local name="$1"
    local version="$2"
    local description="$3"
    
    PLUGINS[$name]="$version:$description"
    debug "Registered plugin: $name v$version"
}

register_command() {
    local plugin="$1"
    local name="$2"
    local description="$3"
    local handler="$4"
    
    COMMANDS["$plugin:$name"]="$description:$handler"
    debug "Registered command: $plugin:$name"
}

register_event_handler() {
    local plugin="$1"
    local event="$2"
    local handler="$3"
    
    if [ -z "${EVENT_HANDLERS[$event]:-}" ]; then
        EVENT_HANDLERS[$event]="$plugin:$handler"
    else
        EVENT_HANDLERS[$event]="${EVENT_HANDLERS[$event]} $plugin:$handler"
    fi
    debug "Registered event handler: $plugin:$event"
}

# 2. Task Management
# ---------------

create_task() {
    local name="$1"
    local description="$2"
    local schedule="$3"
    local command="$4"
    
    local task_file="$TASK_DIR/${name}.task"
    
    # Validate task name
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid task name: $name"
        return 1
    fi
    
    # Create task definition
    cat > "$task_file" << EOF
name="$name"
description="$description"
schedule="$schedule"
command="$command"
enabled=true
created="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
modified="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EOF
    
    info "Created task: $name"
    emit_event "task_created" "$name"
}

delete_task() {
    local name="$1"
    local task_file="$TASK_DIR/${name}.task"
    
    if [ -f "$task_file" ]; then
        rm "$task_file"
        info "Deleted task: $name"
        emit_event "task_deleted" "$name"
    else
        error "Task not found: $name"
        return 1
    fi
}

list_tasks() {
    local format="${1:-text}"
    
    case "$format" in
        text)
            echo "Tasks:"
            echo "------"
            for task in "$TASK_DIR"/*.task; do
                if [ -f "$task" ]; then
                    # shellcheck source=/dev/null
                    source "$task"
                    printf "%-20s %-40s %s\n" "$name" "$description" "$schedule"
                fi
            done
            ;;
        json)
            echo "{"
            echo "  \"tasks\": ["
            local first=true
            for task in "$TASK_DIR"/*.task; do
                if [ -f "$task" ]; then
                    # shellcheck source=/dev/null
                    source "$task"
                    if [ "$first" = true ]; then
                        first=false
                    else
                        echo ","
                    fi
                    cat << EOF
    {
      "name": "$name",
      "description": "$description",
      "schedule": "$schedule",
      "enabled": $enabled,
      "created": "$created",
      "modified": "$modified"
    }
EOF
                fi
            done
            echo "  ]"
            echo "}"
            ;;
        *)
            error "Unknown format: $format"
            return 1
            ;;
    esac
}

run_task() {
    local name="$1"
    local task_file="$TASK_DIR/${name}.task"
    
    if [ ! -f "$task_file" ]; then
        error "Task not found: $name"
        return 1
    fi
    
    # Load task definition
    # shellcheck source=/dev/null
    source "$task_file"
    
    if [ "$enabled" != "true" ]; then
        warning "Task disabled: $name"
        return 0
    fi
    
    info "Running task: $name"
    emit_event "task_started" "$name"
    
    local start_time
    local end_time
    local duration
    
    start_time=$(date +%s)
    
    if eval "$command"; then
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        info "Task completed: $name (${duration}s)"
        emit_event "task_completed" "$name" "$duration"
        return 0
    else
        local exit_code=$?
        end_time=$(date +%s)
        duration=$((end_time - start_time))
        error "Task failed: $name (${duration}s, exit code: $exit_code)"
        emit_event "task_failed" "$name" "$exit_code"
        return "$exit_code"
    fi
}

# 3. Event System
# ------------

emit_event() {
    local event="$1"
    shift
    local args=("$@")
    
    debug "Event: $event ${args[*]}"
    
    if [ -n "${EVENT_HANDLERS[$event]:-}" ]; then
        for handler in ${EVENT_HANDLERS[$event]}; do
            IFS=':' read -r plugin handler_func <<< "$handler"
            if type "$handler_func" &>/dev/null; then
                "$handler_func" "${args[@]}"
            else
                warning "Event handler not found: $plugin:$handler_func"
            fi
        done
    fi
}

# 4. Command Line Interface
# ----------------------

show_help() {
    cat << EOF
Task Automation Framework v$SCRIPT_VERSION

Usage: $SCRIPT_NAME [options] <command> [args]

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -d, --debug     Enable debug mode
    -f, --format    Output format (text|json)
    --version       Show version information

Commands:
    create <name> <description> <schedule> <command>
           Create a new task
    delete <name>
           Delete an existing task
    list   List all tasks
    run    <name>
           Run a specific task
    help   Show this help message

Examples:
    $SCRIPT_NAME create backup "Daily backup" "0 0 * * *" "backup.sh"
    $SCRIPT_NAME list --format json
    $SCRIPT_NAME run backup
EOF
}

parse_args() {
    local args=()
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -f|--format)
                FORMAT="$2"
                shift 2
                ;;
            --version)
                echo "$SCRIPT_NAME version $SCRIPT_VERSION"
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                exit 1
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    
    set -- "${args[@]}"
    
    case "${1:-}" in
        create)
            if [ $# -ne 5 ]; then
                error "Usage: $SCRIPT_NAME create <name> <description> <schedule> <command>"
                exit 1
            fi
            create_task "$2" "$3" "$4" "$5"
            ;;
        delete)
            if [ $# -ne 2 ]; then
                error "Usage: $SCRIPT_NAME delete <name>"
                exit 1
            fi
            delete_task "$2"
            ;;
        list)
            list_tasks "${FORMAT:-text}"
            ;;
        run)
            if [ $# -ne 2 ]; then
                error "Usage: $SCRIPT_NAME run <name>"
                exit 1
            fi
            run_task "$2"
            ;;
        help)
            show_help
            ;;
        *)
            error "Unknown command: ${1:-}"
            show_help
            exit 1
            ;;
    esac
}

# 5. Example Plugin
# -------------

# Create example plugin
mkdir -p "$PLUGIN_DIR"
cat > "$PLUGIN_DIR/example.sh" << 'EOF'
#!/bin/bash

# Plugin metadata
PLUGIN_NAME="example"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Example plugin demonstrating framework features"

# Plugin initialization
plugin_init() {
    register_plugin "$PLUGIN_NAME" "$PLUGIN_VERSION" "$PLUGIN_DESCRIPTION"
    
    # Register commands
    register_command "$PLUGIN_NAME" "hello" "Say hello" plugin_cmd_hello
    register_command "$PLUGIN_NAME" "goodbye" "Say goodbye" plugin_cmd_goodbye
    
    # Register event handlers
    register_event_handler "$PLUGIN_NAME" "task_created" plugin_handle_task_created
    register_event_handler "$PLUGIN_NAME" "task_completed" plugin_handle_task_completed
}

# Command handlers
plugin_cmd_hello() {
    echo "Hello from example plugin!"
}

plugin_cmd_goodbye() {
    echo "Goodbye from example plugin!"
}

# Event handlers
plugin_handle_task_created() {
    local task_name="$1"
    info "Example plugin: Task created: $task_name"
}

plugin_handle_task_completed() {
    local task_name="$1"
    local duration="$2"
    info "Example plugin: Task completed: $task_name (${duration}s)"
}

# Initialize plugin
plugin_init
EOF

# 6. Main Script
# -----------

main() {
    # Initialize logging
    init_logging
    
    # Load plugins
    for plugin in "$PLUGIN_DIR"/*.sh; do
        if [ -f "$plugin" ]; then
            # shellcheck source=/dev/null
            source "$plugin"
        fi
    done
    
    # Parse command line arguments
    parse_args "$@"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
