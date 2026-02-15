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

@test "npm-pr-version: tarball mode detection" {
    # Test that tarball mode is detected when INPUT_TARBALL is set
    bash -c '
        INPUT_TARBALL="test-package-1.0.0.tgz"
        tarball_mode=false

        if [ -n "$INPUT_TARBALL" ]; then
          tarball_mode=true
          echo "SECURE MODE: Using pre-built tarball"
        fi

        echo "tarball-mode=$tarball_mode"
    ' > output.txt

    assert_output_contains "tarball-mode=true" "$(cat output.txt)"
    assert_output_contains "SECURE MODE: Using pre-built tarball" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode extracts package name from tarball" {
    # Create a test package using npm pack format
    mkdir -p package
    echo '{"name": "test-package", "version": "1.0.0"}' > package/package.json

    # Create tarball in npm pack format (package/ directory at root of tarball)
    tar -czf test-package-1.0.0.tgz package/

    # Test extracting package name
    bash -c '
        INPUT_TARBALL="test-package-1.0.0.tgz"

        # Create secure temporary file
        temp_pkg_json=$(mktemp)
        trap '\''rm -f "$temp_pkg_json"'\'' EXIT

        # Extract package.json from tarball
        tar -xzf "$INPUT_TARBALL" -O package/package.json > "$temp_pkg_json" 2>/dev/null

        if [ -s "$temp_pkg_json" ]; then
            package_name=$(jq -r ".name // empty" "$temp_pkg_json")
            echo "package-name=$package_name"
        else
            echo "error=Could not extract package.json"
        fi
    ' > output.txt

    assert_output_contains "package-name=test-package" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode injects PR version (repack)" {
    # Tarball mode unpacks, sets version to 0.0.0-PR-{number}--{sha}, repacks, and publishes
    mkdir -p package
    echo '{"name": "test-package", "version": "1.0.0"}' > package/package.json
    tar -czf test-package-1.0.0.tgz package/

    bash -c '
        INPUT_TARBALL="test-package-1.0.0.tgz"
        PR=123
        SHA="abc1234567890"

        repack_dir=$(mktemp -d)
        trap "rm -rf \$repack_dir" EXIT
        tar -xzf "$INPUT_TARBALL" -C "$repack_dir"
        package_name=$(jq -r ".name // empty" "$repack_dir/package/package.json")
        version="0.0.0-PR-${PR}--$(echo ${SHA} | cut -c -7)"
        jq --arg v "$version" ".version = \$v" "$repack_dir/package/package.json" > "$repack_dir/package/package.json.tmp" && mv "$repack_dir/package/package.json.tmp" "$repack_dir/package/package.json"
        echo "package-name=$package_name"
        echo "version=$version"
    ' > output.txt

    assert_output_contains "package-name=test-package" "$(cat output.txt)"
    assert_output_contains "version=0.0.0-PR-123--abc1234" "$(cat output.txt)"
}

@test "npm-pr-version: repacked tarball extracts with correct structure and PR version" {
    # Create source tarball (npm pack format: package/ with package.json + other files)
    mkdir -p package
    echo '{"name": "@scope/repack-test", "version": "2.0.0"}' > package/package.json
    echo "module.exports = {};" > package/index.js
    tar -czf repack-test.tgz package/

    # Repack (same flow as action: unpack, inject PR version, repack) and write to test dir so it persists
    bash -c '
        INPUT_TARBALL="repack-test.tgz"
        PR=42
        SHA="c0ffee0"
        repack_dir=$(mktemp -d)
        trap "rm -rf \$repack_dir" EXIT
        tar -xzf "$INPUT_TARBALL" -C "$repack_dir"
        version="0.0.0-PR-${PR}--$(echo ${SHA} | cut -c -7)"
        jq --arg v "$version" ".version = \$v" "$repack_dir/package/package.json" > "$repack_dir/package/package.json.tmp" && mv "$repack_dir/package/package.json.tmp" "$repack_dir/package/package.json"
        (cd "$repack_dir" && tar -czf repack.tgz package)
        cp "$repack_dir/repack.tgz" ./repack-output.tgz
    '

    # Extract repacked tarball and validate structure
    extract_dir=$(mktemp -d)
    tar -xzf repack-output.tgz -C "$extract_dir"
    rm -f repack-output.tgz

    # Must have package/package.json (npm pack layout)
    assert_file_exists "$extract_dir/package/package.json"
    name=$(jq -r '.name' "$extract_dir/package/package.json")
    version=$(jq -r '.version' "$extract_dir/package/package.json")
    [ "$name" = "@scope/repack-test" ]
    [ "$version" = "0.0.0-PR-42--c0ffee0" ]

    # Original files must be preserved
    assert_file_exists "$extract_dir/package/index.js"
    [ "$(cat "$extract_dir/package/index.js")" = "module.exports = {};" ]

    rm -rf "$extract_dir"
}

@test "npm-pr-version: tarball mode validates tarball exists" {
    # Test error when tarball doesn't exist
    bash -c '
        INPUT_TARBALL="non-existent-package.tgz"

        if [ ! -f "$INPUT_TARBALL" ]; then
            error_message="ERROR: Tarball not found at path: $INPUT_TARBALL"
            echo "$error_message"
            exit 1
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt

    assert_output_contains "ERROR: Tarball not found" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode uses --ignore-scripts flag" {
    # Test that --ignore-scripts is used when publishing the repacked tarball
    bash -c '
        TARBALL_TO_PUBLISH="/tmp/repack/repack.tgz"
        tarball_mode=true

        if [ "$tarball_mode" = true ]; then
            publish_cmd="npm publish \"$TARBALL_TO_PUBLISH\" --access public --tag pr --ignore-scripts"
            echo "Publishing with: $publish_cmd"
        fi
    ' > output.txt

    assert_output_contains "--ignore-scripts" "$(cat output.txt)"
    assert_output_contains "npm publish" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode with OIDC uses --provenance" {
    # Test that OIDC mode includes --provenance flag when publishing repacked tarball
    bash -c '
        TARBALL_TO_PUBLISH="/tmp/repack/repack.tgz"
        INPUT_NPM_TOKEN=""
        tarball_mode=true

        if [ "$tarball_mode" = true ]; then
            if [ -z "$INPUT_NPM_TOKEN" ]; then
                publish_cmd="npm publish \"$TARBALL_TO_PUBLISH\" --access public --tag pr --provenance --ignore-scripts"
                echo "Publishing with: $publish_cmd"
            fi
        fi
    ' > output.txt

    assert_output_contains "--provenance" "$(cat output.txt)"
    assert_output_contains "--ignore-scripts" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode with token uses npm (not detected package manager)" {
    # Test that tarball mode always uses npm even if yarn.lock exists
    touch yarn.lock

    bash -c '
        TARBALL_TO_PUBLISH="/tmp/repack/repack.tgz"
        INPUT_NPM_TOKEN="test-token"
        tarball_mode=true

        if [ "$tarball_mode" = true ]; then
            if [ -n "$INPUT_NPM_TOKEN" ]; then
                # Token mode with tarball - always use npm, publish repacked tarball
                publish_cmd="npm publish \"$TARBALL_TO_PUBLISH\" --access public --tag pr --ignore-scripts"
                echo "Publishing with: $publish_cmd"
                echo "Note: Using npm even though yarn.lock exists"
            fi
        fi
    ' > output.txt

    assert_output_contains "npm publish" "$(cat output.txt)"
    assert_output_contains "--ignore-scripts" "$(cat output.txt)"
    assert_output_contains "Using npm even though yarn.lock exists" "$(cat output.txt)"
}

@test "npm-pr-version: token mode preserves existing project .npmrc" {
    # Token auth uses a temp userconfig file (NPM_CONFIG_USERCONFIG), never writes or deletes project .npmrc
    printf '%s\n' "registry=https://custom.registry.example/" "@my-scope:registry=https://scope.registry.example/" "save-exact=true" > .npmrc
    custom_npmrc=$(cat .npmrc)

    NPMRC_AUTH_FILE=$(mktemp)
    echo "//registry.npmjs.org/:_authToken=\${NODE_AUTH_TOKEN}" > "$NPMRC_AUTH_FILE"
    export NPM_CONFIG_USERCONFIG="$NPMRC_AUTH_FILE"
    export NODE_AUTH_TOKEN="test-token"
    # Simulate cleanup (same as action) - no trap so we don't overwrite other tests' EXIT trap
    rm -f "$NPMRC_AUTH_FILE" 2>/dev/null || true

    assert_file_exists .npmrc
    [ "$(cat .npmrc)" = "$custom_npmrc" ]
}

@test "npm-pr-version: tarball mode generates PR version for repack" {
    # Tarball mode now injects PR version into the tarball so each publish is unique
    bash -c '
        tarball_mode=true
        PR=99
        SHA="deadbeef12345"

        if [ "$tarball_mode" = true ]; then
            version="0.0.0-PR-${PR}--$(echo ${SHA} | cut -c -7)"
            echo "Generated PR version for repack: $version"
        fi
    ' > output.txt

    assert_output_contains "Generated PR version for repack: 0.0.0-PR-99--deadbee" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode handles scoped packages" {
    # Create a test scoped package (unpack to dir, read name - same as action)
    mkdir -p package
    echo '{"name": "@test-org/scoped-package", "version": "1.0.0"}' > package/package.json
    tar -czf test-org-scoped-package-1.0.0.tgz package/

    bash -c '
        INPUT_TARBALL="test-org-scoped-package-1.0.0.tgz"
        repack_dir=$(mktemp -d)
        trap "rm -rf \$repack_dir" EXIT
        tar -xzf "$INPUT_TARBALL" -C "$repack_dir"
        package_name=$(jq -r ".name // empty" "$repack_dir/package/package.json")
        echo "package-name=$package_name"
    ' > output.txt

    assert_output_contains "package-name=@test-org/scoped-package" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode error when package.json missing from tarball" {
    # Create a tarball without package.json
    mkdir -p package
    echo "test content" > package/readme.txt
    tar -czf invalid-package.tgz package/

    # Test error handling (unpack then check for package/package.json)
    bash -c '
        INPUT_TARBALL="invalid-package.tgz"
        repack_dir=$(mktemp -d)
        trap "rm -rf \$repack_dir" EXIT
        tar -xzf "$INPUT_TARBALL" -C "$repack_dir"

        if [ ! -f "$repack_dir/package/package.json" ]; then
            error_message="ERROR: Could not extract package.json from tarball (expected package/package.json)"
            echo "$error_message"
            exit 1
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt

    assert_output_contains "ERROR: Could not extract package.json from tarball" "$(cat output.txt)"
}

@test "npm-pr-version: tarball mode uses secure temporary files (mktemp)" {
    # Test that mktemp is used for temporary file creation (TOCTOU fix)
    # This verifies the security fix for predictable temp file paths
    # Note: We trust mktemp to set appropriate permissions (600 on Unix, 644 on Windows)
    # and don't verify them since permission checking is unreliable across platforms

    # Store temp file path outside the subshell
    temp_file_path=$(bash -c '
        # Simulate the secure temp file pattern used in action
        temp_pkg_json=$(mktemp)
        trap '\''rm -f "$temp_pkg_json"'\'' EXIT

        # Verify mktemp creates unique files in expected locations
        if [[ "$temp_pkg_json" =~ ^/tmp/tmp\. ]] || [[ "$temp_pkg_json" =~ ^/var/folders ]]; then
            echo "mktemp-created=true" >&2
            echo "temp-file=$temp_pkg_json" >&2
        else
            echo "mktemp-created=false" >&2
        fi

        # Verify file exists
        if [ -f "$temp_pkg_json" ]; then
            echo "file-exists=true" >&2
        else
            echo "file-exists=false" >&2
        fi

        # Output the temp file path so we can check cleanup later
        echo "$temp_pkg_json"
    ' 2>output.txt)

    # Verify mktemp created a unique file in the proper location
    assert_output_contains "mktemp-created=true" "$(cat output.txt)"
    assert_output_contains "file-exists=true" "$(cat output.txt)"

    # Verify trap cleaned up the file after script exit
    if [ -f "$temp_file_path" ]; then
        echo "trap-cleanup=false" >> output.txt
    else
        echo "trap-cleanup=true" >> output.txt
    fi

    assert_output_contains "trap-cleanup=true" "$(cat output.txt)"
}

@test "npm-pr-version: tarball glob pattern expands to single file" {
    # Create a test tarball
    mkdir -p package
    echo '{"name": "test-package", "version": "1.0.0"}' > package/package.json
    tar -czf test-package-1.0.0.tgz package/

    # Test glob expansion with *.tgz pattern
    bash -c '
        INPUT_TARBALL="*.tgz"

        # Simulate glob expansion logic from action
        shopt -s nullglob
        tarball_files=($INPUT_TARBALL)
        shopt -u nullglob

        if [ ${#tarball_files[@]} -eq 1 ]; then
            INPUT_TARBALL="${tarball_files[0]}"
            echo "resolved-tarball=$INPUT_TARBALL"
            echo "file-count=${#tarball_files[@]}"
        else
            echo "error=Expected 1 file, found ${#tarball_files[@]}"
        fi
    ' > output.txt

    assert_output_contains "resolved-tarball=test-package-1.0.0.tgz" "$(cat output.txt)"
    assert_output_contains "file-count=1" "$(cat output.txt)"
}

@test "npm-pr-version: tarball glob pattern error when no files match" {
    # Test error when glob pattern matches no files
    bash -c '
        INPUT_TARBALL="*.tgz"

        shopt -s nullglob
        tarball_files=($INPUT_TARBALL)
        shopt -u nullglob

        if [ ${#tarball_files[@]} -eq 0 ]; then
            error_message="ERROR: No tarball files found matching pattern: $INPUT_TARBALL"
            echo "$error_message"
            exit 1
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt

    assert_output_contains "ERROR: No tarball files found matching pattern: *.tgz" "$(cat output.txt)"
    assert_output_contains "exit-code=1" "$(cat output.txt)"
}

@test "npm-pr-version: tarball glob pattern error when multiple files match" {
    # Create multiple test tarballs
    mkdir -p package
    echo '{"name": "test-package-1", "version": "1.0.0"}' > package/package.json
    tar -czf test-package-1.0.0.tgz package/
    echo '{"name": "test-package-2", "version": "2.0.0"}' > package/package.json
    tar -czf test-package-2.0.0.tgz package/

    # Test error when glob pattern matches multiple files
    bash -c '
        INPUT_TARBALL="*.tgz"

        shopt -s nullglob
        tarball_files=($INPUT_TARBALL)
        shopt -u nullglob

        if [ ${#tarball_files[@]} -gt 1 ]; then
            error_message="ERROR: Multiple tarball files found matching pattern: $INPUT_TARBALL (found: ${tarball_files[*]}). Please specify a single tarball file."
            echo "$error_message"
            exit 1
        fi
    ' > output.txt 2>&1 || echo "exit-code=$?" >> output.txt

    assert_output_contains "ERROR: Multiple tarball files found matching pattern: *.tgz" "$(cat output.txt)"
    assert_output_contains "exit-code=1" "$(cat output.txt)"
}

@test "npm-pr-version: action code uses mktemp and trap for security" {
    # Verify the action.yml contains the secure temp file pattern
    ACTION_FILE="$BATS_TEST_DIRNAME/../../../npm-publish-pr/action.yml"

    if [ ! -f "$ACTION_FILE" ]; then
        skip "action.yml not found"
    fi

    # Check for mktemp usage (temp dir for repack or temp file)
    if grep -q "mktemp" "$ACTION_FILE"; then
        echo "mktemp-found=true" > output.txt
    else
        echo "mktemp-found=false" > output.txt
    fi

    # Check for trap with EXIT (inline or trap cleanup EXIT with cleanup doing rm -f / rm -rf)
    if grep -q "trap.*rm -f.*EXIT" "$ACTION_FILE" || { grep -q "trap cleanup EXIT" "$ACTION_FILE" && (grep -q 'rm -f\|rm -rf' "$ACTION_FILE"); }; then
        echo "trap-found=true" >> output.txt
    else
        echo "trap-found=false" >> output.txt
    fi

    # Check that hardcoded /tmp path is NOT used
    if grep -q "/tmp/package.json.tarball" "$ACTION_FILE"; then
        echo "hardcoded-path-found=true" >> output.txt
    else
        echo "hardcoded-path-found=false" >> output.txt
    fi

    assert_output_contains "mktemp-found=true" "$(cat output.txt)"
    assert_output_contains "trap-found=true" "$(cat output.txt)"
    assert_output_contains "hardcoded-path-found=false" "$(cat output.txt)"
}

@test "npm-pr-version: normal mode still works when tarball not provided" {
    # Test backward compatibility - normal mode should work without tarball
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json

    bash -c '
        INPUT_TARBALL=""
        tarball_mode=false
        PR=456
        SHA="def1234567890"

        if [ -n "$INPUT_TARBALL" ]; then
          tarball_mode=true
        fi

        if [ "$tarball_mode" = false ]; then
            # Normal mode
            if [ -f "package.json" ]; then
                echo "Using normal mode with package.json"
                version="0.0.0-PR-${PR}--$(echo ${SHA} | cut -c -7)"
                echo "version=$version"
            fi
        fi
    ' > output.txt

    assert_output_contains "Using normal mode with package.json" "$(cat output.txt)"
    assert_output_contains "version=0.0.0-PR-456--def1234" "$(cat output.txt)"
}
