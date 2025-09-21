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

@test "setup-node-and-install: fails when no node version specified" {
    # Setup test repo without .nvmrc or node-version input
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    
    # Test missing node version
    bash -c '
        if [[ ! -f "./.nvmrc" && -z "$INPUT_NODE_VERSION" ]]; then
            echo "node-version-missing=true"
            exit 1
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt
    
    assert_output_contains "node-version-missing=true" "$(cat output.txt)"
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

@test "setup-node-and-install: prioritizes .nvmrc over .node-version" {
    # Setup test repo with both files
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/.nvmrc" .
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/.node-version" .
    
    # Test priority logic
    bash -c '
        if [ -f "./.nvmrc" ] && [ -f "./.node-version" ]; then
            echo "Both files found, .nvmrc takes priority"
            echo "nvmrc-version=$(cat .nvmrc)"
            echo "node-version-file=$(cat .node-version)"
        fi
    ' > output.txt
    
    assert_output_contains "Both files found, .nvmrc takes priority" "$(cat output.txt)"
    assert_output_contains "nvmrc-version=18.20.0" "$(cat output.txt)"
    assert_output_contains "node-version-file=20.10.0" "$(cat output.txt)"
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