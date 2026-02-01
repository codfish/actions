# Security Policy

<!-- eslint-disable -->
<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
## Table of Contents

- [Supported Versions](#supported-versions)
- [Reporting a Vulnerability](#reporting-a-vulnerability)
  - [🔒 Private Disclosure](#-private-disclosure)
  - [📋 What to Include](#-what-to-include)
  - [🕐 Response Timeline](#-response-timeline)
- [Security Best Practices for Users](#security-best-practices-for-users)
  - [🔐 Secrets Management](#-secrets-management)
  - [🏷️ Action Versioning](#-action-versioning)
  - [🔍 Workflow Permissions](#-workflow-permissions)
  - [🛡️ Input Validation](#-input-validation)
- [Security Features](#security-features)
  - [🔒 Automated Security Scanning](#-automated-security-scanning)
  - [🛡️ Secure Development Practices](#-secure-development-practices)
  - [🔍 Supply Chain Security](#-supply-chain-security)
- [Known Security Considerations](#known-security-considerations)
  - [GitHub Actions Environment](#github-actions-environment)
  - [npm Publishing (npm-pr-version)](#npm-publishing-npm-pr-version)
  - [Comment Actions](#comment-actions)
- [Incident Response](#incident-response)
- [Security Contact](#security-contact)
- [Acknowledgments](#acknowledgments)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->
<!-- eslint-enable -->

## Supported Versions

This project follows a rolling release model. We provide security updates for:

| Version             | Supported           |
| ------------------- | ------------------- |
| main                | ✅ Always supported |
| Latest release tags | ✅ Supported        |
| Older releases      | ❌ Not supported    |

## Reporting a Vulnerability

If you discover a security issue, please follow these steps:

### 🔒 Private Disclosure

**Do NOT create a public issue for security vulnerabilities.**

Instead, please report security issues privately using one of these methods:

1. **GitHub Security Advisories** (preferred)
   - Go to the [Security tab](https://github.com/codfish/actions/security/advisories)
   - Click "Report a vulnerability"
   - Fill out the form with details

2. **Email**
   - Send details to: [chris@codfish.dev](mailto:chris@codfish.dev)
   - Include "SECURITY" in the subject line

### 📋 What to Include

When reporting a vulnerability, please include:

- **Description** of the vulnerability
- **Steps to reproduce** the issue
- **Potential impact** of the vulnerability
- **Suggested fix** (if you have one)
- **Your contact information** for follow-up

### 🕐 Response Timeline

We aim to respond to security reports within:

- **Initial response**: 24-48 hours
- **Confirmation/triage**: 2-5 business days
- **Resolution**: Varies based on complexity

## Security Best Practices for Users

When using these GitHub Actions in your workflows:

### 🔐 Secrets Management

- **Never log secrets** in workflows that use these actions
- Use **GitHub Secrets** for sensitive information
- **Limit secret scope** to only necessary workflows
- **Rotate secrets** regularly

```yaml
# ✅ Good - Using secrets properly
- uses: codfish/actions/npm-pr-version@v3
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}

# ❌ Bad - Exposing secrets
- name: Debug
  run: echo "Token: ${{ secrets.NPM_TOKEN }}"
```

### 🏷️ Action Versioning

- **Pin to specific versions or commit hashes** for production workflows
- **Avoid using `@main`** in production (use for testing only)

```yaml
# ✅ Good - Pinned version
- uses: codfish/actions/setup-node-and-install@v3.2.3

# ⚠️ Caution - Latest main (testing only)
- uses: codfish/actions/setup-node-and-install@v3
```

### 🔍 Workflow Permissions

- **Use minimal permissions** required
- **Specify explicit permissions** when possible
- **Avoid using `write-all`** permissions

```yaml
# ✅ Good - Minimal permissions
permissions:
  contents: read
  issues: write
  pull-requests: write

# ❌ Bad - Excessive permissions
permissions: write-all
```

### 🛡️ Input Validation

- **Validate user inputs** before using them in actions
- **Sanitize outputs** when displaying them
- **Be cautious with dynamic expressions**

## Security Features

This project implements several security measures:

### 🔒 Automated Security Scanning

- **Dependabot** for dependency updates
- **CodeQL** for static analysis
- **Dependency Review** for PR security checks
- **Secret scanning** with TruffleHog
- **npm audit** for vulnerability detection

### 🛡️ Secure Development Practices

- **Input validation** in all actions
- **Error handling** without information disclosure
- **No secret logging** in any action
- **Least privilege** principle in action permissions

### 🔍 Supply Chain Security

- **Minimal dependencies** to reduce attack surface
- **Regular dependency updates** via Dependabot
- **Verified action references** in workflows

## Known Security Considerations

### GitHub Actions Environment

- **Actions run in GitHub's infrastructure** - we cannot control the runner environment
- **Secrets are available** to all steps in a job that has access
- **Workflow logs are visible** to users with read access to the repository

### npm Publishing (npm-pr-version)

- **NPM tokens have broad permissions** - ensure tokens are scoped appropriately
- **Published packages are public** by default - review package contents
- **Version immutability** - published versions cannot be unpublished

### Comment Actions

- **GitHub tokens can comment** on behalf of the workflow user
- **Comment content is public** - avoid including sensitive information
- **Rate limiting applies** - excessive commenting may be throttled

## Incident Response

In case of a confirmed security vulnerability:

1. **Assessment** - Evaluate severity and impact
2. **Mitigation** - Develop and test fixes
3. **Disclosure** - Coordinate with reporter on disclosure timeline
4. **Release** - Deploy security fixes
5. **Communication** - Notify users through appropriate channels

## Security Contact

- **Primary**: [security@codfish.dev](mailto:security@codfish.dev)
- **GitHub**: [@codfish](https://github.com/codfish)

## Acknowledgments

We appreciate security researchers and users who responsibly disclose vulnerabilities. Contributors who report valid
security issues will be acknowledged (with permission) in:

- Security advisories
- Release notes
- This security policy

Thank you for helping keep this project secure! 🔒
