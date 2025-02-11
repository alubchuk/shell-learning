#!/bin/bash

# =============================================================================
# Shell Script Integration Testing Examples
# This script demonstrates integration testing approaches for shell scripts,
# including API testing, database testing, and system integration testing.
# =============================================================================

# Enable strict mode
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Sample Application
# A simple REST API server and database application to test
# -----------------------------------------------------------------------------

# Start API server
start_api_server() {
    echo "Starting API server on port 8080..."
    python3 -m http.server 8080 &
    PYTHON_PID=$!
    sleep 1  # Wait for server to start
}

# Stop API server
stop_api_server() {
    if [ -n "${PYTHON_PID:-}" ]; then
        echo "Stopping API server..."
        kill "$PYTHON_PID" || true
    fi
}

# Start test database
start_test_db() {
    echo "Starting test database..."
    mkdir -p data
    
    # Create SQLite database
    sqlite3 data/test.db << 'EOF'
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    title TEXT NOT NULL,
    content TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
EOF
}

# Stop test database
stop_test_db() {
    echo "Cleaning up test database..."
    rm -rf data
}

# -----------------------------------------------------------------------------
# Test Framework
# Integration test framework implementation
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
# API Testing Functions
# Functions to test REST API endpoints
# -----------------------------------------------------------------------------

test_api_health() {
    echo "=== Testing API Health ==="
    
    # Test health endpoint
    local response
    response=$(curl -s http://localhost:8080/health)
    assert '{"status":"ok"}' "$response" "Health check should return ok status"
    
    # Test with wrong method
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" -X POST http://localhost:8080/health)
    assert "405" "$status_code" "POST to health endpoint should return 405"
}

test_api_users() {
    echo -e "\n=== Testing Users API ==="
    
    # Test user creation
    local user_response
    user_response=$(curl -s -X POST http://localhost:8080/users \
        -H "Content-Type: application/json" \
        -d '{"name":"Test User","email":"test@example.com"}')
    assert '{"id":1,"name":"Test User","email":"test@example.com"}' "$user_response" \
        "Should create new user"
    
    # Test user retrieval
    local get_response
    get_response=$(curl -s http://localhost:8080/users/1)
    assert '{"id":1,"name":"Test User","email":"test@example.com"}' "$get_response" \
        "Should retrieve created user"
    
    # Test user update
    local update_response
    update_response=$(curl -s -X PUT http://localhost:8080/users/1 \
        -H "Content-Type: application/json" \
        -d '{"name":"Updated User","email":"updated@example.com"}')
    assert '{"id":1,"name":"Updated User","email":"updated@example.com"}' "$update_response" \
        "Should update user"
    
    # Test user deletion
    local delete_status
    delete_status=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE http://localhost:8080/users/1)
    assert "204" "$delete_status" "Should delete user"
}

# -----------------------------------------------------------------------------
# Database Testing Functions
# Functions to test database operations
# -----------------------------------------------------------------------------

test_db_users() {
    echo -e "\n=== Testing Database Users ==="
    
    # Test user insertion
    sqlite3 data/test.db << 'EOF'
INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');
EOF
    
    # Verify user was inserted
    local user_count
    user_count=$(sqlite3 data/test.db "SELECT COUNT(*) FROM users WHERE email='test@example.com'")
    assert "1" "$user_count" "Should insert one user"
    
    # Test user update
    sqlite3 data/test.db << 'EOF'
UPDATE users SET name='Updated User' WHERE email='test@example.com';
EOF
    
    # Verify user was updated
    local updated_name
    updated_name=$(sqlite3 data/test.db "SELECT name FROM users WHERE email='test@example.com'")
    assert "Updated User" "$updated_name" "Should update user name"
    
    # Test user deletion
    sqlite3 data/test.db "DELETE FROM users WHERE email='test@example.com'"
    
    # Verify user was deleted
    local remaining_count
    remaining_count=$(sqlite3 data/test.db "SELECT COUNT(*) FROM users WHERE email='test@example.com'")
    assert "0" "$remaining_count" "Should delete user"
}

test_db_posts() {
    echo -e "\n=== Testing Database Posts ==="
    
    # Create test user
    sqlite3 data/test.db << 'EOF'
INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');
EOF
    local user_id
    user_id=$(sqlite3 data/test.db "SELECT id FROM users WHERE email='test@example.com'")
    
    # Test post creation
    sqlite3 data/test.db << EOF
INSERT INTO posts (user_id, title, content) 
VALUES ($user_id, 'Test Post', 'This is a test post');
EOF
    
    # Verify post was created
    local post_count
    post_count=$(sqlite3 data/test.db "SELECT COUNT(*) FROM posts WHERE user_id=$user_id")
    assert "1" "$post_count" "Should create one post"
    
    # Test post update
    sqlite3 data/test.db << EOF
UPDATE posts SET content='Updated content' WHERE user_id=$user_id;
EOF
    
    # Verify post was updated
    local updated_content
    updated_content=$(sqlite3 data/test.db "SELECT content FROM posts WHERE user_id=$user_id")
    assert "Updated content" "$updated_content" "Should update post content"
    
    # Clean up
    sqlite3 data/test.db << EOF
DELETE FROM posts WHERE user_id=$user_id;
DELETE FROM users WHERE id=$user_id;
EOF
}

# -----------------------------------------------------------------------------
# System Integration Tests
# Tests that verify multiple components working together
# -----------------------------------------------------------------------------

test_user_workflow() {
    echo -e "\n=== Testing Complete User Workflow ==="
    
    # 1. Create user via API
    local user_id
    user_id=$(curl -s -X POST http://localhost:8080/users \
        -H "Content-Type: application/json" \
        -d '{"name":"Workflow User","email":"workflow@example.com"}' | jq -r '.id')
    
    # 2. Verify user in database
    local db_name
    db_name=$(sqlite3 data/test.db "SELECT name FROM users WHERE id=$user_id")
    assert "Workflow User" "$db_name" "User should exist in database"
    
    # 3. Create post for user
    curl -s -X POST http://localhost:8080/posts \
        -H "Content-Type: application/json" \
        -d "{\"user_id\":$user_id,\"title\":\"Test Post\",\"content\":\"Test content\"}"
    
    # 4. Verify post in database
    local post_count
    post_count=$(sqlite3 data/test.db "SELECT COUNT(*) FROM posts WHERE user_id=$user_id")
    assert "1" "$post_count" "Post should exist in database"
    
    # 5. Update user email
    curl -s -X PUT http://localhost:8080/users/$user_id \
        -H "Content-Type: application/json" \
        -d '{"email":"updated@example.com"}'
    
    # 6. Verify email updated in database
    local db_email
    db_email=$(sqlite3 data/test.db "SELECT email FROM users WHERE id=$user_id")
    assert "updated@example.com" "$db_email" "Email should be updated in database"
    
    # 7. Delete user and verify cascade delete of posts
    curl -s -X DELETE http://localhost:8080/users/$user_id
    
    local user_exists
    user_exists=$(sqlite3 data/test.db "SELECT COUNT(*) FROM users WHERE id=$user_id")
    assert "0" "$user_exists" "User should be deleted"
    
    local posts_exist
    posts_exist=$(sqlite3 data/test.db "SELECT COUNT(*) FROM posts WHERE user_id=$user_id")
    assert "0" "$posts_exist" "Posts should be deleted"
}

# -----------------------------------------------------------------------------
# Load Testing Functions
# Functions to perform load and stress testing
# -----------------------------------------------------------------------------

test_api_load() {
    echo -e "\n=== Running Load Tests ==="
    
    # Test parameters
    local num_requests=100
    local concurrent=10
    
    # Run Apache Bench if available
    if command -v ab &>/dev/null; then
        echo "Running $num_requests requests with $concurrent concurrent users..."
        ab -n "$num_requests" -c "$concurrent" http://localhost:8080/health
    else
        echo "Apache Bench (ab) not found. Skipping load test."
    fi
}

# -----------------------------------------------------------------------------
# Test Runner
# Function to run all integration tests
# -----------------------------------------------------------------------------

run_integration_tests() {
    echo "Starting integration tests..."
    
    # Start required services
    start_api_server
    start_test_db
    
    # Run API tests
    test_api_health
    test_api_users
    
    # Run database tests
    test_db_users
    test_db_posts
    
    # Run system integration tests
    test_user_workflow
    
    # Run load tests
    test_api_load
    
    # Stop services
    stop_api_server
    stop_test_db
    
    # Print summary
    echo -e "\n"
    print_test_summary
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    echo "Starting integration testing demonstration..."
    
    # Run all integration tests
    run_integration_tests
    
    echo -e "\nIntegration testing demonstration completed."
}

# Run main function if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi
