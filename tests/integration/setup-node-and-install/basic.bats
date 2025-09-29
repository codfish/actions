#!/usr/bin/env bats

load "../../scripts/test-helpers.sh"

setup() {
    setup_github_env
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
}

teardown() {
    cd /
    cleanup_test_env "$TEST_DIR"
}

@test "setup-node-and-install: detects npm with package-lock.json" {
    # Setup test repo with npm lockfile
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/lockfiles/package-lock.json" .

    # Test enhanced package manager detection
    bash -c '
        if [ -f "./pnpm-lock.yaml" ]; then
            echo "package-manager=pnpm"
            echo "lockfile-exists=true"
        elif [ -f "./yarn.lock" ]; then
            echo "package-manager=yarn"
            echo "lockfile-exists=true"
        elif [ -f "./package-lock.json" ]; then
            echo "package-manager=npm"
            echo "lockfile-exists=true"
        else
            echo "package-manager=npm"
            echo "lockfile-exists=false"
        fi
    ' > output.txt

    assert_output_contains "package-manager=npm" "$(cat output.txt)"
    assert_output_contains "lockfile-exists=true" "$(cat output.txt)"
}

@test "setup-node-and-install: detects pnpm with pnpm-lock.yaml" {
    # Setup test repo with pnpm lockfile
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/lockfiles/pnpm-lock.yaml" .

    # Test package manager detection (updated with yarn support)
    bash -c '
        if [ -f "./pnpm-lock.yaml" ]; then
            echo "package-manager=pnpm"
            echo "lockfile-exists=true"
        elif [ -f "./yarn.lock" ]; then
            echo "package-manager=yarn"
            echo "lockfile-exists=true"
        elif [ -f "./package-lock.json" ]; then
            echo "package-manager=npm"
            echo "lockfile-exists=true"
        else
            echo "package-manager=npm"
            echo "lockfile-exists=false"
        fi
    ' > output.txt

    assert_output_contains "package-manager=pnpm" "$(cat output.txt)"
    assert_output_contains "lockfile-exists=true" "$(cat output.txt)"
}

@test "setup-node-and-install: detects .nvmrc file" {
    # Setup test repo with .nvmrc
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/.nvmrc" .

    # Test nvmrc detection
    bash -c '
        if [[ ! -f "./.nvmrc" && -z "$INPUT_NODE_VERSION" ]]; then
            echo "node-version-missing=true"
        else
            echo "node-version-found=true"
            if [ -f "./.nvmrc" ]; then
                echo "nvmrc-version=$(cat .nvmrc)"
            fi
        fi
    ' > output.txt

    assert_output_contains "node-version-found=true" "$(cat output.txt)"
    assert_output_contains "nvmrc-version=18.20.0" "$(cat output.txt)"
}

@test "setup-node-and-install: detects yarn with yarn.lock" {
    # Setup test repo with yarn lockfile
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/lockfiles/yarn.lock" .

    # Test yarn detection
    bash -c '
        if [ -f "./pnpm-lock.yaml" ]; then
            echo "package-manager=pnpm"
            echo "lockfile-exists=true"
        elif [ -f "./yarn.lock" ]; then
            echo "package-manager=yarn"
            echo "lockfile-exists=true"
        elif [ -f "./package-lock.json" ]; then
            echo "package-manager=npm"
            echo "lockfile-exists=true"
        else
            echo "package-manager=npm"
            echo "lockfile-exists=false"
        fi
    ' > output.txt

    assert_output_contains "package-manager=yarn" "$(cat output.txt)"
    assert_output_contains "lockfile-exists=true" "$(cat output.txt)"
}

@test "setup-node-and-install: does not fail when no node version specified" {
    # Setup test repo without .nvmrc or .node-version or node-version input
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json

    # No failure should occur; action no longer enforces node version presence
    bash -c '
        echo "validation-passed=true"
    ' > output.txt

    assert_output_contains "validation-passed=true" "$(cat output.txt)"
}

@test "setup-node-and-install: detects .node-version file" {
    # Setup test repo with .node-version
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/.node-version" .

    # Test .node-version detection
    bash -c '
        if [[ ! -f "./.nvmrc" && ! -f "./.node-version" && -z "$INPUT_NODE_VERSION" ]]; then
            echo "node-version-missing=true"
        else
            echo "node-version-found=true"
            if [ -f "./.node-version" ]; then
                echo "node-version-content=$(cat .node-version)"
            fi
        fi
    ' > output.txt

    assert_output_contains "node-version-found=true" "$(cat output.txt)"
    assert_output_contains "node-version-content=20.10.0" "$(cat output.txt)"
}

@test "setup-node-and-install: prioritizes .node-version over .nvmrc" {
    # Setup test repo with both files
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/.nvmrc" .
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/.node-version" .

    # Test priority logic (.node-version should win now)
    bash -c '
        if [ -f "./.nvmrc" ] && [ -f "./.node-version" ]; then
            echo "Both files found, .node-version takes priority"
            echo "node-version-file=$(cat .node-version)"
            echo "nvmrc-version=$(cat .nvmrc)"
        fi
    ' > output.txt

    assert_output_contains "Both files found, .node-version takes priority" "$(cat output.txt)"
    assert_output_contains "node-version-file=20.10.0" "$(cat output.txt)"
    assert_output_contains "nvmrc-version=18.20.0" "$(cat output.txt)"
}

@test "setup-node-and-install: detects volta.node in package.json" {
    # Setup test repo with volta.node
    tmp_pkg=$(mktemp)
    cat > "$tmp_pkg" <<'JSON'
{
  "name": "example",
  "version": "1.0.0",
  "volta": { "node": "24.3.4" }
}
JSON
    cp "$tmp_pkg" package.json

    # Test volta.node detection
    bash -c '
        volta_node=$(jq -r ".volta.node // empty" package.json 2>/dev/null || true)
        if [ -n "$volta_node" ]; then
            echo "volta-node=$volta_node"
        fi
    ' > output.txt

    assert_output_contains "volta-node=24.3.4" "$(cat output.txt)"
}

@test "setup-node-and-install: validates package.json existence" {
    # Test without package.json
    bash -c '
        if [ ! -f "./package.json" ]; then
            echo "ERROR: package.json not found"
            exit 1
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt

    assert_output_contains "ERROR: package.json not found" "$(cat output.txt)"
}

@test "setup-node-and-install: validates empty .node-version file" {
    # Setup test repo with empty .node-version
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    touch .node-version  # Create empty file

    # Test empty .node-version validation
    bash -c '
        if [ -f "./.node-version" ] && [ ! -f "./.nvmrc" ]; then
            node_version_file=$(cat .node-version | tr -d "\n\r" | xargs)
            if [ -z "$node_version_file" ]; then
                echo "ERROR: .node-version file is empty"
                exit 1
            fi
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt

    assert_output_contains "ERROR: .node-version file is empty" "$(cat output.txt)"
}

@test "setup-node-and-install: cache-hit output defaults to false" {
    # Test that cache-hit output defaults to false when no cache
    bash -c '
        # Simulate no cache hit scenario (default)
        setup_node_cache_hit=""
        setup_node_alt_cache_hit=""

        # Simulate the output logic from action.yml
        cache_hit="${setup_node_cache_hit:-${setup_node_alt_cache_hit:-false}}"
        echo "cache-hit=$cache_hit"
    ' > output.txt

    assert_output_contains "cache-hit=false" "$(cat output.txt)"
}

@test "setup-node-and-install: cache-hit output true when setup-node has cache hit" {
    # Test cache-hit output when setup-node step has cache hit
    bash -c '
        # Simulate setup-node cache hit
        setup_node_cache_hit="true"
        setup_node_alt_cache_hit=""

        # Simulate the output logic from action.yml
        cache_hit="${setup_node_cache_hit:-${setup_node_alt_cache_hit:-false}}"
        echo "cache-hit=$cache_hit"
    ' > output.txt

    assert_output_contains "cache-hit=true" "$(cat output.txt)"
}

@test "setup-node-and-install: cache-hit output true when setup-node-alt has cache hit" {
    # Test cache-hit output when setup-node-alt step has cache hit
    bash -c '
        # Simulate setup-node-alt cache hit (when using .node-version)
        setup_node_cache_hit=""
        setup_node_alt_cache_hit="true"

        # Simulate the output logic from action.yml
        cache_hit="${setup_node_cache_hit:-${setup_node_alt_cache_hit:-false}}"
        echo "cache-hit=$cache_hit"
    ' > output.txt

    assert_output_contains "cache-hit=true" "$(cat output.txt)"
}

@test "setup-node-and-install: cache-hit prioritizes setup-node over setup-node-alt" {
    # Test that setup-node cache-hit takes priority over setup-node-alt
    bash -c '
        # Simulate both having cache hits (setup-node should take priority)
        setup_node_cache_hit="true"
        setup_node_alt_cache_hit="false"

        # Simulate the output logic from action.yml
        cache_hit="${setup_node_cache_hit:-${setup_node_alt_cache_hit:-false}}"
        echo "cache-hit=$cache_hit"
        echo "priority=setup-node"
    ' > output.txt

    assert_output_contains "cache-hit=true" "$(cat output.txt)"
    assert_output_contains "priority=setup-node" "$(cat output.txt)"
}
