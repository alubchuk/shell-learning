#!/bin/bash

# Backup Management Tool
# --------------------
# This script provides flexible backup functionality with support for
# different backup strategies, compression, and remote backup.

# Configuration
CONFIG_DIR="${HOME}/.config/backup"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
LOG_FILE="${CONFIG_DIR}/backup.log"
BACKUP_DIR="${HOME}/backups"
TEMP_DIR="/tmp/backup_$$"

# Default settings
COMPRESSION="gzip"  # gzip, bzip2, or xz
BACKUP_TYPE="full"  # full, incremental, or differential
REMOTE_BACKUP=false
VERIFY_BACKUP=true
MAX_BACKUPS=5
EXCLUDE_FILE="${CONFIG_DIR}/exclude.txt"

# Ensure required directories exist
mkdir -p "$CONFIG_DIR" "$BACKUP_DIR"

# Create default configuration if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" << EOF
# Backup Configuration

# Backup settings
BACKUP_TYPE=full           # full, incremental, or differential
COMPRESSION=gzip          # gzip, bzip2, or xz
REMOTE_BACKUP=false      # true or false
VERIFY_BACKUP=true       # true or false
MAX_BACKUPS=5           # number of backups to keep

# Backup sources (space-separated)
BACKUP_SOURCES="/etc /home/user/documents"

# Remote backup settings (if enabled)
#REMOTE_HOST="backup.example.com"
#REMOTE_USER="backup"
#REMOTE_PATH="/backup"
#REMOTE_PORT=22

# Retention settings
DAILY_BACKUPS=7
WEEKLY_BACKUPS=4
MONTHLY_BACKUPS=3
EOF
fi

# Create default exclude file if it doesn't exist
if [ ! -f "$EXCLUDE_FILE" ]; then
    cat > "$EXCLUDE_FILE" << EOF
# Exclude patterns for backup
.DS_Store
node_modules/
*.log
*.tmp
.git/
.svn/
EOF
fi

# Source configuration
source "$CONFIG_FILE"

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    echo "[$level] $message"
}

# Error handling function
error_exit() {
    log "ERROR" "$1"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    log "INFO" "Performing cleanup..."
    rm -rf "$TEMP_DIR"
}

# Set up error handling
trap cleanup EXIT
trap 'error_exit "An error occurred on line $LINENO"' ERR

# Verify backup function
verify_backup() {
    local backup_file="$1"
    local verify_dir="$TEMP_DIR/verify"
    
    log "INFO" "Verifying backup: $backup_file"
    mkdir -p "$verify_dir"
    
    # Extract backup based on compression type
    case "$COMPRESSION" in
        gzip)
            tar -tzf "$backup_file" >/dev/null || return 1
            ;;
        bzip2)
            tar -tjf "$backup_file" >/dev/null || return 1
            ;;
        xz)
            tar -tJf "$backup_file" >/dev/null || return 1
            ;;
        *)
            error_exit "Unknown compression type: $COMPRESSION"
            ;;
    esac
    
    log "INFO" "Backup verification successful"
    return 0
}

# Remote backup function
remote_backup() {
    local backup_file="$1"
    
    if [ "$REMOTE_BACKUP" = true ]; then
        if [ -z "${REMOTE_HOST:-}" ] || [ -z "${REMOTE_USER:-}" ] || [ -z "${REMOTE_PATH:-}" ]; then
            error_exit "Remote backup settings not configured"
        fi
        
        log "INFO" "Copying backup to remote host: $REMOTE_HOST"
        
        # Create remote directory if it doesn't exist
        ssh -p "${REMOTE_PORT:-22}" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_PATH"
        
        # Copy backup file
        rsync -avz -e "ssh -p ${REMOTE_PORT:-22}" \
            "$backup_file" \
            "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH/" || {
            error_exit "Remote backup failed"
        }
        
        log "INFO" "Remote backup completed"
    fi
}

# Rotate backups function
rotate_backups() {
    local backup_type="$1"
    local max_count="$2"
    
    log "INFO" "Rotating $backup_type backups (keeping $max_count)"
    
    # List backups of this type, sorted by date
    local backups=($(ls -t "$BACKUP_DIR"/*"$backup_type"* 2>/dev/null))
    
    # Remove excess backups
    if [ ${#backups[@]} -gt "$max_count" ]; then
        for ((i=max_count; i<${#backups[@]}; i++)); do
            log "INFO" "Removing old backup: ${backups[i]}"
            rm -f "${backups[i]}"
        done
    fi
}

# Create backup function
create_backup() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/backup_${BACKUP_TYPE}_${timestamp}"
    
    # Create temporary directory
    mkdir -p "$TEMP_DIR"
    
    # Determine backup command based on type
    case "$BACKUP_TYPE" in
        full)
            backup_file="${backup_file}_full.tar"
            ;;
        incremental)
            local snapshot_file="$BACKUP_DIR/snapshot"
            backup_file="${backup_file}_incr.tar"
            ;;
        differential)
            local base_file="$BACKUP_DIR/base_snapshot"
            backup_file="${backup_file}_diff.tar"
            ;;
        *)
            error_exit "Unknown backup type: $BACKUP_TYPE"
            ;;
    esac
    
    # Add compression extension
    case "$COMPRESSION" in
        gzip)  backup_file="${backup_file}.gz" ;;
        bzip2) backup_file="${backup_file}.bz2" ;;
        xz)    backup_file="${backup_file}.xz" ;;
        *)     error_exit "Unknown compression type: $COMPRESSION" ;;
    esac
    
    log "INFO" "Creating $BACKUP_TYPE backup: $backup_file"
    
    # Create backup based on type and compression
    case "$BACKUP_TYPE" in
        full)
            tar --exclude-from="$EXCLUDE_FILE" \
                --warning=no-file-changed \
                -cf - $BACKUP_SOURCES 2>/dev/null | \
                case "$COMPRESSION" in
                    gzip)  gzip -c ;;
                    bzip2) bzip2 -c ;;
                    xz)    xz -c ;;
                esac > "$backup_file" || {
                error_exit "Backup creation failed"
            }
            ;;
            
        incremental)
            tar --exclude-from="$EXCLUDE_FILE" \
                --warning=no-file-changed \
                --listed-incremental="$snapshot_file" \
                -cf - $BACKUP_SOURCES 2>/dev/null | \
                case "$COMPRESSION" in
                    gzip)  gzip -c ;;
                    bzip2) bzip2 -c ;;
                    xz)    xz -c ;;
                esac > "$backup_file" || {
                error_exit "Backup creation failed"
            }
            ;;
            
        differential)
            if [ ! -f "$base_file" ]; then
                # Create base snapshot if it doesn't exist
                tar --exclude-from="$EXCLUDE_FILE" \
                    --warning=no-file-changed \
                    --listed-incremental="$base_file" \
                    -cf /dev/null $BACKUP_SOURCES 2>/dev/null
            fi
            
            tar --exclude-from="$EXCLUDE_FILE" \
                --warning=no-file-changed \
                --listed-incremental="$base_file" \
                -cf - $BACKUP_SOURCES 2>/dev/null | \
                case "$COMPRESSION" in
                    gzip)  gzip -c ;;
                    bzip2) bzip2 -c ;;
                    xz)    xz -c ;;
                esac > "$backup_file" || {
                error_exit "Backup creation failed"
            }
            ;;
    esac
    
    # Verify backup if enabled
    if [ "$VERIFY_BACKUP" = true ]; then
        verify_backup "$backup_file" || {
            error_exit "Backup verification failed"
        }
    fi
    
    # Perform remote backup if enabled
    remote_backup "$backup_file"
    
    # Rotate backups
    case "$BACKUP_TYPE" in
        full)     rotate_backups "full" "$MONTHLY_BACKUPS" ;;
        incremental) rotate_backups "incr" "$DAILY_BACKUPS" ;;
        differential) rotate_backups "diff" "$WEEKLY_BACKUPS" ;;
    esac
    
    log "INFO" "Backup completed successfully: $backup_file"
    
    # Calculate and display backup size
    local backup_size=$(du -h "$backup_file" | cut -f1)
    log "INFO" "Backup size: $backup_size"
}

# List backups function
list_backups() {
    echo "=== Available Backups ==="
    echo "Location: $BACKUP_DIR"
    echo
    
    if [ -d "$BACKUP_DIR" ]; then
        echo "Full Backups:"
        ls -lh "$BACKUP_DIR"/*full* 2>/dev/null || echo "No full backups found"
        echo
        
        echo "Incremental Backups:"
        ls -lh "$BACKUP_DIR"/*incr* 2>/dev/null || echo "No incremental backups found"
        echo
        
        echo "Differential Backups:"
        ls -lh "$BACKUP_DIR"/*diff* 2>/dev/null || echo "No differential backups found"
    else
        echo "Backup directory does not exist"
    fi
}

# Restore backup function
restore_backup() {
    local backup_file="$1"
    local restore_dir="$2"
    
    if [ ! -f "$backup_file" ]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    if [ -z "$restore_dir" ]; then
        error_exit "Restore directory not specified"
    fi
    
    log "INFO" "Restoring backup: $backup_file"
    log "INFO" "Restore location: $restore_dir"
    
    mkdir -p "$restore_dir"
    
    # Restore based on compression type
    case "$backup_file" in
        *.tar.gz)  tar -xzf "$backup_file" -C "$restore_dir" ;;
        *.tar.bz2) tar -xjf "$backup_file" -C "$restore_dir" ;;
        *.tar.xz)  tar -xJf "$backup_file" -C "$restore_dir" ;;
        *)         error_exit "Unknown backup format: $backup_file" ;;
    esac
    
    log "INFO" "Backup restored successfully"
}

# Show help
show_help() {
    cat << EOF
Backup Management Tool
Usage: $0 <command> [options]

Commands:
    create              Create a new backup
    list                List available backups
    restore <file> <dir> Restore a backup
    verify <file>       Verify a backup
    help                Show this help message

Options:
    -t, --type         Backup type (full, incremental, differential)
    -c, --compression  Compression type (gzip, bzip2, xz)
    -r, --remote       Enable remote backup
    -v, --verify       Enable backup verification

Example:
    $0 create -t full -c gzip
    $0 restore backup_file.tar.gz /restore/path
EOF
}

# Parse command line arguments
case "${1:-}" in
    create)
        shift
        while [ $# -gt 0 ]; do
            case "$1" in
                -t|--type)
                    BACKUP_TYPE="$2"
                    shift 2
                    ;;
                -c|--compression)
                    COMPRESSION="$2"
                    shift 2
                    ;;
                -r|--remote)
                    REMOTE_BACKUP=true
                    shift
                    ;;
                -v|--verify)
                    VERIFY_BACKUP=true
                    shift
                    ;;
                *)
                    error_exit "Unknown option: $1"
                    ;;
            esac
        done
        create_backup
        ;;
    list)
        list_backups
        ;;
    restore)
        if [ -z "${2:-}" ] || [ -z "${3:-}" ]; then
            error_exit "Usage: $0 restore <backup_file> <restore_dir>"
        fi
        restore_backup "$2" "$3"
        ;;
    verify)
        if [ -z "${2:-}" ]; then
            error_exit "Usage: $0 verify <backup_file>"
        fi
        verify_backup "$2"
        ;;
    help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit 0
