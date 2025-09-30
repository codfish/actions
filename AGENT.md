# AGENT.md

<!-- DOCTOC SKIP -->

This file provides guidance to AI agents when working with code in this repository.

## Project Overview

This repository contains reusable GitHub Actions for use across multiple projects. Each action is self-contained in its
own directory at the root level.

## Package Manager

This project uses **pnpm** as the package manager. All commands should use pnpm:

- Install dependencies: `pnpm install`
- Run tests: `pnpm test`
- Run linting: `pnpm lint`
- Format code: `pnpm format`
- Generate documentation: `pnpm docs:generate`
- Run specific test types: `pnpm test:integration`, `pnpm test:unit`

## Code Quality Workflow

**IMPORTANT**: Always run the appropriate command after making file changes:

- **For JS/TS/TSX/JSX/YML/YAML files**: Run `pnpm fix` to apply ESLint fixes (CRITICAL for YAML files to prevent
  formatting issues)
- **For JSON/MD/CSS files**: Run `pnpm format` to apply Prettier formatting
- **When in doubt**: Run both commands in sequence

## Action Structure

- Action names: lowercase kebab-case (e.g., `npm-publish-pr`)
- Each action directory contains:
  - `action.yml` - Action definition and metadata
  - Implementation files (JavaScript/TypeScript as needed)
  - `README.md` - Action-specific documentation

## Development Guidelines

- Actions should be standalone and reusable across different projects
- Follow GitHub Actions best practices for inputs, outputs, and error handling
- Use semantic action names that clearly describe their purpose
- Each action should handle its own dependencies and setup requirements
- All actions support multiple package managers (npm/yarn/pnpm) when applicable
- Use comprehensive input validation with clear error messages
- Include proper error handling and informative logging

## Security Best Practices

- **File Operations**: Use file descriptors (`fs.openSync()`, `fs.readSync()`, `fs.writeSync()`) instead of file names
  (`fs.readFileSync()`, `fs.writeFileSync()`) to prevent TOCTOU (Time-of-Check-Time-of-Use) vulnerabilities
- **Resource Management**: Always close file descriptors in `finally` blocks to prevent resource leaks
- **Atomic Operations**: Keep file descriptors open during entire read-modify-write operations to prevent race
  conditions

## Current Actions

- `npm-pr-version` - Publishes packages with PR-specific version numbers using detected package manager (npm/yarn/pnpm)
  for testing in downstream apps before merging
- `comment` - Creates or updates pull request comments with intelligent upsert functionality using unique tags
  - **IMPORTANT**: Any job using the comment action must include `permissions: pull-requests: write`
- `setup-node-and-install` - Sets up Node.js environment and installs dependencies with automatic package manager
  detection, intelligent caching, and dynamic Node version detection via input, `.node-version`, `.nvmrc`, or
  `package.json` `volta.node`. Validation is relaxed; the action no longer fails when no version is detected.

## Testing

The project includes comprehensive testing infrastructure:

- **Integration tests**: Test full action workflows using bats
- **Test fixtures**: Reusable test data for different scenarios
- **CI/CD validation**: Dogfooding actions in GitHub workflows
- **Multi-platform testing**: Ubuntu, Windows, macOS support

Run tests with: `pnpm test`

**Cross-Platform Notes:**

- Test scripts use `bash` prefix for Windows compatibility
- All npm scripts should work on Windows, macOS, and Linux
- Bats tests require bash to be available (included in Git for Windows)

## Documentation System

### Automated Documentation Generation

- Run `pnpm docs:generate` to update all documentation
- The script automatically:
  1. Updates main README.md with action overview using `<!-- start action docs -->` / `<!-- end action docs -->` markers
  2. Updates individual action README files with inputs/outputs tables using `<!-- start inputs -->` /
     `<!-- end inputs -->` and `<!-- start outputs -->` / `<!-- end outputs -->` markers
  3. Runs prettier formatting on all updated documentation

### Documentation Markers

- **Main README.md**: Uses `<!-- start action docs -->` and `<!-- end action docs -->` for the Available Actions section
- **Action README files**: Uses `<!-- start inputs -->` / `<!-- end inputs -->` for inputs tables and
  `<!-- start outputs -->` / `<!-- end outputs -->` for outputs tables
- **CRITICAL: NEVER EDIT AUTO-GENERATED CONTENT**: Never modify content between ANY HTML comment markers in README
  files:
  - `<!-- START doctoc generated TOC please keep comment here to allow auto update -->` and
    `<!-- END doctoc generated TOC please keep comment here to allow auto update -->` (doctoc table of contents)
  - `<!-- start action docs -->` and `<!-- end action docs -->` (main README action documentation)
  - `<!-- start inputs -->` and `<!-- end inputs -->` (action inputs tables)
  - `<!-- start outputs -->` and `<!-- end outputs -->` (action outputs tables)
  - Any other `<!-- ... -->` comment markers - they indicate auto-generated content
- All content outside these markers is manually maintained and can be edited
- **Prettier Protection**: Doctoc blocks are wrapped in `<!-- prettier-ignore-start -->` and
  `<!-- prettier-ignore-end -->` to prevent formatting

### Workflow Automation

- `.github/workflows/update-docs.yml` automatically runs on changes to `*/action.yml` or `bin/generate-docs.js`
- Uses `stefanzweifel/git-auto-commit-action` to commit documentation changes
- Handles both main README.md and all action README files
- Automatically formats all documentation using prettier

## Security

The project implements multiple security measures:

- **Dependabot**: Automated dependency updates
- **CodeQL**: Static security analysis
- **Secret scanning**: TruffleHog for committed secrets (uses default behavior without base/head commits for better
  compatibility)
- **Vulnerability auditing**: Regular pnpm audit checks
- **Note**: Dependency review requires GitHub Advanced Security (available free on public repos, paid feature for
  private repos)

## Code Quality and File Editing Rules

### Bats File Editing Rules

**CRITICAL**: After editing any `.bats` file, ALWAYS check for and remove trailing spaces:

1. Run: `grep -n " $" path/to/file.bats`
2. If any trailing spaces are found, remove them immediately
3. Bats files are NOT automatically formatted by eslint/prettier, so manual cleanup is required
4. Trailing spaces in bats files can cause test execution issues

### General File Editing Guidelines

- Do what has been asked; nothing more, nothing less
- NEVER create files unless they're absolutely necessary for achieving your goal
- ALWAYS prefer editing an existing file to creating a new one
- NEVER proactively create documentation files (\*.md) or README files. Only create documentation files if explicitly
  requested by the User
