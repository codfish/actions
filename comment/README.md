# comment

Creates or updates pull request comments with intelligent upsert functionality using unique tags.

<!-- DOCTOC SKIP -->

## Usage

See [action.yml](action.yml).

```yaml
- name: Comment on PR
  uses: codfish/actions/comment@main
  with:
    message: '✅ Build successful!'
    tag: 'build-status'
    upsert: true
```

## Inputs

<!-- start inputs -->

| Input     | Description                                                                           | Required | Default |
| --------- | ------------------------------------------------------------------------------------- | -------- | ------- |
| `message` | The comment message content (supports markdown formatting)                            | Yes      | -       |
| `tag`     | Unique identifier to find and update existing comments (required when upsert is true) | No       | -       |
| `upsert`  | Update existing comment with matching tag instead of creating new comment             | No       | `false` |

<!-- end inputs -->

## Examples

### Basic comment

```yaml
- uses: codfish/actions/comment@main
  with:
    message: 'Hello from GitHub Actions! 👋'
```

### Updating comments with upsert

Use the `upsert` feature to update the same comment instead of creating multiple comments:

```yaml
- name: Update build status
  uses: codfish/actions/comment@main
  with:
    message: |
      ## Build Status
      ⏳ Build in progress...
    tag: 'build-status'
    upsert: true

# Later in the workflow...
- name: Update build status
  uses: codfish/actions/comment@main
  with:
    message: |
      ## Build Status
      ✅ Build completed successfully!
    tag: 'build-status'
    upsert: true
```

### Multi-line markdown comment

```yaml
- uses: codfish/actions/comment@main
  with:
    message: |
      ## 📊 Test Results

      - ✅ Unit tests: 42 passed
      - ✅ Integration tests: 12 passed
      - 📦 Coverage: 98%

      Great work! 🎉
    tag: 'test-results'
    upsert: true
```
