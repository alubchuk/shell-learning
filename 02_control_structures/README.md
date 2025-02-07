# Module 2: Control Structures in Shell Scripting

Control structures are fundamental building blocks that allow you to control the flow of execution in your shell scripts. This module covers conditionals, loops, and functions.

## Conditionals

### if statements
- Basic syntax: `if [ condition ]; then ... fi`
- Extended syntax: `if [ condition ]; then ... elif [ condition ]; then ... else ... fi`
- Test operators:
  - `-eq`, `-ne`, `-gt`, `-lt`, `-ge`, `-le`: Numeric comparisons
  - `=`, `!=`, `<`, `>`: String comparisons
  - `-z`, `-n`: String empty/not empty
  - `-f`, `-d`, `-e`: File tests

### case statements
- Pattern matching for multiple conditions
- More readable alternative to complex if-elif structures
- Syntax: `case $var in pattern1) ... ;; pattern2) ... ;; esac`

## Loops

### for loops
- Iterate over a list of items
- Can iterate over:
  - Numbers using sequence
  - Files using globbing
  - Array elements
  - Command output

### while loops
- Execute while condition is true
- Useful for:
  - Reading files line by line
  - Continuous processing
  - User input validation

### until loops
- Execute until condition becomes true
- Opposite of while loop
- Less commonly used but useful in specific scenarios

## Functions

### Function Basics
- Reusable code blocks
- Can take parameters
- Can return values (through exit status)
- Local variable scope
- Must be defined before use

### Best Practices
- Use meaningful function names
- Document parameters
- Return meaningful exit status
- Use local variables
- Keep functions focused and small

## Examples
Check out the example scripts in this directory:
1. `01_conditionals.sh` - If and case statements
2. `02_loops.sh` - For, while, and until loops
3. `03_functions.sh` - Function definition and usage
4. `04_practical_example.sh` - A practical script combining all concepts
