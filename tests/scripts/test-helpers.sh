#!/usr/bin/env bash

# Test helper functions for GitHub Actions testing

# Setup test environment variables
setup_github_env() {
    export GITHUB_ACTIONS=true
    export GITHUB_WORKFLOW="test"
    export GITHUB_RUN_ID="test-run-$(date +%s)"
    export GITHUB_RUN_NUMBER="1"
    export GITHUB_SHA="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "test-sha-$(date +%s)")}"
    export GITHUB_REF="refs/heads/test"
    export GITHUB_REPOSITORY="codfish/actions"
    export GITHUB_ACTOR="test-user"
    export GITHUB_EVENT_NAME="pull_request"
    export GITHUB_EVENT_PATH="/tmp/github-event.json"
    
    # Create mock event file
    cat > "$GITHUB_EVENT_PATH" <<EOF
{
  "number": 123,
  "pull_request": {
    "number": 123,
    "head": {
      "sha": "$GITHUB_SHA"
    }
  }
}
EOF
}

# Create temporary test directory
create_test_repo() {
    local test_dir="$1"
    local package_json_fixture="${2:-valid}"
    
    mkdir -p "$test_dir"
    cp "tests/fixtures/package-json/${package_json_fixture}.json" "$test_dir/package.json"
    
    # Initialize git repo if needed
    if [ ! -d "$test_dir/.git" ]; then
        cd "$test_dir"
        git init
        git config user.name "Test User"
        git config user.email "test@example.com"
        git add .
        git commit -m "Initial commit"
        cd - >/dev/null
    fi
    
    echo "$test_dir"
}

# Mock npm publish command
mock_npm_publish() {
    cat > /tmp/mock-npm <<'EOF'
#!/usr/bin/env bash
echo "Mock npm publish called with args: $*"
echo "npm notice"
echo "npm notice 📦  test-package@0.0.0-PR-123--abc1234"
echo "npm notice === Published Successfully ==="
exit 0
EOF
    chmod +x /tmp/mock-npm
    export PATH="/tmp:$PATH"
}

# Cleanup test environment
cleanup_test_env() {
    local test_dir="$1"
    if [ -n "$test_dir" ] && [ -d "$test_dir" ]; then
        rm -rf "$test_dir"
    fi
    rm -f /tmp/mock-npm /tmp/github-event.json
}

# Check if action output contains expected value
assert_output_contains() {
    local expected="$1"
    local actual="$2"
    
    if [[ "$actual" == *"$expected"* ]]; then
        return 0
    else
        echo "Expected output to contain: $expected"
        echo "Actual output: $actual"
        return 1
    fi
}

# Check if file exists
assert_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        return 0
    else
        echo "Expected file to exist: $file"
        return 1
    fi
}

# Check if environment variable is set
assert_env_set() {
    local var_name="$1"
    local var_value="${!var_name}"

    if [ -n "$var_value" ]; then
        return 0
    else
        echo "Expected environment variable to be set: $var_name"
        return 1
    fi
}

# Check if action output does NOT contain expected value
refute_output_contains() {
    local unexpected="$1"
    local actual="$2"

    if [[ "$actual" != *"$unexpected"* ]]; then
        return 0
    else
        echo "Expected output NOT to contain: $unexpected"
        echo "Actual output: $actual"
        return 1
    fi
}