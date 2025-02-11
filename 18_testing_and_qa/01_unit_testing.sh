#!/bin/bash

# =============================================================================
# Shell Script Unit Testing Examples
# This script demonstrates various approaches to unit testing shell scripts,
# including test frameworks, assertions, and mocking.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Sample Functions to Test
# These are the functions we'll be testing in our examples
# -----------------------------------------------------------------------------

# Calculate sum of two numbers
calculate_sum() {
    local a=$1
    local b=$2
    echo $((a + b))
}

# Validate email format
validate_email() {
    local email=$1
    if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get user info from /etc/passwd
get_user_info() {
    local username=$1
    getent passwd "$username" || echo "User not found"
}

# Create temporary file with content
create_temp_file() {
    local content=$1
    local temp_file
    temp_file=$(mktemp)
    echo "$content" > "$temp_file"
    echo "$temp_file"
}

# -----------------------------------------------------------------------------
# Custom Test Framework
# A simple test framework implementation
# -----------------------------------------------------------------------------

# Initialize test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test assertion function
assert() {
    local expected=$1
    local actual=$2
    local message=${3:-""}
    
    ((TESTS_RUN++))
    
    if [ "$expected" = "$actual" ]; then
        ((TESTS_PASSED++))
        echo "✓ Test passed: $message"
    else
        ((TESTS_FAILED++))
        echo "✗ Test failed: $message"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
    fi
}

# Assert function return code
assert_return() {
    local command=$1
    local expected_return=$2
    local message=${3:-""}
    
    ((TESTS_RUN++))
    
    eval "$command"
    local actual_return=$?
    
    if [ "$expected_return" -eq "$actual_return" ]; then
        ((TESTS_PASSED++))
        echo "✓ Test passed: $message"
    else
        ((TESTS_FAILED++))
        echo "✗ Test failed: $message"
        echo "  Expected return: $expected_return"
        echo "  Actual return:   $actual_return"
    fi
}

# Print test summary
print_test_summary() {
    echo "=== Test Summary ==="
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    
    if [ "$TESTS_FAILED" -eq 0 ]; then
        echo "All tests passed! 🎉"
    else
        echo "Some tests failed! 😢"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Mock Functions
# Functions to help with mocking external commands
# -----------------------------------------------------------------------------

# Create mock function
create_mock() {
    local command=$1
    local output=$2
    local return_code=${3:-0}
    
    eval "function $command() { echo '$output'; return $return_code; }"
}

# Remove mock function
remove_mock() {
    local command=$1
    unset -f "$command"
}

# -----------------------------------------------------------------------------
# Test Setup and Teardown
# Functions to run before and after tests
# -----------------------------------------------------------------------------

setup() {
    # Create temporary test directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
}

teardown() {
    # Clean up temporary test directory
    cd - > /dev/null
    rm -rf "$TEST_DIR"
}

# -----------------------------------------------------------------------------
# Unit Tests
# Test cases for our sample functions
# -----------------------------------------------------------------------------

test_calculate_sum() {
    echo "=== Testing calculate_sum ==="
    
    # Test positive numbers
    result=$(calculate_sum 2 3)
    assert "5" "$result" "2 + 3 should equal 5"
    
    # Test negative numbers
    result=$(calculate_sum -1 1)
    assert "0" "$result" "-1 + 1 should equal 0"
    
    # Test zero
    result=$(calculate_sum 0 0)
    assert "0" "$result" "0 + 0 should equal 0"
    
    # Test large numbers
    result=$(calculate_sum 1000000 2000000)
    assert "3000000" "$result" "1000000 + 2000000 should equal 3000000"
}

test_validate_email() {
    echo -e "\n=== Testing validate_email ==="
    
    # Test valid email
    assert_return "validate_email 'user@example.com'" 0 "Valid email should return 0"
    
    # Test invalid emails
    assert_return "validate_email 'invalid.email'" 1 "Invalid email should return 1"
    assert_return "validate_email '@example.com'" 1 "Email without local part should return 1"
    assert_return "validate_email 'user@'" 1 "Email without domain should return 1"
    assert_return "validate_email ''" 1 "Empty email should return 1"
}

test_get_user_info() {
    echo -e "\n=== Testing get_user_info ==="
    
    # Mock getent command
    create_mock "getent" "testuser:x:1000:1000:Test User:/home/testuser:/bin/bash"
    
    # Test existing user
    result=$(get_user_info "testuser")
    assert "testuser:x:1000:1000:Test User:/home/testuser:/bin/bash" "$result" \
        "Should return user info for existing user"
    
    # Mock non-existent user
    create_mock "getent" "" 1
    
    # Test non-existent user
    result=$(get_user_info "nonexistent")
    assert "User not found" "$result" "Should return 'User not found' for non-existent user"
    
    # Remove mock
    remove_mock "getent"
}

test_create_temp_file() {
    echo -e "\n=== Testing create_temp_file ==="
    
    # Test file creation
    local temp_file
    temp_file=$(create_temp_file "test content")
    
    # Check if file exists
    assert "true" "$([ -f "$temp_file" ] && echo true || echo false)" \
        "Temporary file should exist"
    
    # Check file content
    local content
    content=$(cat "$temp_file")
    assert "test content" "$content" "File should contain correct content"
    
    # Clean up
    rm -f "$temp_file"
}

# -----------------------------------------------------------------------------
# Test Runner
# Function to run all tests
# -----------------------------------------------------------------------------

run_tests() {
    echo "Starting unit tests..."
    
    # Run setup
    setup
    
    # Run all test functions
    test_calculate_sum
    test_validate_email
    test_get_user_info
    test_create_temp_file
    
    # Run teardown
    teardown
    
    # Print summary
    echo -e "\n"
    print_test_summary
}

# -----------------------------------------------------------------------------
# Integration with Bats
# Example of using Bats (Bash Automated Testing System)
# -----------------------------------------------------------------------------

setup_bats_tests() {
    echo -e "\n=== Setting Up Bats Tests ==="
    
    # Create tests directory
    mkdir -p tests
    
    # Create test file
    cat << 'EOF' > tests/functions.bats
#!/usr/bin/env bats

load ../01_unit_testing.sh

@test "calculate_sum adds positive numbers" {
    result=$(calculate_sum 2 3)
    [ "$result" -eq 5 ]
}

@test "calculate_sum handles negative numbers" {
    result=$(calculate_sum -1 1)
    [ "$result" -eq 0 ]
}

@test "validate_email accepts valid email" {
    run validate_email "user@example.com"
    [ "$status" -eq 0 ]
}

@test "validate_email rejects invalid email" {
    run validate_email "invalid.email"
    [ "$status" -eq 1 ]
}

@test "get_user_info handles non-existent user" {
    result=$(get_user_info "nonexistent")
    [ "$result" = "User not found" ]
}

@test "create_temp_file creates file with content" {
    temp_file=$(create_temp_file "test content")
    [ -f "$temp_file" ]
    content=$(cat "$temp_file")
    [ "$content" = "test content" ]
    rm -f "$temp_file"
}
EOF
    
    # Make test file executable
    chmod +x tests/functions.bats
    
    echo "Bats tests created in tests/functions.bats"
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting unit testing demonstration..."
    
    # Run custom framework tests
    run_tests
    
    # Setup Bats tests
    setup_bats_tests
    
    echo -e "\nUnit testing demonstration completed."
    echo "To run Bats tests (if installed):"
    echo "bats tests/functions.bats"
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
