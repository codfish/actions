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
- Run specific test types: `pnpm test:integration`, `pnpm test:unit`

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

## Current Actions

- `npm-pr-version` - Publishes packages with PR-specific version numbers using detected package manager (npm/yarn/pnpm)
  for testing in downstream apps before merging
- `comment` - Creates or updates pull request comments with intelligent upsert functionality using unique tags
- `setup-node-and-install` - Sets up Node.js environment and installs dependencies with automatic package manager
  detection, intelligent caching, and .nvmrc/.node-version support

## Testing

The project includes comprehensive testing infrastructure:

- **Integration tests**: Test full action workflows using bats
- **Test fixtures**: Reusable test data for different scenarios
- **CI/CD validation**: Dogfooding actions in GitHub workflows
- **Multi-platform testing**: Ubuntu, Windows, macOS support

Run tests with: `pnpm test`

## Security

The project implements multiple security measures:

- **Dependabot**: Automated dependency updates
- **CodeQL**: Static security analysis
- **Secret scanning**: TruffleHog for committed secrets
- **Vulnerability auditing**: Regular pnpm audit checks
- **Dependency review**: Security checks on PRs
