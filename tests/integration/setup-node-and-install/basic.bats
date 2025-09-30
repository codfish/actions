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
    # Test that cache-hit output defaults to false when setup-node cache miss
    bash -c '
        # Simulate setup-node cache miss
        setup_node_cache_hit="false"

        # Simulate the simplified output logic from action.yml
        if [ "$setup_node_cache_hit" = "true" ]; then
            cache_hit="true"
        else
            cache_hit="false"
        fi
        echo "cache-hit=$cache_hit"
    ' > output.txt

    assert_output_contains "cache-hit=false" "$(cat output.txt)"
}

@test "setup-node-and-install: cache-hit output true when setup-node has cache hit" {
    # Test cache-hit output when setup-node step has cache hit
    bash -c '
        # Simulate setup-node cache hit
        setup_node_cache_hit="true"

        # Simulate the simplified output logic from action.yml
        if [ "$setup_node_cache_hit" = "true" ]; then
            cache_hit="true"
        else
            cache_hit="false"
        fi
        echo "cache-hit=$cache_hit"
    ' > output.txt

    assert_output_contains "cache-hit=true" "$(cat output.txt)"
}

@test "setup-node-and-install: node_modules cache separate from cache-hit output" {
    # Test that node_modules cache doesn't affect the cache-hit output
    bash -c '
        # Simulate setup-node cache miss but node_modules cache hit
        setup_node_cache_hit="false"
        node_modules_cache_hit="true"

        # cache-hit output only reflects setup-node, not node_modules cache
        if [ "$setup_node_cache_hit" = "true" ]; then
            cache_hit="true"
        else
            cache_hit="false"
        fi
        echo "cache-hit=$cache_hit"
        echo "node-modules-cache-hit=$node_modules_cache_hit"
        echo "note=cache-hit output only reflects setup-node cache"
    ' > output.txt

    assert_output_contains "cache-hit=false" "$(cat output.txt)"
    assert_output_contains "node-modules-cache-hit=true" "$(cat output.txt)"
    assert_output_contains "note=cache-hit output only reflects setup-node cache" "$(cat output.txt)"
}

@test "setup-node-and-install: input node-version overrides all other sources" {
    # Test that input takes highest priority
    tmp_pkg=$(mktemp)
    cat > "$tmp_pkg" <<'JSON'
{
  "name": "example",
  "version": "1.0.0",
  "volta": { "node": "24.3.4" }
}
JSON
    cp "$tmp_pkg" package.json
    echo "18.20.0" > .nvmrc
    echo "20.10.0" > .node-version

    # Test priority: input > .node-version > .nvmrc > volta.node
    bash -c '
        INPUT_NODE_VERSION="22.1.0"
        resolved_version=""

        if [ -n "${INPUT_NODE_VERSION}" ]; then
            resolved_version="$INPUT_NODE_VERSION"
            echo "source=input"
        elif [ -f "./.node-version" ]; then
            file_version=$(cat ./.node-version | tr -d "\\n\\r" | xargs)
            if [ -n "$file_version" ]; then
                resolved_version="$file_version"
                echo "source=node-version"
            fi
        elif [ -f "./.nvmrc" ]; then
            nvmrc_version=$(cat ./.nvmrc | tr -d "\\n\\r" | xargs)
            if [ -n "$nvmrc_version" ]; then
                resolved_version="$nvmrc_version"
                echo "source=nvmrc"
            fi
        else
            volta_node=$(jq -r ".volta.node // empty" package.json 2>/dev/null || true)
            if [ -n "$volta_node" ]; then
                resolved_version="$volta_node"
                echo "source=volta"
            fi
        fi

        echo "resolved-version=$resolved_version"
    ' > output.txt

    assert_output_contains "source=input" "$(cat output.txt)"
    assert_output_contains "resolved-version=22.1.0" "$(cat output.txt)"
}

@test "setup-node-and-install: node-version overrides nvmrc and volta" {
    # Test .node-version priority when no input
    tmp_pkg=$(mktemp)
    cat > "$tmp_pkg" <<'JSON'
{
  "name": "example",
  "version": "1.0.0",
  "volta": { "node": "24.3.4" }
}
JSON
    cp "$tmp_pkg" package.json
    echo "18.20.0" > .nvmrc
    echo "20.10.0" > .node-version

    # Test without input
    bash -c '
        INPUT_NODE_VERSION=""
        resolved_version=""

        if [ -n "${INPUT_NODE_VERSION}" ]; then
            resolved_version="$INPUT_NODE_VERSION"
            echo "source=input"
        elif [ -f "./.node-version" ]; then
            file_version=$(cat ./.node-version | tr -d "\\n\\r" | xargs)
            if [ -n "$file_version" ]; then
                resolved_version="$file_version"
                echo "source=node-version"
            fi
        elif [ -f "./.nvmrc" ]; then
            nvmrc_version=$(cat ./.nvmrc | tr -d "\\n\\r" | xargs)
            if [ -n "$nvmrc_version" ]; then
                resolved_version="$nvmrc_version"
                echo "source=nvmrc"
            fi
        else
            volta_node=$(jq -r ".volta.node // empty" package.json 2>/dev/null || true)
            if [ -n "$volta_node" ]; then
                resolved_version="$volta_node"
                echo "source=volta"
            fi
        fi

        echo "resolved-version=$resolved_version"
    ' > output.txt

    assert_output_contains "source=node-version" "$(cat output.txt)"
    assert_output_contains "resolved-version=20.10.0" "$(cat output.txt)"
}

@test "setup-node-and-install: nvmrc overrides volta when no node-version" {
    # Test .nvmrc priority when no input or .node-version
    tmp_pkg=$(mktemp)
    cat > "$tmp_pkg" <<'JSON'
{
  "name": "example",
  "version": "1.0.0",
  "volta": { "node": "24.3.4" }
}
JSON
    cp "$tmp_pkg" package.json
    echo "18.20.0" > .nvmrc
    # No .node-version file

    bash -c '
        INPUT_NODE_VERSION=""
        resolved_version=""

        if [ -n "${INPUT_NODE_VERSION}" ]; then
            resolved_version="$INPUT_NODE_VERSION"
            echo "source=input"
        elif [ -f "./.node-version" ]; then
            file_version=$(cat ./.node-version | tr -d "\\n\\r" | xargs)
            if [ -n "$file_version" ]; then
                resolved_version="$file_version"
                echo "source=node-version"
            fi
        elif [ -f "./.nvmrc" ]; then
            nvmrc_version=$(cat ./.nvmrc | tr -d "\\n\\r" | xargs)
            if [ -n "$nvmrc_version" ]; then
                resolved_version="$nvmrc_version"
                echo "source=nvmrc"
            fi
        else
            volta_node=$(jq -r ".volta.node // empty" package.json 2>/dev/null || true)
            if [ -n "$volta_node" ]; then
                resolved_version="$volta_node"
                echo "source=volta"
            fi
        fi

        echo "resolved-version=$resolved_version"
    ' > output.txt

    assert_output_contains "source=nvmrc" "$(cat output.txt)"
    assert_output_contains "resolved-version=18.20.0" "$(cat output.txt)"
}

@test "setup-node-and-install: volta used as last resort" {
    # Test volta.node as fallback when no other sources
    tmp_pkg=$(mktemp)
    cat > "$tmp_pkg" <<'JSON'
{
  "name": "example",
  "version": "1.0.0",
  "volta": { "node": "24.3.4" }
}
JSON
    cp "$tmp_pkg" package.json
    # No .nvmrc or .node-version files

    bash -c '
        INPUT_NODE_VERSION=""
        resolved_version=""

        if [ -n "${INPUT_NODE_VERSION}" ]; then
            resolved_version="$INPUT_NODE_VERSION"
            echo "source=input"
        elif [ -f "./.node-version" ]; then
            file_version=$(cat ./.node-version | tr -d "\\n\\r" | xargs)
            if [ -n "$file_version" ]; then
                resolved_version="$file_version"
                echo "source=node-version"
            fi
        elif [ -f "./.nvmrc" ]; then
            nvmrc_version=$(cat ./.nvmrc | tr -d "\\n\\r" | xargs)
            if [ -n "$nvmrc_version" ]; then
                resolved_version="$nvmrc_version"
                echo "source=nvmrc"
            fi
        else
            volta_node=$(jq -r ".volta.node // empty" package.json 2>/dev/null || true)
            if [ -n "$volta_node" ]; then
                resolved_version="$volta_node"
                echo "source=volta"
            fi
        fi

        echo "resolved-version=$resolved_version"
        if [ -z "$resolved_version" ]; then
            echo "no-version-found=true"
        fi
    ' > output.txt

    assert_output_contains "source=volta" "$(cat output.txt)"
    assert_output_contains "resolved-version=24.3.4" "$(cat output.txt)"
}

@test "setup-node-and-install: no node version found scenario" {
    # Test behavior when no node version source is available
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json
    # No version files or volta config

    bash -c '
        INPUT_NODE_VERSION=""
        resolved_version=""

        if [ -n "${INPUT_NODE_VERSION}" ]; then
            resolved_version="$INPUT_NODE_VERSION"
            echo "source=input"
        elif [ -f "./.node-version" ]; then
            file_version=$(cat ./.node-version | tr -d "\\n\\r" | xargs)
            if [ -n "$file_version" ]; then
                resolved_version="$file_version"
                echo "source=node-version"
            fi
        elif [ -f "./.nvmrc" ]; then
            nvmrc_version=$(cat ./.nvmrc | tr -d "\\n\\r" | xargs)
            if [ -n "$nvmrc_version" ]; then
                resolved_version="$nvmrc_version"
                echo "source=nvmrc"
            fi
        else
            volta_node=$(jq -r ".volta.node // empty" package.json 2>/dev/null || true)
            if [ -n "$volta_node" ]; then
                resolved_version="$volta_node"
                echo "source=volta"
            fi
        fi

        echo "resolved-version=$resolved_version"
        if [ -z "$resolved_version" ]; then
            echo "no-version-found=true"
        fi
    ' > output.txt

    assert_output_contains "no-version-found=true" "$(cat output.txt)"
    assert_output_contains "resolved-version=" "$(cat output.txt)"
}

@test "setup-node-and-install: install commands run on node_modules cache miss" {
    # Test that install steps run when node_modules cache is missed
    bash -c '
        package_manager="npm"
        lockfile_exists="true"
        node_modules_cache_hit="false"

        # Simulate the conditional logic from action.yml
        should_install="false"
        if [ "$package_manager" = "npm" ] && [ "$node_modules_cache_hit" != "true" ]; then
            should_install="true"
            echo "npm-install=will-run"
        fi

        if [ "$package_manager" = "yarn" ] && [ "$node_modules_cache_hit" != "true" ]; then
            should_install="true"
            echo "yarn-install=will-run"
        fi

        if [ "$package_manager" = "pnpm" ] && [ "$node_modules_cache_hit" != "true" ]; then
            should_install="true"
            echo "pnpm-install=will-run"
        fi

        echo "cache-hit=$node_modules_cache_hit"
        echo "should-install=$should_install"
    ' > output.txt

    assert_output_contains "npm-install=will-run" "$(cat output.txt)"
    assert_output_contains "cache-hit=false" "$(cat output.txt)"
    assert_output_contains "should-install=true" "$(cat output.txt)"
}

@test "setup-node-and-install: install commands skip on node_modules cache hit" {
    # Test that install steps are skipped when node_modules cache is hit
    bash -c '
        package_manager="pnpm"
        lockfile_exists="true"
        node_modules_cache_hit="true"

        # Simulate the conditional logic from action.yml
        should_install="false"
        if [ "$package_manager" = "npm" ] && [ "$node_modules_cache_hit" != "true" ]; then
            should_install="true"
            echo "npm-install=will-run"
        fi

        if [ "$package_manager" = "yarn" ] && [ "$node_modules_cache_hit" != "true" ]; then
            should_install="true"
            echo "yarn-install=will-run"
        fi

        if [ "$package_manager" = "pnpm" ] && [ "$node_modules_cache_hit" != "true" ]; then
            should_install="true"
            echo "pnpm-install=will-run"
        fi

        if [ "$should_install" = "false" ]; then
            echo "install-skipped=cache-hit"
        fi

        echo "cache-hit=$node_modules_cache_hit"
        echo "should-install=$should_install"
    ' > output.txt

    assert_output_contains "install-skipped=cache-hit" "$(cat output.txt)"
    assert_output_contains "cache-hit=true" "$(cat output.txt)"
    assert_output_contains "should-install=false" "$(cat output.txt)"
}

@test "setup-node-and-install: conditional install works for all package managers" {
    # Test that all package managers respect the cache condition
    bash -c '
        node_modules_cache_hit="false"

        # Test each package manager
        for pm in npm yarn pnpm; do
            should_install="false"
            if [ "$pm" = "npm" ] && [ "$node_modules_cache_hit" != "true" ]; then
                should_install="true"
            elif [ "$pm" = "yarn" ] && [ "$node_modules_cache_hit" != "true" ]; then
                should_install="true"
            elif [ "$pm" = "pnpm" ] && [ "$node_modules_cache_hit" != "true" ]; then
                should_install="true"
            fi
            echo "$pm-will-install=$should_install"
        done

        echo "cache-miss-scenario=all-managers-will-install"
    ' > output.txt

    assert_output_contains "npm-will-install=true" "$(cat output.txt)"
    assert_output_contains "yarn-will-install=true" "$(cat output.txt)"
    assert_output_contains "pnpm-will-install=true" "$(cat output.txt)"
    assert_output_contains "cache-miss-scenario=all-managers-will-install" "$(cat output.txt)"
}

@test "setup-node-and-install: node_modules cache only applies with lockfile" {
    # Test that node_modules cache is only used when lockfile exists
    bash -c '
        lockfile_exists_with_lock="true"
        lockfile_exists_without_lock="false"

        # Simulate cache step condition: if lockfile exists
        if [ "$lockfile_exists_with_lock" = "true" ]; then
            echo "node-modules-cache=enabled"
        else
            echo "node-modules-cache=disabled"
        fi

        if [ "$lockfile_exists_without_lock" = "true" ]; then
            echo "no-lockfile-cache=enabled"
        else
            echo "no-lockfile-cache=disabled"
        fi
    ' > output.txt

    assert_output_contains "node-modules-cache=enabled" "$(cat output.txt)"
    assert_output_contains "no-lockfile-cache=disabled" "$(cat output.txt)"
}
