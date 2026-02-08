# Contributing to codfish/actions

Thank you for your interest in contributing! This document provides guidelines for contributing to this repository.

<!-- eslint-disable -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
  - [1. Create a Branch](#1-create-a-branch)
  - [2. Make Your Changes](#2-make-your-changes)
  - [3. Test Your Changes](#3-test-your-changes)
  - [4. Commit Your Changes](#4-commit-your-changes)
- [Action Development Guidelines](#action-development-guidelines)
  - [Directory Structure](#directory-structure)
  - [Action Naming](#action-naming)
  - [Action Definition (action.yml)](#action-definition-actionyml)
  - [Implementation Guidelines](#implementation-guidelines)
  - [Error Handling](#error-handling)
  - [Package Manager Detection](#package-manager-detection)
- [Testing](#testing)
  - [Test Structure](#test-structure)
  - [Writing Tests](#writing-tests)
  - [Running Tests](#running-tests)
- [Documentation](#documentation)
  - [README Structure](#readme-structure)
  - [Documentation Updates](#documentation-updates)
  - [Auto-Generated Documentation](#auto-generated-documentation)
- [Submitting Changes](#submitting-changes)
  - [Pull Request Process](#pull-request-process)
  - [PR Requirements](#pr-requirements)
  - [Review Process](#review-process)
- [Action Ideas](#action-ideas)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
<!-- eslint-enable -->

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected
to uphold this code.

## Getting Started

1. **Fork the repository** and clone it locally
2. **Install dependencies**: `pnpm install`
3. **Set up your development environment**:
   ```bash
   # Install act for local testing (optional but recommended)
   brew install act  # macOS
   # or
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash  # Linux
   ```

## Development Workflow

### 1. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes

Follow the [Action Development Guidelines](#action-development-guidelines) below.

### 3. Test Your Changes

```bash
# Run all tests
pnpm test

# Run specific test types
pnpm test:integration
pnpm test:unit

# Run linting
pnpm lint
```

### 4. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git commit -m "feat(setup-node): add yarn berry support"
git commit -m "fix(comment): handle empty tag input properly"
git commit -m "docs(npm-pr-version): update README with new examples"
```

## Action Development Guidelines

### Directory Structure

Each action should be in its own directory at the repository root:

```txt
action-name/
├── action.yml          # Action definition
├── README.md          # Action documentation
└── [implementation files]
```

### Action Naming

- Use **kebab-case** for action directory names
- Action names should be descriptive and follow the pattern: `verb-noun` or `noun-verb`
- Examples: `setup-node-and-install`, `npm-pr-version`, `comment`

### Action Definition (action.yml)

```yml
name: action-name
description: Clear, concise description of what the action does

inputs:
  input-name:
    description: Clear description of the input parameter
    required: true|false
    default: 'default-value' # if applicable

outputs:
  output-name:
    description: Clear description of the output
    value: '${{ steps.step-id.outputs.output-name }}'

runs:
  using: composite
  steps:
    # Implementation steps
```

### Implementation Guidelines

1. **Use composite actions** for consistency and transparency
2. **Validate inputs** early with clear error messages
3. **Handle errors gracefully** with actionable feedback
4. **Use consistent formatting**:
   - ❌ for errors
   - ✅ for success messages
   - 📦 for package manager operations
   - 📋 for informational messages
5. **Support multiple package managers** when applicable (npm/yarn/pnpm)
6. **Follow security best practices** - never log secrets or sensitive data

### Error Handling

```bash
# Good error handling example
if [ ! -f "package.json" ]; then
  echo "❌ ERROR: package.json not found in current directory"
  echo "Make sure you're running this action in a directory with a package.json file"
  exit 1
fi
```

### Package Manager Detection

When applicable, detect package managers in this order:

1. `yarn.lock` → yarn
2. `pnpm-lock.yaml` → pnpm
3. `package-lock.json` → npm
4. No lockfile → npm (default)

## Testing

### Test Structure

```txt
tests/
├── integration/           # Full action tests
│   └── action-name/
│       └── basic.bats
├── fixtures/              # Test data
│   ├── package-json/
│   └── lockfiles/
└── scripts/
    ├── test-runner.sh
    └── test-helpers.sh
```

### Writing Tests

1. **Create integration tests** for each action in `tests/integration/action-name/`
2. **Use the bats testing framework** for shell script testing
3. **Test error conditions** as well as success scenarios
4. **Use test fixtures** from `tests/fixtures/` when possible

Example test:

```bash
@test "action-name: handles valid input" {
    # Setup
    cp "$BATS_TEST_DIRNAME/../../../tests/fixtures/package-json/valid.json" package.json

    # Test
    run bash -c 'your-test-command'

    # Assertions
    assert_success
    assert_output_contains "expected-output"
}
```

### Running Tests

```bash
# All tests
pnpm test

# Specific action tests
./tests/scripts/test-runner.sh integration
```

## Documentation

### README Structure

Each action should have a comprehensive README.md with:

1. **Title and description**
2. **Table of contents** (for longer READMEs)
3. **Usage section** with basic example
4. **Inputs table** with descriptions
5. **Outputs table** (if applicable)
6. **Examples section** with various use cases
7. **Special features** (package manager detection, etc.)

### Documentation Updates

- Update action README when changing inputs/outputs
- **Run `pnpm docs:generate`** to auto-update the main project README
- Update CLAUDE.md when changing project structure
- Add inline comments for complex logic

### Auto-Generated Documentation

The main project README's "Available Actions" section is automatically generated from:

- `action.yml` files (name, description, inputs, outputs)
- Individual action README files (usage examples)

**When to regenerate documentation:**

- After adding a new action
- After changing action.yml inputs/outputs
- After updating action descriptions
- Before submitting a PR

```bash
# Generate updated documentation
pnpm docs:generate

# Review the changes
git diff README.md
```

## Submitting Changes

### Pull Request Process

1. **Create a descriptive PR title**: `feat(action-name): add new feature`
2. **Fill out the PR template** completely
3. **Link related issues** using keywords (Closes #123)
4. **Request review** from maintainers
5. **Address feedback** promptly and respectfully

### PR Requirements

- [ ] All tests pass
- [ ] Code follows existing style guidelines
- [ ] Documentation is updated
- [ ] Changes are tested in real GitHub Actions workflows
- [ ] No security vulnerabilities introduced

### Review Process

1. **Automated checks** must pass (tests, linting, security scans)
2. **Manual review** by maintainers
3. **Testing** in real-world scenarios
4. **Approval** and merge

## Action Ideas

Looking for contribution ideas? Here are some actions that would be valuable:

- `cache-restore-save` - Advanced caching patterns
- `monorepo-changed` - Detect changed packages in monorepos
- `performance-test` - Lighthouse/performance testing
