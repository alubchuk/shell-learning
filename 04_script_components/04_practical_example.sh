#!/bin/bash

# Configuration Management Tool
# ---------------------------
# This script demonstrates practical usage of arguments, environment variables,
# and shell expansion in a configuration management tool.

# Default values and environment setup
: ${CONFIG_DIR:="$HOME/.config/myapp"}
: ${CONFIG_FILE:="$CONFIG_DIR/config.ini"}
: ${BACKUP_DIR:="$CONFIG_DIR/backups"}
: ${LOG_FILE:="$CONFIG_DIR/config.log"}
: ${DEFAULT_ENV:="development"}

# Initialize variables
VERBOSE=false
ACTION=""
SECTION=""
KEY=""
VALUE=""
ENV_NAME="$DEFAULT_ENV"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$(date '+%Y-%m-%d %H:%M:%S') [$level] $*"
    echo "$message" >> "$LOG_FILE"
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ]; then
        echo "$message"
    fi
}

# Function to display usage
show_help() {
    cat << EOF
Configuration Management Tool
Usage: $(basename "$0") [options] <action> [arguments]

Actions:
    get <section> <key>           Get value for a key in section
    set <section> <key> <value>   Set value for a key in section
    list [section]                List all sections or keys in a section
    backup                        Create config backup
    restore <backup-file>         Restore config from backup
    diff <backup-file>           Show differences with backup

Options:
    -h, --help                    Show this help message
    -v, --verbose                Enable verbose output
    -e, --env <name>             Specify environment (default: $DEFAULT_ENV)
    -c, --config <file>          Specify config file
    --no-backup                  Don't create backup before changes

Environment Variables:
    CONFIG_DIR    Config directory (default: $HOME/.config/myapp)
    CONFIG_FILE   Config file path (default: \$CONFIG_DIR/config.ini)
    BACKUP_DIR    Backup directory (default: \$CONFIG_DIR/backups)
    LOG_FILE      Log file path (default: \$CONFIG_DIR/config.log)

Examples:
    $(basename "$0") list
    $(basename "$0") get database host
    $(basename "$0") -e production set database port 5432
    $(basename "$0") backup
    $(basename "$0") restore config_20240207.bak
EOF
}

# Function to ensure directories exist
ensure_dirs() {
    local dirs=("$CONFIG_DIR" "$BACKUP_DIR")
    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log "INFO" "Created directory: $dir"
        fi
    done
}

# Function to validate section/key format
validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log "ERROR" "Invalid name format: $name (use only letters, numbers, underscore, hyphen)"
        exit 1
    fi
}

# Function to create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/config_${timestamp}.bak"
    
    if [ -f "$CONFIG_FILE" ]; then
        cp "$CONFIG_FILE" "$backup_file"
        log "INFO" "Created backup: $backup_file"
        echo "$backup_file"
    else
        log "ERROR" "No config file to backup"
        exit 1
    fi
}

# Function to get value
get_value() {
    local section="$1"
    local key="$2"
    
    validate_name "$section"
    validate_name "$key"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "ERROR" "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    local value=$(awk -F ' *= *' '
        /^\['$section'\]/ { in_section=1; next }
        /^\[.*\]/ { in_section=0 }
        in_section && $1 == "'$key'" { print $2 }
    ' "$CONFIG_FILE")
    
    if [ -n "$value" ]; then
        echo "$value"
        log "INFO" "Retrieved value for [$section].$key"
    else
        log "ERROR" "Value not found for [$section].$key"
        exit 1
    fi
}

# Function to set value
set_value() {
    local section="$1"
    local key="$2"
    local value="$3"
    
    validate_name "$section"
    validate_name "$key"
    
    # Create config file if it doesn't exist
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "# Configuration file for myapp\n# Environment: $ENV_NAME\n" > "$CONFIG_FILE"
        log "INFO" "Created new config file: $CONFIG_FILE"
    fi
    
    # Create backup unless disabled
    if [ "${NO_BACKUP:-false}" != true ]; then
        create_backup >/dev/null
    fi
    
    local tmp_file=$(mktemp)
    local section_found=false
    local key_found=false
    
    # Process the config file
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ "$line" =~ ^\[(.*)\]$ ]]; then
            if [ "$section_found" = true ] && [ "$key_found" = false ]; then
                echo "$key = $value" >> "$tmp_file"
                key_found=true
            fi
            section_found=false
            if [ "${BASH_REMATCH[1]}" = "$section" ]; then
                section_found=true
            fi
        fi
        if [ "$section_found" = true ] && [[ "$line" =~ ^$key[[:space:]]*= ]]; then
            echo "$key = $value" >> "$tmp_file"
            key_found=true
            continue
        fi
        echo "$line" >> "$tmp_file"
    done < "$CONFIG_FILE"
    
    # Add section and key if not found
    if [ "$section_found" = false ]; then
        echo -e "\n[$section]" >> "$tmp_file"
        echo "$key = $value" >> "$tmp_file"
    elif [ "$key_found" = false ]; then
        echo "$key = $value" >> "$tmp_file"
    fi
    
    mv "$tmp_file" "$CONFIG_FILE"
    log "INFO" "Set value for [$section].$key"
}

# Function to list configuration
list_config() {
    local section="$1"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "ERROR" "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    if [ -n "$section" ]; then
        validate_name "$section"
        echo "Configuration for [$section]:"
        awk -F ' *= *' '
            /^\['$section'\]/ { in_section=1; next }
            /^\[.*\]/ { in_section=0 }
            in_section && NF > 1 { printf "  %-20s = %s\n", $1, $2 }
        ' "$CONFIG_FILE"
    else
        echo "Available sections:"
        grep '^\[.*\]$' "$CONFIG_FILE" | tr -d '[]' | sed 's/^/  /'
    fi
}

# Function to restore backup
restore_backup() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "Backup file not found: $backup_file"
        exit 1
    fi
    
    create_backup >/dev/null
    cp "$backup_file" "$CONFIG_FILE"
    log "INFO" "Restored configuration from: $backup_file"
}

# Function to show differences
show_diff() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        log "ERROR" "Backup file not found: $backup_file"
        exit 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log "ERROR" "Config file not found: $CONFIG_FILE"
        exit 1
    fi
    
    diff -u "$backup_file" "$CONFIG_FILE"
}

# Process options
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
        -e|--env)
            ENV_NAME="$2"
            validate_name "$ENV_NAME"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        -*)
            log "ERROR" "Unknown option: $1"
            exit 1
            ;;
        *)
            if [ -z "$ACTION" ]; then
                ACTION="$1"
            elif [ -z "$SECTION" ]; then
                SECTION="$1"
            elif [ -z "$KEY" ]; then
                KEY="$1"
            elif [ -z "$VALUE" ]; then
                VALUE="$1"
            else
                log "ERROR" "Too many arguments"
                exit 1
            fi
            shift
            ;;
    esac
done

# Ensure required directories exist
ensure_dirs

# Process actions
case "$ACTION" in
    get)
        if [ -z "$SECTION" ] || [ -z "$KEY" ]; then
            log "ERROR" "get requires section and key"
            exit 1
        fi
        get_value "$SECTION" "$KEY"
        ;;
    set)
        if [ -z "$SECTION" ] || [ -z "$KEY" ] || [ -z "$VALUE" ]; then
            log "ERROR" "set requires section, key, and value"
            exit 1
        fi
        set_value "$SECTION" "$KEY" "$VALUE"
        ;;
    list)
        list_config "$SECTION"
        ;;
    backup)
        create_backup
        ;;
    restore)
        if [ -z "$SECTION" ]; then
            log "ERROR" "restore requires backup file path"
            exit 1
        fi
        restore_backup "$SECTION"
        ;;
    diff)
        if [ -z "$SECTION" ]; then
            log "ERROR" "diff requires backup file path"
            exit 1
        fi
        show_diff "$SECTION"
        ;;
    *)
        log "ERROR" "Unknown or missing action. Use -h for help."
        exit 1
        ;;
esac
