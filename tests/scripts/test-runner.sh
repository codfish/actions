#!/usr/bin/env bash
set -euo pipefail

# Test runner script for GitHub Actions
# Usage: ./test-runner.sh [integration|unit|all]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEST_DIR="$PROJECT_ROOT/tests"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

# Check dependencies
check_dependencies() {
    log "Checking dependencies..."
    
    if ! command -v bats >/dev/null 2>&1; then
        error "bats is not installed. Install with: pnpm install"
        exit 1
    fi
    
    if ! command -v act >/dev/null 2>&1; then
        warn "act is not installed. Integration tests will use GitHub Actions API"
        warn "Install act for local testing: brew install act"
    fi
    
    success "Dependencies checked"
}

# Run unit tests
run_unit_tests() {
    log "Running unit tests..."
    
    if [ ! -d "$TEST_DIR/unit" ] || [ -z "$(find "$TEST_DIR/unit" -name "*.bats" 2>/dev/null)" ]; then
        warn "No unit tests found in $TEST_DIR/unit"
        return 0
    fi
    
    bats "$TEST_DIR/unit"/**/*.bats
    success "Unit tests completed"
}

# Run integration tests
run_integration_tests() {
    log "Running integration tests..."
    
    if [ ! -d "$TEST_DIR/integration" ] || [ -z "$(find "$TEST_DIR/integration" -name "*.bats" 2>/dev/null)" ]; then
        warn "No integration tests found in $TEST_DIR/integration"
        return 0
    fi
    
    # Set up test environment
    export GITHUB_ACTIONS=true
    export GITHUB_WORKFLOW="test"
    export GITHUB_RUN_ID="test-run"
    export GITHUB_RUN_NUMBER="1"
    export GITHUB_SHA="$(git rev-parse HEAD 2>/dev/null || echo "test-sha")"
    export GITHUB_REF="refs/heads/test"
    export GITHUB_REPOSITORY="codfish/actions"
    export GITHUB_ACTOR="test-user"
    export GITHUB_EVENT_NAME="push"
    
    bats "$TEST_DIR/integration"/**/*.bats
    success "Integration tests completed"
}

# Main execution
main() {
    cd "$PROJECT_ROOT"
    
    local test_type="${1:-all}"
    
    log "Starting test runner (type: $test_type)"
    log "Project root: $PROJECT_ROOT"
    
    check_dependencies
    
    case "$test_type" in
        "unit")
            run_unit_tests
            ;;
        "integration")
            run_integration_tests
            ;;
        "all"|*)
            run_unit_tests
            run_integration_tests
            ;;
    esac
    
    success "All tests completed successfully!"
}

main "$@"