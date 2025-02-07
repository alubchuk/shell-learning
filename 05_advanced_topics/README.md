# Module 5: Advanced Shell Scripting Topics

This module covers advanced shell scripting concepts essential for creating robust and professional scripts.

## Process Management

### Process Basics
- Process creation and termination
- Process states
- Process hierarchy
- Process groups and sessions
- Job control

### Process Information
- Process ID (PID)
- Parent Process ID (PPID)
- Process status
- Resource usage
- Priority and nice values

### Background Processes
- Starting background processes
- Job control commands
- Detaching processes
- Monitoring background jobs

## Signal Handling

### Common Signals
- `SIGHUP` (1): Hangup
- `SIGINT` (2): Interrupt (Ctrl+C)
- `SIGQUIT` (3): Quit
- `SIGKILL` (9): Kill (cannot be caught)
- `SIGTERM` (15): Terminate
- `SIGSTOP` (19): Stop (cannot be caught)

### Signal Management
- Trapping signals
- Default handlers
- Custom handlers
- Signal masking
- Signal propagation

## Command Evaluation

### The eval Command
- Evaluates and executes arguments as shell commands
- Performs variable and command substitution
- Allows dynamic command construction
- Requires careful security consideration

### Common Use Cases
1. Dynamic Variable Names
   ```bash
   prefix="MY_VAR"
   eval "${prefix}_1='value1'"
   eval "echo \$${prefix}_1"
   ```

2. Command String Building
   ```bash
   cmd="find . -name '*.txt' -exec ls -l {} \;"
   eval "$cmd"
   ```

3. Indirect References
   ```bash
   array_name="my_array"
   eval "echo \${${array_name}[@]}"
   ```

### Security Considerations
- Never use eval with untrusted input
- Validate and sanitize all inputs
- Use parameter expansion when possible
- Consider alternatives like arrays or case statements

### Best Practices
1. Input Validation
   ```bash
   if [[ ! "$var_name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
       echo "Invalid variable name"
       exit 1
   fi
   ```

2. Error Handling
   ```bash
   if ! eval "$cmd"; then
       echo "Command failed: $cmd"
       exit 1
   fi
   ```

3. Safe Alternatives
   ```bash
   # Instead of eval, use arrays
   declare -A vars
   vars["${prefix}_1"]="value1"
   echo "${vars[${prefix}_1]}"
   ```

## Error Handling

### Error Types
- Syntax errors
- Runtime errors
- Logical errors
- System errors

### Error Handling Techniques
- Exit codes
- Error messages
- Error logging
- Cleanup handlers
- Defensive programming

### Debugging
- Debug mode
- Trace execution
- Logging levels
- Common debugging tools

## Examples in this Module

1. `01_process_management.sh`: Process creation and control
   - Process creation
   - Background jobs
   - Process monitoring
   - Resource management

2. `02_signal_handling.sh`: Signal handling and traps
   - Signal trapping
   - Cleanup handlers
   - Graceful shutdown
   - Signal propagation

3. `03_error_handling.sh`: Error handling and debugging
   - Error detection
   - Error reporting
   - Cleanup procedures
   - Debug modes

4. `04_practical_example.sh`: Process Monitor and Control Tool
   - Process monitoring
   - Resource tracking
   - Signal handling
   - Error management
