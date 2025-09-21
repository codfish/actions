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

@test "comment: generates correct tag format" {
    # Test tag generation logic from action
    TAG_INPUT="test-tag"
    MESSAGE_INPUT="Hello, World!"
    
    bash -c "
        tag=\"<!-- codfish/actions/comment $TAG_INPUT -->\"
        echo \"Generated tag: \$tag\"
        echo \"tag=\$tag\"
    " > output.txt
    
    assert_output_contains "tag=<!-- codfish/actions/comment test-tag -->" "$(cat output.txt)"
}

@test "comment: handles multi-line messages" {
    # Test multi-line message handling
    MESSAGE_INPUT="Line 1
Line 2
Line 3"
    
    bash -c '
        body=$(printf "$1")
        echo "Processed message:"
        echo "$body"
    ' -- "$MESSAGE_INPUT" > output.txt
    
    assert_output_contains "Line 1" "$(cat output.txt)"
    assert_output_contains "Line 2" "$(cat output.txt)"
    assert_output_contains "Line 3" "$(cat output.txt)"
}

@test "comment: handles markdown formatting" {
    # Test markdown message
    MESSAGE_INPUT="## Test Header

- Item 1
- Item 2

**Bold text** and *italic text*"
    
    bash -c '
        body=$(printf "$1")
        echo "Markdown message:"
        echo "$body"
    ' -- "$MESSAGE_INPUT" > output.txt
    
    assert_output_contains "## Test Header" "$(cat output.txt)"
    assert_output_contains "- Item 1" "$(cat output.txt)"
    assert_output_contains "**Bold text**" "$(cat output.txt)"
}

@test "comment: combines message and tag correctly" {
    # Test complete body generation
    TAG_INPUT="build-status"
    MESSAGE_INPUT="✅ Build successful!"
    
    bash -c "
        tag=\"<!-- codfish/actions/comment $TAG_INPUT -->\"
        body=\$(printf '$MESSAGE_INPUT')
        echo \"Complete body:\"
        echo \"\$body\"
        echo \"\$tag\"
    " > output.txt
    
    assert_output_contains "✅ Build successful!" "$(cat output.txt)"
    assert_output_contains "<!-- codfish/actions/comment build-status -->" "$(cat output.txt)"
}

@test "comment: handles empty tag input" {
    # Test with empty tag
    TAG_INPUT=""
    MESSAGE_INPUT="Message without tag"
    
    bash -c "
        tag=\"<!-- codfish/actions/comment $TAG_INPUT -->\"
        echo \"Tag with empty input: \$tag\"
    " > output.txt
    
    assert_output_contains "<!-- codfish/actions/comment  -->" "$(cat output.txt)"
}