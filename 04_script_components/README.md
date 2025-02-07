# Module 4: Shell Script Components

This module covers essential components and features that make shell scripts more robust, flexible, and maintainable.

## Command Line Arguments

### Basic Arguments
- Positional parameters (`$1`, `$2`, etc.)
- Special parameters:
  - `$0`: Script name
  - `$#`: Number of arguments
  - `$@`: All arguments as separate strings
  - `$*`: All arguments as a single string

### Argument Manipulation
- The `shift` command:
  - Shifts positional parameters to the left
  - Default shift count is 1
  - `shift n` shifts n positions
  - Reduces `$#` accordingly
  - Common uses:
    - Processing arguments in loops
    - Handling variable argument lists
    - Implementing custom option parsing

### Option Processing
- `getopts` built-in command
- Long options with `getopt`
- Option types:
  - Flags (-f)
  - Options with values (-f value)
  - Long options (--file=value)

### Example Usage
```bash
# Basic shift
while [ $# -gt 0 ]; do
    echo "Processing: $1"
    shift
done

# Shift with named parameters
while [ $# -gt 0 ]; do
    case "$1" in
        --name)
            name="$2"
            shift 2  # Skip both --name and its value
            ;;
        --flag)
            flag=true
            shift    # Skip flag
            ;;
    esac
done
```
## Environment Variables

### System Environment
- Common variables (`PATH`, `HOME`, `USER`, etc.)
- Shell variables (`SHELL`, `PWD`, `RANDOM`, etc.)
- Process variables (`$$`, `$PPID`, etc.)

### Script Environment
- Local vs. global variables
- `export` command
- `env` command
- Subshell environment

## Shell Expansion

### Types of Expansion
1. Brace expansion `{a,b,c}`
2. Tilde expansion `~`
3. Parameter expansion `${var}`
4. Command substitution `$(cmd)`
5. Arithmetic expansion `$((expr))`
6. Word splitting
7. Pathname expansion (globbing)

### Parameter Expansion
- Default values `${var:-default}`
- Assign default `${var:=default}`
- Error if unset `${var:?error}`
- Use alternate value `${var:+value}`
- Substring `${var:offset:length}`
- Pattern matching `${var#pattern}`

## Examples in this Module

1. `01_arguments.sh`: Command-line argument handling
   - Basic argument processing
   - Option parsing
   - Argument validation

2. `02_environment.sh`: Environment variable management
   - System environment
   - Local environment
   - Subshell environment

3. `03_shell_expansion.sh`: Shell expansion examples
   - Different types of expansion
   - Parameter manipulation
   - Pattern matching

4. `04_practical_example.sh`: Configuration Management Tool
   - Command-line interface
   - Environment handling
   - Configuration processing
