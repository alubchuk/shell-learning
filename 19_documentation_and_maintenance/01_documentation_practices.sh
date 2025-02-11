#!/bin/bash

# =============================================================================
# Shell Script Documentation Examples
# This script demonstrates best practices for shell script documentation,
# including code comments, function documentation, usage guides, and
# automatic documentation generation.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Script Version and Metadata
# -----------------------------------------------------------------------------
readonly VERSION="1.0.0"
readonly AUTHOR="Your Name"
readonly LICENSE="MIT"
readonly DESCRIPTION="Example script demonstrating shell script documentation practices"

# -----------------------------------------------------------------------------
# Configuration Variables
# -----------------------------------------------------------------------------
readonly DEFAULT_CONFIG_FILE="${HOME}/.config/example.conf"
readonly DEFAULT_LOG_DIR="/var/log/example"
readonly DEFAULT_BACKUP_DIR="/var/backup/example"

# -----------------------------------------------------------------------------
# Function: show_usage
# Description: Display script usage information
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
show_usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] COMMAND

${DESCRIPTION}

Commands:
    start       Start the service
    stop        Stop the service
    restart     Restart the service
    status      Show service status
    backup      Create backup of configuration
    restore     Restore configuration from backup

Options:
    -h, --help      Show this help message
    -v, --version   Show version information
    -c, --config    Specify config file (default: ${DEFAULT_CONFIG_FILE})
    -l, --log-dir   Specify log directory (default: ${DEFAULT_LOG_DIR})
    -b, --backup    Specify backup directory (default: ${DEFAULT_BACKUP_DIR})
    -d, --debug     Enable debug mode
    -q, --quiet     Suppress output

Examples:
    # Start service with default configuration
    $(basename "$0") start

    # Start service with custom config
    $(basename "$0") -c /path/to/config.conf start

    # Create backup with custom backup directory
    $(basename "$0") -b /path/to/backup backup

For more information, visit:
https://github.com/yourusername/yourproject

Report bugs to: youremail@example.com
EOF
}

# -----------------------------------------------------------------------------
# Function: show_version
# Description: Display script version information
# Arguments: None
# Returns: None
# -----------------------------------------------------------------------------
show_version() {
    cat << EOF
$(basename "$0") version ${VERSION}
Copyright (C) $(date +%Y) ${AUTHOR}
License: ${LICENSE}

Written by ${AUTHOR}
EOF
}

# -----------------------------------------------------------------------------
# Function: log_message
# Description: Log a message with timestamp and level
# Arguments:
#   $1 - Log level (INFO, WARNING, ERROR, DEBUG)
#   $2 - Message to log
# Returns: None
# Example:
#   log_message "INFO" "Service started successfully"
# -----------------------------------------------------------------------------
log_message() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] ${message}"
}

# -----------------------------------------------------------------------------
# Function: validate_config
# Description: Validate configuration file format and settings
# Arguments:
#   $1 - Path to configuration file
# Returns:
#   0 - Configuration is valid
#   1 - Configuration is invalid
# Outputs:
#   Writes validation errors to stderr
# -----------------------------------------------------------------------------
validate_config() {
    local config_file=$1
    
    # Check if file exists
    if [ ! -f "$config_file" ]; then
        log_message "ERROR" "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check file permissions
    if [ ! -r "$config_file" ]; then
        log_message "ERROR" "Configuration file not readable: $config_file"
        return 1
    fi
    
    # Validate configuration format
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # Trim whitespace
        key=${key// /}
        value=${value// /}
        
        # Validate key-value format
        if [[ -z $value ]]; then
            log_message "ERROR" "Invalid configuration: missing value for key '$key'"
            return 1
        fi
    done < "$config_file"
    
    return 0
}

# -----------------------------------------------------------------------------
# Function: create_documentation
# Description: Generate documentation from script comments
# Arguments:
#   $1 - Output directory for documentation
# Returns:
#   0 - Documentation generated successfully
#   1 - Error generating documentation
# -----------------------------------------------------------------------------
create_documentation() {
    local output_dir=$1
    local script_path
    script_path=$(realpath "$0")
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Generate README.md
    cat << EOF > "${output_dir}/README.md"
# $(basename "$0")

${DESCRIPTION}

## Version

${VERSION}

## Author

${AUTHOR}

## License

${LICENSE}

## Installation

\`\`\`bash
# Clone repository
git clone https://github.com/yourusername/yourproject

# Make script executable
chmod +x $(basename "$0")

# Create default directories
sudo mkdir -p ${DEFAULT_LOG_DIR}
sudo mkdir -p ${DEFAULT_BACKUP_DIR}
\`\`\`

## Usage

$(show_usage)

## Configuration

The script uses a configuration file in INI format. Default location: \`${DEFAULT_CONFIG_FILE}\`

Example configuration:
\`\`\`ini
# Service configuration
service.name=example
service.port=8080

# Logging configuration
log.level=INFO
log.format=text

# Backup configuration
backup.retention=7
backup.compress=true
\`\`\`

## Functions

EOF
    
    # Extract function documentation
    grep -A 1 "^# Function:" "$script_path" | while read -r line1 && read -r line2; do
        if [[ $line1 =~ ^#[[:space:]]Function:[[:space:]](.*)$ ]]; then
            func_name=${BASH_REMATCH[1]}
            func_desc=${line2#\# Description: }
            echo "### \`${func_name}\`" >> "${output_dir}/README.md"
            echo "" >> "${output_dir}/README.md"
            echo "${func_desc}" >> "${output_dir}/README.md"
            echo "" >> "${output_dir}/README.md"
        fi
    done
    
    # Generate man page
    cat << EOF > "${output_dir}/$(basename "$0").1"
.TH "$(basename "$0" | tr '[:lower:]' '[:upper:]')" 1 "$(date +"%B %Y")" "${VERSION}" "User Commands"
.SH NAME
$(basename "$0") \- ${DESCRIPTION}
.SH SYNOPSIS
.B $(basename "$0")
[\fIOPTIONS\fR] \fICOMMAND\fR
.SH DESCRIPTION
${DESCRIPTION}
.SH OPTIONS
.TP
.BR \-h ", " \-\-help
Show help message and exit
.TP
.BR \-v ", " \-\-version
Show version information and exit
.TP
.BR \-c ", " \-\-config =\fIFILE\fR
Specify configuration file
.TP
.BR \-l ", " \-\-log\-dir =\fIDIR\fR
Specify log directory
.TP
.BR \-b ", " \-\-backup =\fIDIR\fR
Specify backup directory
.SH FILES
.TP
.I ${DEFAULT_CONFIG_FILE}
Default configuration file
.TP
.I ${DEFAULT_LOG_DIR}
Default log directory
.TP
.I ${DEFAULT_BACKUP_DIR}
Default backup directory
.SH AUTHOR
Written by ${AUTHOR}
.SH COPYRIGHT
Copyright \(co $(date +%Y) ${AUTHOR}
.br
License: ${LICENSE}
.SH BUGS
Report bugs to: youremail@example.com
EOF
    
    # Generate HTML documentation using pandoc if available
    if command -v pandoc >/dev/null 2>&1; then
        pandoc "${output_dir}/README.md" -o "${output_dir}/index.html" \
            --standalone --toc --toc-depth=2 \
            --metadata title="$(basename "$0") Documentation" \
            --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css
    fi
    
    log_message "INFO" "Documentation generated in ${output_dir}"
    return 0
}

# -----------------------------------------------------------------------------
# Function: setup_dev_environment
# Description: Set up development environment with documentation tools
# Arguments: None
# Returns:
#   0 - Setup successful
#   1 - Setup failed
# -----------------------------------------------------------------------------
setup_dev_environment() {
    echo "Setting up development environment..."
    
    # Create development directory structure
    mkdir -p {docs,tests,scripts,examples}
    
    # Create documentation templates
    cat << 'EOF' > docs/CONTRIBUTING.md
# Contributing Guidelines

## Code Style

- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use shellcheck for linting
- Add comments for complex logic
- Document all functions

## Documentation

- Update README.md when adding features
- Include examples in docs/examples/
- Update man pages if CLI changes
- Add tests for new features

## Pull Requests

1. Fork repository
2. Create feature branch
3. Add tests
4. Update documentation
5. Submit pull request

## Development Setup

\`\`\`bash
# Install development tools
brew install shellcheck pandoc
npm install -g doctoc

# Set up pre-commit hooks
cp scripts/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
\`\`\`
EOF
    
    # Create example documentation
    cat << 'EOF' > docs/examples/README.md
# Examples

This directory contains example scripts and configurations demonstrating various use cases.

## Basic Usage

\`\`\`bash
# Start service
./example.sh start

# Create backup
./example.sh backup
\`\`\`

## Advanced Usage

See individual example files for detailed documentation.
EOF
    
    # Create documentation generation script
    cat << 'EOF' > scripts/generate-docs.sh
#!/bin/bash
set -euo pipefail

# Update table of contents
doctoc README.md

# Generate man pages
for script in *.sh; do
    help2man -N "./$script" > "docs/man/$script.1"
done

# Generate HTML docs
pandoc README.md -o docs/index.html \
    --standalone --toc --toc-depth=2 \
    --metadata title="Project Documentation" \
    --css=https://cdn.jsdelivr.net/npm/water.css@2/out/water.css
EOF
    chmod +x scripts/generate-docs.sh
    
    # Create pre-commit hook for documentation
    cat << 'EOF' > scripts/pre-commit
#!/bin/bash
set -euo pipefail

# Check if documentation is up to date
./scripts/generate-docs.sh

# Check if changes were made
if git diff --quiet docs/; then
    echo "Documentation is up to date"
else
    echo "Documentation needs to be updated"
    echo "Run ./scripts/generate-docs.sh and commit changes"
    exit 1
fi
EOF
    chmod +x scripts/pre-commit
    
    echo "Development environment setup complete"
    return 0
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting documentation practices demonstration..."
    
    # Create documentation
    create_documentation "docs"
    
    # Setup development environment
    setup_dev_environment
    
    echo "Documentation practices demonstration completed."
    echo "Documentation available in docs/"
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
