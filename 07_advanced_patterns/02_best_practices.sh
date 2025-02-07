#!/bin/bash

# Shell Scripting Best Practices
# ----------------------------
# This script demonstrates shell scripting best practices including
# code organization, error handling, performance, and security.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Script information
readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_AUTHOR="Your Name"
readonly SCRIPT_LICENSE="MIT"

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${HOME}/.config/${SCRIPT_NAME}"
readonly CONFIG_FILE="${CONFIG_DIR}/config.ini"
readonly LOG_FILE="${CONFIG_DIR}/script.log"
readonly TEMP_DIR="/tmp/${SCRIPT_NAME}_$$"

# Default settings
DEBUG=${DEBUG:-false}
VERBOSE=${VERBOSE:-false}
DRY_RUN=${DRY_RUN:-false}

# ANSI color codes (only if output is a terminal)
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

# 1. Code Organization
# ------------------

# Load library functions
load_library() {
    local lib_file="$1"
    if [ -f "$SCRIPT_DIR/lib/$lib_file" ]; then
        # shellcheck source=/dev/null
        source "$SCRIPT_DIR/lib/$lib_file"
    else
        error "Library file not found: $lib_file"
        exit 1
    fi
}

# Configuration management
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        create_default_config
    fi
    
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
}

create_default_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# Configuration for $SCRIPT_NAME

# General settings
MAX_RETRIES=3
TIMEOUT=30
BATCH_SIZE=100

# Feature flags
ENABLE_CACHE=true
ENABLE_LOGGING=true
ENABLE_METRICS=false

# Security settings
REQUIRE_SUDO=false
ALLOWED_USERS="root,admin"
EOF
}

# 2. Logging Functions
# ------------------

# Initialize logging
init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
}

# Multi-level logging
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    # Log to file
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    # Log to console with colors
    case "$level" in
        ERROR)   echo -e "${RED}[$level] $message${NC}" >&2 ;;
        WARNING) echo -e "${YELLOW}[$level] $message${NC}" >&2 ;;
        INFO)    echo -e "${GREEN}[$level] $message${NC}" ;;
        DEBUG)   [[ "$DEBUG" = true ]] && echo -e "${BLUE}[$level] $message${NC}" ;;
    esac
}

# Convenience logging functions
debug()   { log "DEBUG" "$*"; }
info()    { log "INFO" "$*"; }
warning() { log "WARNING" "$*"; }
error()   { log "ERROR" "$*"; }

# 3. Error Handling
# ---------------

# Error handler
error_handler() {
    local line="$1"
    local command="$2"
    local code="${3:-1}"
    error "Command '$command' failed with exit code $code at line $line"
    cleanup
    exit "$code"
}

# Set error trap
trap 'error_handler ${LINENO} "$BASH_COMMAND" $?' ERR

# Cleanup handler
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
    info "Cleanup completed"
}

# Set cleanup trap
trap cleanup EXIT

# 4. Input Validation
# -----------------

# Validate number
validate_number() {
    local value="$1"
    local min="$2"
    local max="$3"
    local name="$4"
    
    if [[ ! "$value" =~ ^[0-9]+$ ]]; then
        error "$name must be a number"
        return 1
    fi
    
    if [ "$value" -lt "$min" ] || [ "$value" -gt "$max" ]; then
        error "$name must be between $min and $max"
        return 1
    fi
    
    return 0
}

# Validate string
validate_string() {
    local value="$1"
    local pattern="$2"
    local name="$3"
    
    if [[ ! "$value" =~ $pattern ]]; then
        error "$name contains invalid characters"
        return 1
    fi
    
    return 0
}

# Validate file
validate_file() {
    local file="$1"
    local type="$2"
    
    case "$type" in
        readable)
            if [ ! -r "$file" ]; then
                error "File not readable: $file"
                return 1
            fi
            ;;
        writable)
            if [ ! -w "$file" ]; then
                error "File not writable: $file"
                return 1
            fi
            ;;
        executable)
            if [ ! -x "$file" ]; then
                error "File not executable: $file"
                return 1
            fi
            ;;
        *)
            if [ ! -f "$file" ]; then
                error "File not found: $file"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# 5. Performance Optimization
# ------------------------

# Cache management
declare -A CACHE

cache_get() {
    local key="$1"
    echo "${CACHE[$key]:-}"
}

cache_set() {
    local key="$1"
    local value="$2"
    CACHE[$key]="$value"
}

cache_clear() {
    CACHE=()
}

# Batch processing
process_batch() {
    local items=("$@")
    local batch_size="${BATCH_SIZE:-100}"
    local total="${#items[@]}"
    local processed=0
    
    while [ "$processed" -lt "$total" ]; do
        local end=$((processed + batch_size))
        [ "$end" -gt "$total" ] && end="$total"
        
        # Process current batch
        for ((i=processed; i<end; i++)); do
            process_item "${items[i]}"
        done
        
        processed="$end"
        info "Processed $processed of $total items"
    done
}

# 6. Security Measures
# -----------------

# Check if running as root when required
check_root() {
    if [ "$REQUIRE_SUDO" = true ] && [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Validate user permissions
check_user_permissions() {
    local current_user
    current_user="$(whoami)"
    
    IFS=',' read -ra allowed <<< "$ALLOWED_USERS"
    for user in "${allowed[@]}"; do
        if [ "$user" = "$current_user" ]; then
            return 0
        fi
    done
    
    error "User $current_user is not authorized to run this script"
    exit 1
}

# Sanitize input
sanitize_input() {
    local input="$1"
    # Remove any dangerous characters
    echo "$input" | tr -cd '[:alnum:]._-'
}

# 7. Command Line Interface
# ----------------------

show_help() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION
$SCRIPT_AUTHOR

Usage: $SCRIPT_NAME [options] <command> [args]

Options:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    -d, --debug     Enable debug mode
    -n, --dry-run   Show what would be done
    --version       Show version information

Commands:
    start           Start processing
    stop            Stop processing
    status          Show current status
    help            Show this help message

Examples:
    $SCRIPT_NAME start
    $SCRIPT_NAME --debug status
EOF
}

show_version() {
    echo "$SCRIPT_NAME version $SCRIPT_VERSION"
}

# Parse command line arguments
parse_args() {
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
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --version)
                show_version
                exit 0
                ;;
            -*)
                error "Unknown option: $1"
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    readonly DEBUG VERBOSE DRY_RUN
}

# 8. Main Script Logic
# -----------------

init() {
    init_logging
    load_config
    check_root
    check_user_permissions
    
    mkdir -p "$TEMP_DIR"
    info "Initialization completed"
}

main() {
    parse_args "$@"
    init
    
    case "${1:-}" in
        start)
            info "Starting process..."
            ;;
        stop)
            info "Stopping process..."
            ;;
        status)
            info "Checking status..."
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
}

# Only run if script is executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
