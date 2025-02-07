#!/bin/bash

# Shell Script Testing Framework
# ---------------------------
# Demonstrates a comprehensive testing framework for shell scripts
# including unit tests, integration tests, and performance tests.

# Strict mode
set -euo pipefail
IFS=$'\n\t'

# Script configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_DIR="$SCRIPT_DIR/tests"
readonly FIXTURE_DIR="$TEST_DIR/fixtures"
readonly REPORT_DIR="$TEST_DIR/reports"
readonly TEMP_DIR="/tmp/shell_test_$$"

# Test statistics
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Color codes
if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly NC=''
fi

# 1. Test Framework Core
# --------------------

# Initialize test environment
init_test_env() {
    mkdir -p "$TEST_DIR" "$FIXTURE_DIR" "$REPORT_DIR" "$TEMP_DIR"
    
    # Create test report file
    REPORT_FILE="$REPORT_DIR/test_report_$(date +%Y%m%d_%H%M%S).txt"
    touch "$REPORT_FILE"
}

# Cleanup test environment
cleanup_test_env() {
    rm -rf "$TEMP_DIR"
}

# Test reporting
log_test() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    
    echo "[$timestamp] [$level] $message" >> "$REPORT_FILE"
    
    case "$level" in
        PASS)    echo -e "${GREEN}[PASS]${NC} $message" ;;
        FAIL)    echo -e "${RED}[FAIL]${NC} $message" ;;
        SKIP)    echo -e "${YELLOW}[SKIP]${NC} $message" ;;
        INFO)    echo -e "${BLUE}[INFO]${NC} $message" ;;
    esac
}

# 2. Assertion Functions
# -------------------

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [ "$expected" = "$actual" ]; then
        return 0
    else
        echo "Expected: '$expected'"
        echo "Actual:   '$actual'"
        [ -n "$message" ] && echo "$message"
        return 1
    fi
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-}"
    
    if [ "$unexpected" != "$actual" ]; then
        return 0
    else
        echo "Expected not: '$unexpected'"
        echo "Actual:      '$actual'"
        [ -n "$message" ] && echo "$message"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        echo "Expected to find: '$needle'"
        echo "In string:       '$haystack'"
        [ -n "$message" ] && echo "$message"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-}"
    
    if [ -f "$file" ]; then
        return 0
    else
        echo "File does not exist: $file"
        [ -n "$message" ] && echo "$message"
        return 1
    fi
}

assert_exit_code() {
    local expected="$1"
    shift
    local command="$*"
    
    if eval "$command" > /dev/null 2>&1; then
        local actual=$?
        if [ "$actual" -eq "$expected" ]; then
            return 0
        else
            echo "Expected exit code: $expected"
            echo "Actual exit code:   $actual"
            echo "Command: $command"
            return 1
        fi
    fi
}

# 3. Test Runner
# ------------

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    echo -n "Running test: $test_name... "
    
    # Create test isolation directory
    local test_temp_dir="$TEMP_DIR/$test_name"
    mkdir -p "$test_temp_dir"
    
    # Run test in subshell for isolation
    if (cd "$test_temp_dir" && $test_function); then
        log_test "PASS" "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_test "FAIL" "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

skip_test() {
    local test_name="$1"
    local reason="${2:-No reason provided}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    
    log_test "SKIP" "$test_name ($reason)"
}

# 4. Performance Testing
# -------------------

measure_performance() {
    local test_name="$1"
    shift
    local command="$*"
    
    echo "Measuring performance: $test_name"
    
    # Run command multiple times and measure
    local runs=5
    local total_time=0
    
    for ((i=1; i<=runs; i++)); do
        local start_time
        local end_time
        local duration
        
        start_time=$(date +%s.%N)
        eval "$command" > /dev/null 2>&1
        end_time=$(date +%s.%N)
        
        duration=$(echo "$end_time - $start_time" | bc)
        total_time=$(echo "$total_time + $duration" | bc)
        
        echo "Run $i: $duration seconds"
    done
    
    # Calculate average
    local average
    average=$(echo "scale=3; $total_time / $runs" | bc)
    echo "Average time: $average seconds"
    
    # Log performance results
    log_test "INFO" "Performance test '$test_name': $average seconds (average of $runs runs)"
}

# 5. Example Tests
# -------------

# Unit tests
test_string_manipulation() {
    local str="Hello, World!"
    local upper="${str^^}"
    assert_equals "HELLO, WORLD!" "$upper" "String uppercase failed"
}

test_arithmetic() {
    local result=$((2 + 2))
    assert_equals 4 "$result" "Basic arithmetic failed"
}

# Integration tests
test_file_operations() {
    # Create test file
    echo "test content" > test.txt
    assert_file_exists "test.txt" "File creation failed"
    
    # Read file content
    local content
    content=$(cat test.txt)
    assert_equals "test content" "$content" "File content mismatch"
}

test_command_execution() {
    local output
    output=$(echo "test" | grep "test")
    assert_equals "test" "$output" "Command pipeline failed"
}

# Performance tests
test_file_read_performance() {
    # Create large test file
    dd if=/dev/zero of=large_file.txt bs=1M count=10 2>/dev/null
    
    measure_performance "read_large_file" "cat large_file.txt > /dev/null"
}

test_sort_performance() {
    # Create file with random numbers
    for ((i=1; i<=10000; i++)); do
        echo "$RANDOM"
    done > numbers.txt
    
    measure_performance "sort_numbers" "sort -n numbers.txt > /dev/null"
}

# 6. Main Test Suite
# ---------------

run_test_suite() {
    init_test_env
    
    # Unit tests
    run_test "String Manipulation" test_string_manipulation
    run_test "Basic Arithmetic" test_arithmetic
    
    # Integration tests
    run_test "File Operations" test_file_operations
    run_test "Command Execution" test_command_execution
    
    # Performance tests
    if [ "${SKIP_PERF_TESTS:-false}" != "true" ]; then
        run_test "File Read Performance" test_file_read_performance
        run_test "Sort Performance" test_sort_performance
    else
        skip_test "Performance Tests" "Disabled by configuration"
    fi
    
    # Print test summary
    echo
    echo "Test Summary:"
    echo "------------"
    echo "Total:   $TESTS_RUN"
    echo -e "${GREEN}Passed:  $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:  $TESTS_FAILED${NC}"
    echo -e "${YELLOW}Skipped: $TESTS_SKIPPED${NC}"
    
    # Cleanup
    cleanup_test_env
    
    # Exit with failure if any tests failed
    [ "$TESTS_FAILED" -eq 0 ]
}

# Run tests if script is executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    run_test_suite
fi
