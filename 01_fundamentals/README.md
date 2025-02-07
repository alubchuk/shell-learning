# Module 1: Shell Scripting Fundamentals

## What is a Shell?

A shell is a command-line interpreter that provides a user interface for Unix-like operating systems. It serves as an intermediary between the user and the operating system kernel, allowing you to execute commands, run programs, and automate tasks.

## Common Shell Types

1. **Bash (Bourne Again Shell)**
   - Default shell on many Linux distributions
   - Enhanced version of the original Bourne Shell
   - POSIX-compliant

2. **Zsh (Z Shell)**
   - Default shell on macOS since Catalina
   - More features than bash
   - Highly customizable

3. **Others**
   - sh (Bourne Shell)
   - ksh (Korn Shell)
   - fish (Friendly Interactive Shell)

## Basic Shell Concepts

### 1. Shell Scripts
- Text files containing shell commands
- Usually start with a shebang (`#!/bin/bash` or `#!/bin/zsh`)
- Must have execute permissions to run

### 2. Variables
- Store data temporarily
- No data types (everything is stored as strings)
- No declaration needed
- Named using letters, numbers, underscores
- Case-sensitive

### 3. Command Structure
- Commands are read from left to right
- Can be combined using operators
- Can be separated by semicolons
- Can span multiple lines using backslash

## Getting Started

Check out the example scripts in this directory:
1. `01_hello_world.sh` - Your first shell script
2. `02_variables.sh` - Working with variables
3. `03_input_output.sh` - Basic input/output operations

Each script is thoroughly commented to explain the concepts being demonstrated.
