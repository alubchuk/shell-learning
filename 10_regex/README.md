# Module 10: Regular Expressions in Shell Scripting

This module covers regular expressions (regex) in shell scripting, focusing on pattern matching, text processing, and validation using various tools like grep, sed, and awk.

## Basic Concepts

### Character Classes
- Single characters: `a`, `b`, `c`
- Character ranges: `[a-z]`, `[0-9]`
- Negated classes: `[^0-9]`
- Predefined classes: `[:digit:]`, `[:alpha:]`, `[:space:]`

### Quantifiers
- Zero or more: `*`
- One or more: `+`
- Zero or one: `?`
- Exact count: `{n}`
- Range count: `{n,m}`

### Anchors
- Start of line: `^`
- End of line: `$`
- Word boundary: `\b`
- Non-word boundary: `\B`

### Special Characters
- Any character: `.`
- Escape character: `\`
- Alternation: `|`
- Grouping: `()`
- Back references: `\1`, `\2`

## Tools and Usage

### grep
- Basic pattern matching
- Extended regular expressions (-E)
- Perl-compatible regex (-P)
- Case sensitivity
- Recursive search
- Context lines

### sed
- Pattern substitution
- Line operations
- Multiple commands
- In-place editing
- Back references
- Address ranges

### awk
- Pattern matching
- Field processing
- Regular expressions
- Built-in variables
- Functions
- Control structures

## Examples in this Module

1. `01_basic_regex.sh`: Basic regex patterns
   - Character matching
   - Quantifiers
   - Anchors
   - Groups

2. `02_grep_examples.sh`: grep usage
   - Search patterns
   - File filtering
   - Context display
   - Recursive search

3. `03_sed_examples.sh`: sed operations
   - Text substitution
   - Line manipulation
   - Multiple edits
   - Back references

4. `04_awk_examples.sh`: awk processing
   - Field operations
   - Pattern matching
   - Text processing
   - Report generation

5. `05_practical_example.sh`: Log Analysis Tool
   - Pattern extraction
   - Data validation
   - Text transformation
   - Report generation

## Common Use Cases

### Text Processing
- Email validation
- Phone number formatting
- URL extraction
- Log parsing
- Data cleaning

### File Operations
- File name patterns
- Content filtering
- Batch renaming
- Code analysis
- Configuration parsing

### Data Validation
- Input sanitization
- Format checking
- Pattern enforcement
- Error detection
- Data extraction

### System Administration
- Log analysis
- Configuration management
- Process monitoring
- User input validation
- File system operations

## Best Practices

1. **Readability**
   - Comment complex patterns
   - Use extended syntax for clarity
   - Break down complex patterns
   - Use meaningful variable names

2. **Performance**
   - Optimize patterns for efficiency
   - Use appropriate tools
   - Consider input size
   - Cache compiled patterns

3. **Maintainability**
   - Document regex patterns
   - Test with various inputs
   - Use version control
   - Keep patterns modular

4. **Debugging**
   - Use regex debuggers
   - Test incrementally
   - Validate assumptions
   - Handle edge cases

## Common Patterns

### Email Validation
```regex
^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$
```

### URL Matching
```regex
^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$
```

### Phone Numbers
```regex
^\+?[1-9][0-9]{7,14}$
```

### Date Formats
```regex
^(19|20)\d\d[- /.](0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])$
```

### IP Addresses
```regex
^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$
```
