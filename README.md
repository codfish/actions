# codfish/actions

A collection of reusable GitHub Actions for common development workflows. Each action is self-contained and designed for
maximum reusability across different projects.

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

## Usage

Reference actions using the following format:

```yaml
uses: codfish/actions/{action-name}@main
```

For specific versions or branches:

```yaml
uses: codfish/actions/{action-name}@v1.0.0
uses: codfish/actions/{action-name}@feature-branch
```

## Available Actions

<!-- start action docs -->
### [comment](./comment/)

Creates or updates a comment in a pull request with optional tagging for upsert functionality

**Inputs:**

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `message` | The comment message content (supports markdown formatting) | Yes | - |
| `tag` | Unique identifier to find and update existing comments (required when upsert is true) | No | - |
| `upsert` | Update existing comment with matching tag instead of creating new comment | No | `false`  |

**Usage:**

```yaml
- name: Comment on PR
  uses: codfish/actions/comment@main
  with:
    message: '✅ Build successful!'
    tag: 'build-status'
    upsert: true
```

### [npm-pr-version](./npm-publish-pr/)

Publishes package with PR-specific version (0.0.0-PR-123--abc1234) using detected package manager (npm/yarn/pnpm) and automatically comments on PR

**Inputs:**

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `npm-token` | Registry authentication token with publish permissions (works with npm/yarn/pnpm) | No | - |
| `github-token` | GitHub token with pull request comment permissions (typically secrets.GITHUB_TOKEN) | Yes | - |

**Outputs:**

| Output | Description |
|--------|-------------|
| `version` | Generated PR-specific version number (0.0.0-PR-{number}--{short-sha}) |

**Usage:**

```yaml
steps:
  - uses: actions/checkout@v5

  - uses: codfish/actions/setup-node-and-install@main
    with:
      node-version: lts/*

  - run: npm run build

  - uses: codfish/actions/npm-pr-version@main
    with:
      npm-token: ${{ secrets.NPM_TOKEN }}
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

### [setup-node-and-install](./setup-node-and-install/)

Sets up Node.js environment and installs dependencies with automatic package manager detection (npm/pnpm/yarn), intelligent caching, and .nvmrc/.node-version support

**Inputs:**

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `node-version` | Node.js version to install (e.g. '24', 'lts/*'). Defaults to .nvmrc or .node-version file if present | No | - |
| `cache-key-suffix` | Additional suffix for cache key to enable multiple caches per workflow | No | - |
| `install-options` | Extra command-line options to pass to npm/pnpm/yarn install | No | - |
| `working-directory` | Directory containing package.json and lockfile | No | `.`  |

**Usage:**

```yaml
steps:
  - uses: actions/checkout@v5

  # will install latest Node v18.x
  - uses: codfish/actions/setup-node-and-install@main
    with:
      node-version: 18
      cache-key-suffix: '-${{ github.head_ref || github.event.release.tag_name }}'

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

Complete workflow using multiple actions together:

```yaml
name: CI/CD Pipeline
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  test-and-publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: codfish/actions/setup-node-and-install@main
        with:
          node-version: 'lts/*'

      - name: Run tests
        run: npm test

      - name: Build package
        run: npm run build

      - uses: codfish/actions/comment@main
        with:
          message: '⏳ Publishing PR version...'
          tag: 'pr-publish-status'
          upsert: true

      - uses: codfish/actions/npm-pr-version@main
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
        id: publish

      - uses: codfish/actions/comment@main
        with:
          message: |
            ✅ **PR package published successfully!**

            Install with: `npm install my-package@${{ steps.publish.outputs.version }}`
          tag: 'pr-publish-status'
          upsert: true
```
