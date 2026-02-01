# codfish/actions

A collection of reusable GitHub Actions for common development workflows. Each action is self-contained and designed for
maximum reusability across different projects.

<!-- prettier-ignore-start -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Usage](#usage)
- [Available Actions](#available-actions)
  - [comment](#comment)
  - [npm-pr-version](#npm-pr-version)
  - [setup-node-and-install](#setup-node-and-install)
- [Contributing](#contributing)
- [Example Workflow](#example-workflow)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
<!-- prettier-ignore-end -->

## Usage

Reference actions using the following format:

```yaml
uses: codfish/actions/{action-name}@main
uses: codfish/actions/{action-name}@v3
uses: codfish/actions/{action-name}@v3.0.1
uses: codfish/actions/{action-name}@feature-branch
uses: codfish/actions/{action-name}@aff1a9d
```

## Available Actions

<!-- start action docs -->

### [comment](./comment/)

Creates or updates a comment in a pull request with optional tagging for upsert functionality

**Inputs:**

| Input     | Description                                                                           | Required | Default |
| --------- | ------------------------------------------------------------------------------------- | -------- | ------- |
| `message` | The comment message content (supports markdown formatting)                            | Yes      | -       |
| `tag`     | Unique identifier to find and update existing comments (required when upsert is true) | No       | -       |
| `upsert`  | Update existing comment with matching tag instead of creating new comment             | No       | `false` |

**Usage:**

```yaml
- name: Comment on PR
  uses: codfish/actions/comment@v3
  with:
    message: '✅ Build successful!'
    tag: 'build-status'
    upsert: true
```

### [npm-pr-version](./npm-publish-pr/)

Publishes package with PR-specific version (0.0.0-PR-123--abc1234) using detected package manager (npm/yarn/pnpm) or
OIDC trusted publishing, and automatically comments on PR

**Inputs:**

| Input         | Description                                                                                                    | Required | Default          |
| ------------- | -------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `npm-token`   | Registry authentication token with publish permissions. If not provided, OIDC trusted publishing will be used. | No       | -                |
| `comment`     | Whether to comment on the PR with the published version (true/false)                                           | No       | `true`           |
| `comment-tag` | Tag to use for PR comments (for comment identification and updates)                                            | No       | `npm-publish-pr` |

**Outputs:**

| Output          | Description                                                           |
| --------------- | --------------------------------------------------------------------- |
| `version`       | Generated PR-specific version number (0.0.0-PR-{number}--{short-sha}) |
| `package-name`  | Package name from package.json                                        |
| `error-message` | Error message if publish fails                                        |

**Usage:**

```yaml
permissions:
  id-token: write
  pull-requests: write

steps:
  - uses: actions/checkout@v6

  - uses: codfish/actions/setup-node-and-install@v3

  - run: npm run build

  - uses: codfish/actions/npm-pr-version@v3
```

### [setup-node-and-install](./setup-node-and-install/)

Sets up Node.js environment and installs dependencies with automatic package manager detection (npm/pnpm/yarn),
intelligent caching, and version detection via input, .node-version, .nvmrc, or package.json volta.node

**Inputs:**

| Input               | Description                                                                                                                                                                                    | Required | Default |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| `node-version`      | Node.js version to install (e.g. "24", "lts/\*"). Precedence: node-version input > .node-version > .nvmrc > package.json volta.node.                                                           | No       | -       |
| `install-options`   | Extra command-line options to pass to npm/pnpm/yarn install.                                                                                                                                   | No       | -       |
| `working-directory` | Directory containing package.json and lockfile.                                                                                                                                                | No       | `.`     |
| `upgrade-npm`       | Whether to upgrade npm to v11.5.1. This is required for OIDC trusted publishing but can be disabled if you want to shave off some run time and you are still using token-based authentication. | No       | `true`  |

**Outputs:**

| Output          | Description                                        |
| --------------- | -------------------------------------------------- |
| `node-version`  | The installed node version.                        |
| `cache-hit`     | Whether the dependency cache was hit (true/false). |
| `pnpm-dest`     | Expanded path of pnpm dest.                        |
| `pnpm-bin-dest` | Location of pnpm and pnpx command.                 |

**Usage:**

```yaml
steps:
  - uses: actions/checkout@v6

  # Will setup node, inferring node version from your codebase & installing your dependencies
  - uses: codfish/actions/setup-node-and-install@v3

  # Or if you want to be explicit
  - uses: codfish/actions/setup-node-and-install@v3
    with:
      node-version: 24.4

  - run: npm test
```

<!-- end action docs -->

## Contributing

Each action follows these conventions:

- **Directory structure**: Actions are in kebab-case directories at the repository root
- **Required files**: `action.yml`, `README.md`
- **Composite actions**: All actions use `composite` type for simplicity and transparency
- **Documentation**: Each action includes comprehensive usage examples and input/output documentation

## Example Workflow

Complete workflow using multiple actions together with OIDC trusted publishing:

```yaml
name: Validate

on: pull_request_target

permissions:
  id-token: write # For npm trusted publishing to work
  pull-requests: write # For commenting on PR's

jobs:
  test-and-publish:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v6

      - uses: codfish/actions/setup-node-and-install@v3

      - name: Run tests
        id: test
        run: |
          pnpm test 2>&1 | tee test-output.txt
          if grep -q "All tests passed" test-output.txt; then
            echo "status=✅ passed" >> $GITHUB_OUTPUT
          else
            echo "status=❌ failed" >> $GITHUB_OUTPUT
          fi
          echo "count=$(grep -c "✓\|√\|PASS" test-output.txt || echo "unknown")" >> $GITHUB_OUTPUT

      - name: Build package
        run: pnpm build

      - name: Calculate build size
        run: |
          if [ -d "dist" ]; then
            size=$(du -sh dist | cut -f1)
          elif [ -d "build" ]; then
            size=$(du -sh build | cut -f1)
          elif [ -f "package.json" ]; then
            size=$(du -sh . --exclude=node_modules | cut -f1)
          else
            size="unknown"
          fi
          echo "size=$size" >> $GITHUB_OUTPUT
        id: build

      - uses: codfish/actions/comment@v3
        with:
          message: |
            ## 🚀 **Build Summary**

            **Tests**: ${{ steps.test.outputs.status }} (${{ steps.test.outputs.count }} tests)
            **Build**: ✅ completed successfully
            **Size**: ${{ steps.build.outputs.size }}

            Ready for testing! 🎉
          tag: 'build-summary'
          upsert: true

      - uses: codfish/actions/npm-pr-version@v3
        with:
          comment-tag: 'pr-package'
```
