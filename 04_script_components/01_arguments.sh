#!/bin/bash

# Command Line Arguments Examples
# -----------------------------

# Function to display script usage
show_help() {
    cat << EOF
Command Line Arguments Demo
Usage: $0 [options] <input-file>

Options:
    -h, --help              Show this help message
    -v, --verbose          Enable verbose output
    -o, --output FILE      Specify output file
    -n, --number NUMBER    Specify a number
    -l, --list ITEMS       Comma-separated list of items
    --debug               Enable debug mode

Example:
    $0 -v -o output.txt -n 42 --list "a,b,c" input.txt
EOF
}

# Function to log messages in verbose mode
log() {
    if [ "$VERBOSE" = true ]; then
        echo "[LOG] $1"
    fi
}

# Initialize variables
VERBOSE=false
OUTPUT_FILE=""
NUMBER=""
ITEMS=""
DEBUG=false

# Basic argument demonstration
echo "1. Basic Argument Information:"
echo "Script name: $0"
echo "Number of arguments: $#"
echo "All arguments: $@"
echo

# Demonstrate different ways to access all arguments
echo "2. Different Ways to Access Arguments:"
echo "Using \$*: $*"
echo "Using \$@: $@"
echo "Difference demonstration:"
echo "Using \"\$*\":"
for arg in "$*"; do
    echo "  Arg: $arg"
done
echo "Using \"\$@\":"
for arg in "$@"; do
    echo "  Arg: $arg"
done
echo

# Process options using getopts
echo "3. Processing Short Options with getopts:"
while getopts ":hvo:n:l:" opt; do
    case $opt in
        h)
            show_help
            exit 0
            ;;
        v)
            VERBOSE=true
            log "Verbose mode enabled"
            ;;
        o)
            OUTPUT_FILE="$OPTARG"
            log "Output file set to: $OUTPUT_FILE"
            ;;
        n)
            NUMBER="$OPTARG"
            log "Number set to: $NUMBER"
            ;;
        l)
            ITEMS="$OPTARG"
            log "Items set to: $ITEMS"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Shift past the processed options
shift $((OPTIND-1))

# Process remaining arguments (if any)
if [ $# -gt 0 ]; then
    INPUT_FILE="$1"
    log "Input file set to: $INPUT_FILE"
else
    echo "Error: Input file is required"
    show_help
    exit 1
fi

# Demonstrate processing long options manually
echo "4. Processing Long Options Manually:"
process_long_options() {
    while [ $# -gt 0 ]; do
        case "$1" in
            --help)
                show_help
                exit 0
                ;;
            --verbose)
                VERBOSE=true
                log "Verbose mode enabled"
                ;;
            --output=*)
                OUTPUT_FILE="${1#*=}"
                log "Output file set to: $OUTPUT_FILE"
                ;;
            --number=*)
                NUMBER="${1#*=}"
                log "Number set to: $NUMBER"
                ;;
            --list=*)
                ITEMS="${1#*=}"
                log "Items set to: $ITEMS"
                ;;
            --debug)
                DEBUG=true
                log "Debug mode enabled"
                ;;
            -*)
                echo "Error: Unknown option $1" >&2
                exit 1
                ;;
            *)
                INPUT_FILE="$1"
                ;;
        esac
        shift
    done
}

# Example of argument validation
validate_arguments() {
    # Validate number
    if [ -n "$NUMBER" ] && ! [[ "$NUMBER" =~ ^[0-9]+$ ]]; then
        echo "Error: Number must be a positive integer" >&2
        exit 1
    fi

    # Validate output file
    if [ -n "$OUTPUT_FILE" ]; then
        if [ -e "$OUTPUT_FILE" ]; then
            echo "Warning: Output file already exists and will be overwritten"
        fi
        if ! touch "$OUTPUT_FILE" 2>/dev/null; then
            echo "Error: Cannot write to output file: $OUTPUT_FILE" >&2
            exit 1
        fi
        rm "$OUTPUT_FILE"  # Clean up the test file
    fi

    # Validate input file
    if [ ! -f "$INPUT_FILE" ]; then
        echo "Error: Input file does not exist: $INPUT_FILE" >&2
        exit 1
    fi
    if [ ! -r "$INPUT_FILE" ]; then
        echo "Error: Input file is not readable: $INPUT_FILE" >&2
        exit 1
    fi
}

# Example of processing a list argument
process_list() {
    if [ -n "$ITEMS" ]; then
        echo "Processing items:"
        IFS=',' read -ra ITEMS_ARRAY <<< "$ITEMS"
        for item in "${ITEMS_ARRAY[@]}"; do
            echo "  - $item"
        done
    fi
}

# Display final configuration
show_configuration() {
    cat << EOF

Final Configuration:
------------------
Verbose mode: $VERBOSE
Debug mode: $DEBUG
Input file: $INPUT_FILE
Output file: ${OUTPUT_FILE:-"(none)"}
Number: ${NUMBER:-"(none)"}
Items: ${ITEMS:-"(none)"}

EOF
}

# Example usage demonstration
if [ "$VERBOSE" = true ]; then
    show_configuration
    process_list
fi

# Debug information
if [ "$DEBUG" = true ]; then
    cat << EOF
Debug Information:
----------------
Script PID: $$
Parent PID: $PPID
Current directory: $PWD
Argument count: $#
Shell: $SHELL
EOF
fi
