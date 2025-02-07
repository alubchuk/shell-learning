# Module 3: Text Processing in Shell

Text processing is a fundamental skill in shell scripting. This module covers the most powerful text processing tools available in Unix-like systems.

## Core Text Processing Tools

### grep (Global Regular Expression Print)
- Search text patterns in files
- Key options:
  - `-i`: Case-insensitive search
  - `-v`: Invert match
  - `-r`: Recursive search
  - `-n`: Show line numbers
  - `-l`: Show only filenames
  - `-c`: Count matches

### sed (Stream Editor)
- Edit text streams (files or input)
- Common operations:
  - Substitution
  - Deletion
  - Insertion
  - Line addressing
  - Regular expressions
- Key commands:
  - `s/pattern/replacement/`: Substitution
  - `d`: Delete lines
  - `i`: Insert before
  - `a`: Append after
  - `c`: Change lines

### awk (Aho, Weinberger, Kernighan)
- Pattern scanning and text processing
- Features:
  - Field processing
  - Mathematical operations
  - Variables
  - Functions
  - Control structures
- Key concepts:
  - Field separators
  - Record processing
  - Built-in variables
  - User-defined functions

## Regular Expressions
- Basic vs Extended regex
- Common patterns:
  - Character classes
  - Quantifiers
  - Anchors
  - Groups and references

## Examples in this Module

1. `01_grep_examples.sh`: Demonstrates various grep use cases
   - Pattern matching
   - Regular expressions
   - File searching
   - Context control

2. `02_sed_examples.sh`: Shows sed operations
   - Text substitution
   - Line operations
   - Multi-line processing
   - File transformations

3. `03_awk_examples.sh`: Covers awk functionality
   - Field processing
   - Calculations
   - Report generation
   - Data transformation

4. `04_practical_example.sh`: Log Analysis Tool
   - Combines grep, sed, and awk
   - Processes log files
   - Generates reports
   - Handles various log formats

## Practice Files
The `sample_data` directory contains various text files to practice with:
- `sample.txt`: General text examples
- `access.log`: Web server log format
- `data.csv`: Comma-separated data
- `config.ini`: Configuration file format
