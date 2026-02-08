# codfish/actions

A collection of reusable GitHub Actions for common development workflows. Each action is self-contained and designed for
maximum reusability across different projects.

<!-- eslint-disable -->
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
- [Maintenance](#maintenance)
  - [Test pull requests in downstream apps before merging](#test-pull-requests-in-downstream-apps-before-merging)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
<!-- eslint-enable -->

## Usage

Reference actions using the following format:

```yml
uses: codfish/actions/{action-name}@main
uses: codfish/actions/{action-name}@v3
uses: codfish/actions/{action-name}@v3.0.1
uses: codfish/actions/{action-name}@feature-branch
uses: codfish/actions/{action-name}@9f7cf1a3ff9f2838eff5ec9ac69b6ff277610bb2
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

```yml
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

| Input         | Description                                                                                                                                                                                                                        | Required | Default          |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `npm-token`   | Registry authentication token with publish permissions. If not provided, OIDC trusted publishing will be used.                                                                                                                     | No       | -                |
| `tarball`     | Path to pre-built tarball to publish (e.g., '\*.tgz'). When provided, publishes the tarball with --ignore-scripts for security. Recommended for pull_request_target workflows to prevent execution of malicious lifecycle scripts. | No       | -                |
| `comment`     | Whether to comment on the PR with the published version (true/false)                                                                                                                                                               | No       | `true`           |
| `comment-tag` | Tag to use for PR comments (for comment identification and updates)                                                                                                                                                                | No       | `npm-publish-pr` |

**Outputs:**

| Output          | Description                                                           |
| --------------- | --------------------------------------------------------------------- |
| `version`       | Generated PR-specific version number (0.0.0-PR-{number}--{short-sha}) |
| `package-name`  | Package name from package.json                                        |
| `error-message` | Error message if publish fails                                        |

**Usage:**

```yml
on: pull_request

jobs:
  publish:
    permissions:
      id-token: write
      pull-requests: write

    steps:
      - uses: actions/checkout@v6

      - uses: codfish/actions/setup-node-and-install@v3
        with:
          node-version: lts/*

      - run: npm run build

      - uses: codfish/actions/npm-pr-version@v3
```

### [setup-node-and-install](./setup-node-and-install/)

Sets up Node.js environment and installs dependencies with automatic package manager detection (npm/pnpm/yarn),
intelligent caching, and version detection via input, .node-version, .nvmrc, or package.json volta.node

**Inputs:**

| Input               | Description                                                                                                                                                                                                                                                                                                     | Required | Default |
| ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| `node-version`      | Node.js version to install (e.g. "24", "lts/\*"). Precedence: node-version input > .node-version > .nvmrc > package.json volta.node.                                                                                                                                                                            | No       | -       |
| `install-options`   | Extra command-line options to pass to npm/pnpm/yarn install.                                                                                                                                                                                                                                                    | No       | -       |
| `working-directory` | Directory containing package.json and lockfile.                                                                                                                                                                                                                                                                 | No       | `.`     |
| `registry-url`      | Optional registry URL to configure for publishing (e.g. "https://registry.npmjs.org/"). Creates .npmrc with NODE_AUTH_TOKEN placeholder. NOT recommended if using semantic-release (it handles auth independently). Only needed for publishing with manual npm publish or other non-semantic-release workflows. | No       | -       |
| `upgrade-npm`       | Whether to upgrade npm to v11.5.1. This is required for OIDC trusted publishing but can be disabled if you want to shave off some run time and you are still using token-based authentication.                                                                                                                  | No       | `true`  |

**Outputs:**

| Output          | Description                                        |
| --------------- | -------------------------------------------------- |
| `node-version`  | The installed node version.                        |
| `cache-hit`     | Whether the dependency cache was hit (true/false). |
| `pnpm-dest`     | Expanded path of pnpm dest.                        |
| `pnpm-bin-dest` | Location of pnpm and pnpx command.                 |

**Usage:**

```yml
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

Complete workflow using multiple actions together with secure OIDC trusted publishing:

```yml
name: Validate

on: pull_request_target

jobs:
  # Build and test with untrusted PR code (no secrets)
  build-and-test:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      pull-requests: write

    steps:
      - uses: actions/checkout@v6
        with:
          ref: ${{ github.event.pull_request.head.sha }}

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
        id: build
        run: |
          pnpm build

          if [ -d "dist" ]; then
            size=$(du -sh dist | cut -f1)
          elif [ -d "build" ]; then
            size=$(du -sh build | cut -f1)
          else
            size="unknown"
          fi
          echo "size=$size" >> $GITHUB_OUTPUT

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

      - name: Create package tarball
        run: pnpm pack

      - uses: actions/upload-artifact@v4
        with:
          name: package-tarball
          path: '*.tgz'
          retention-days: 1

  # Publish with secrets using only trusted base branch code
  publish:
    needs: build-and-test

    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write
      pull-requests: write

    steps:
      - uses: actions/checkout@v6
        # No ref = uses base branch (trusted code only)

      - uses: codfish/actions/setup-node-and-install@v3

      - uses: actions/download-artifact@v4
        with:
          name: package-tarball

      - uses: codfish/actions/npm-pr-version@v3
        with:
          tarball: '*.tgz' # Secure: uses --ignore-scripts
          comment-tag: 'pr-package'
```

## Maintenance

> The release workflow automatically updates the major version tag (v3, v4, v5, etc.) to point to the latest release for
> that major version. This allows users binding to the major version tag to automatically receive the most recent stable
> minor/patch releases.

This happens automatically in the [release workflow](.github/workflows/release.yml) after each successful release.

If you need to update the major version tag manually:

```sh
git tag -fa v5 -m "Update v5 tag" && git push origin v5 --force
```

**Reference**: https://github.com/actions/toolkit/blob/main/docs/action-versioning.md#recommendations

### Test pull requests in downstream apps before merging

Our validation workflow builds and publishes a multi-arch Docker image to GitHub Container Registry for every pull
request, tagging the image with the PR's branch name. You can point downstream repositories at this branch-tagged image
to try changes before merging.

```yml
- uses: codfish/actions:<branch-name>
```
