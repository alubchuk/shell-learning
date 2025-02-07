#!/bin/bash

# Advanced Array Operations
# ----------------------
# This script demonstrates advanced usage of associative arrays
# and array operations in bash.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly OUTPUT_DIR="$SCRIPT_DIR/output"
readonly CACHE_DIR="$OUTPUT_DIR/cache"

# Ensure directories exist
mkdir -p "$OUTPUT_DIR" "$CACHE_DIR"

# 1. Basic Array Operations
# ---------------------

basic_operations() {
    echo "Basic Array Operations:"
    echo "---------------------"
    
    # Declare associative array
    declare -A config
    
    # Initialize with key-value pairs
    config=(
        [host]="localhost"
        [port]="8080"
        [user]="admin"
        [password]="secret"
    )
    
    # Access and print values
    echo "1. Direct access:"
    echo "Host: ${config[host]}"
    echo "Port: ${config[port]}"
    
    # Check if key exists
    echo -e "\n2. Key existence:"
    if [[ -v config[host] ]]; then
        echo "Host key exists"
    fi
    
    # Get all keys
    echo -e "\n3. All keys:"
    echo "${!config[@]}"
    
    # Get all values
    echo -e "\n4. All values:"
    echo "${config[@]}"
    
    # Count elements
    echo -e "\n5. Array size:"
    echo "${#config[@]}"
}

# 2. Array Iteration
# --------------

array_iteration() {
    echo "Array Iteration:"
    echo "---------------"
    
    # Declare and initialize array
    declare -A fruits=(
        [apple]="red"
        [banana]="yellow"
        [grape]="purple"
        [orange]="orange"
    )
    
    # Iterate over key-value pairs
    echo "1. Key-value iteration:"
    for key in "${!fruits[@]}"; do
        echo "$key -> ${fruits[$key]}"
    done
    
    # Sort keys before iteration
    echo -e "\n2. Sorted iteration:"
    readarray -t sorted_keys < <(printf '%s\n' "${!fruits[@]}" | sort)
    for key in "${sorted_keys[@]}"; do
        echo "$key -> ${fruits[$key]}"
    done
    
    # Filter and iterate
    echo -e "\n3. Filtered iteration:"
    for key in "${!fruits[@]}"; do
        if [[ ${fruits[$key]} == *"e"* ]]; then
            echo "$key has 'e' in its color"
        fi
    done
}

# 3. Array Manipulation
# -----------------

array_manipulation() {
    echo "Array Manipulation:"
    echo "------------------"
    
    # Declare array
    declare -A numbers
    
    # Add elements
    echo "1. Adding elements:"
    numbers[one]=1
    numbers[two]=2
    numbers[three]=3
    echo "Current array: ${numbers[@]}"
    
    # Update element
    echo -e "\n2. Updating elements:"
    numbers[two]=22
    echo "After update: ${numbers[@]}"
    
    # Delete element
    echo -e "\n3. Deleting elements:"
    unset "numbers[one]"
    echo "After deletion: ${numbers[@]}"
    
    # Clear array
    echo -e "\n4. Clearing array:"
    numbers=()
    echo "After clearing: ${numbers[@]:-empty}"
}

# 4. Advanced Patterns
# ----------------

# Configuration manager
config_manager() {
    local operation="$1"
    local key="${2:-}"
    local value="${3:-}"
    
    # Initialize configuration
    declare -A config
    
    # Load existing config if available
    if [[ -f "$CACHE_DIR/config.txt" ]]; then
        while IFS='=' read -r k v; do
            [[ $k ]] || continue
            config[$k]="$v"
        done < "$CACHE_DIR/config.txt"
    fi
    
    case "$operation" in
        get)
            if [[ -v config[$key] ]]; then
                echo "${config[$key]}"
            else
                echo "Key not found: $key" >&2
                return 1
            fi
            ;;
        set)
            config[$key]="$value"
            # Save to file
            {
                for k in "${!config[@]}"; do
                    echo "$k=${config[$k]}"
                done
            } > "$CACHE_DIR/config.txt"
            echo "Set $key=$value"
            ;;
        list)
            for k in "${!config[@]}"; do
                echo "$k=${config[$k]}"
            done
            ;;
        delete)
            if [[ -v config[$key] ]]; then
                unset "config[$key]"
                # Update file
                {
                    for k in "${!config[@]}"; do
                        echo "$k=${config[$k]}"
                    done
                } > "$CACHE_DIR/config.txt"
                echo "Deleted $key"
            else
                echo "Key not found: $key" >&2
                return 1
            fi
            ;;
        *)
            echo "Unknown operation: $operation" >&2
            return 1
            ;;
    esac
}

# Cache implementation
cache_manager() {
    declare -A cache
    local max_size=100
    local cleanup_threshold=80
    
    # Add to cache
    add_to_cache() {
        local key="$1"
        local value="$2"
        
        # Check cache size
        if ((${#cache[@]} >= max_size)); then
            # Remove oldest entries
            local to_remove=$((${#cache[@]} - cleanup_threshold))
            readarray -t sorted_keys < <(printf '%s\n' "${!cache[@]}" | sort)
            for ((i=0; i<to_remove; i++)); do
                unset "cache[${sorted_keys[$i]}]"
            done
        fi
        
        cache[$key]="$value"
    }
    
    # Get from cache
    get_from_cache() {
        local key="$1"
        if [[ -v cache[$key] ]]; then
            echo "${cache[$key]}"
            return 0
        fi
        return 1
    }
    
    # Cache statistics
    cache_stats() {
        echo "Cache size: ${#cache[@]}"
        echo "Keys: ${!cache[@]}"
    }
    
    # Example usage
    echo "Cache Operations:"
    echo "---------------"
    
    # Add items
    for ((i=1; i<=5; i++)); do
        add_to_cache "key$i" "value$i"
    done
    
    # Show stats
    echo "1. Initial cache:"
    cache_stats
    
    # Retrieve item
    echo -e "\n2. Get key3:"
    get_from_cache "key3"
    
    # Add more items
    echo -e "\n3. Adding more items:"
    for ((i=6; i<=90; i++)); do
        add_to_cache "key$i" "value$i"
    done
    
    # Show final stats
    echo -e "\n4. Final cache:"
    cache_stats
}

# Data processing with arrays
data_processor() {
    # Sample data structure
    declare -A users
    declare -A scores
    
    # Initialize data
    users=(
        [1]="John"
        [2]="Jane"
        [3]="Bob"
    )
    
    scores=(
        [John]=85
        [Jane]=92
        [Bob]=78
    )
    
    echo "Data Processing:"
    echo "---------------"
    
    # Calculate average score
    local total=0
    for user in "${users[@]}"; do
        ((total += scores[$user]))
    done
    echo "1. Average score: $((total / ${#users[@]}))"
    
    # Find highest score
    local max_score=0
    local top_student=""
    for user in "${users[@]}"; do
        if ((scores[$user] > max_score)); then
            max_score=${scores[$user]}
            top_student=$user
        fi
    done
    echo "2. Top student: $top_student ($max_score)"
    
    # Grade distribution
    declare -A grades
    for user in "${users[@]}"; do
        local score=${scores[$user]}
        case $score in
            9[0-9]|100) grades[$user]="A" ;;
            8[0-9])     grades[$user]="B" ;;
            7[0-9])     grades[$user]="C" ;;
            6[0-9])     grades[$user]="D" ;;
            *)          grades[$user]="F" ;;
        esac
    done
    
    echo "3. Grade distribution:"
    for user in "${users[@]}"; do
        echo "$user: ${grades[$user]}"
    done
}

# Main execution
main() {
    # Run examples
    basic_operations
    echo -e "\n"
    array_iteration
    echo -e "\n"
    array_manipulation
    echo -e "\n"
    
    # Configuration manager example
    echo "Configuration Manager:"
    echo "--------------------"
    config_manager set "database.host" "localhost"
    config_manager set "database.port" "5432"
    config_manager list
    config_manager get "database.host"
    config_manager delete "database.port"
    echo -e "\n"
    
    # Cache manager example
    cache_manager
    echo -e "\n"
    
    # Data processor example
    data_processor
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
