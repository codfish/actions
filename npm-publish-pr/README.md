# npm-publish-pr

Publishes packages with PR-specific version numbers for testing in downstream applications before merging. Supports both
**OIDC trusted publishing** (recommended) and token-based authentication. Automatically detects your package manager
(npm, yarn, or pnpm) for token-based publishing. The action generates versions in the format
`0.0.0-PR-{number}--{short-sha}` and automatically comments on the pull request with the published version.

**Key Features:**

- **OIDC trusted publishing** support (no secrets required for public packages!)
- Token-based authentication fallback for private packages
- Automatic package manager detection (npm/yarn/pnpm) for token mode
- Automatic PR version generation
- Publishes to registry with `pr` tag
- Automatic PR commenting with version info
- No git history modification

<!-- DOCTOC SKIP -->

## Migrating to OIDC Trusted Publishing

If you're currently using token-based authentication (`npm-token`), migrating to OIDC is recommended for public
packages. OIDC provides better security, automatic provenance attestations, and eliminates the need to manage npm
tokens.

### Requirements

1. **Public package** - OIDC trusted publishing only works with public repos & npm packages
2. **npm 11.5.1+** - Required for OIDC support
   - ✅ **Automatic**: Use `setup-node-and-install@v3` and it handles the npm upgrade for you
   - 🔧 **Manual**: Run `npm install -g npm@^11.5.1` before publishing
3. **Configure trusted publisher on npmjs.com** - One-time setup per package
4. **Update workflow permissions** - Add `id-token: write` to your workflow

### Migration Steps

1. **Configure trusted publisher on npmjs.com:**
   - Go to https://www.npmjs.com/package/YOUR-PACKAGE/access
   - Click "Add trusted publisher"
   - Fill in:
     - Provider: `GitHub Actions`
     - Organization/User: `your-github-username`
     - Repository: `your-repo-name`
     - Workflow: `<file>.yml` (exact filename, not the workflow `name`!)
     - Environment: Leave blank (unless using GitHub environments)

2. **Update your workflow:**

   ```diff
    on: pull_request_target

   +permissions:
   +  contents: read
   +  id-token: write
   +  pull-requests: write

    jobs:
      publish:
        runs-on: ubuntu-latest

        steps:
   +      # Use v3 for automatic npm 11.5.1+ upgrade
   +      - uses: codfish/actions/setup-node-and-install@v3
   +
          - uses: codfish/actions/npm-pr-version@v3
   -        with:
   -          npm-token: ${{ secrets.NPM_TOKEN }}
   ```

3. **Test on a PR** - Create a test PR to verify OIDC publishing works

4. **Remove npm token** - Once confirmed working, you can delete the `NPM_TOKEN` secret

## Usage

See [action.yml](action.yml).

### OIDC Trusted Publishing (Recommended for Public Packages)

No npm token required! Just configure your package on npmjs.com for trusted publishing.

```yaml
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

> **Note:** `setup-node-and-install@v3` automatically upgrades npm to v11 (required for OIDC).

### Token-Based Authentication (For Private Packages)

```yaml
permissions:
  pull-requests: write

steps:
  - uses: actions/checkout@v6

  - uses: codfish/actions/setup-node-and-install@v3
    with:
      node-version: lts/*

  - run: npm run build

  - uses: codfish/actions/npm-pr-version@v3
    with:
      npm-token: ${{ secrets.NPM_TOKEN }}
```

### Disable PR Comments

```yaml
- uses: codfish/actions/npm-pr-version@v3
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
    comment: false
```

### Custom Comment Tag

```yaml
- uses: codfish/actions/npm-pr-version@v3
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
    comment-tag: my-custom-tag
```

## Complete Workflow Example

### With OIDC (Recommended)

```yaml
name: PR Package Testing

on: pull_request_target

permissions:
  contents: read
  id-token: write
  pull-requests: write

jobs:
  publish-pr-package:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v6

      - uses: codfish/actions/setup-node-and-install@v3

      - name: Build package
        run: npm run build

      - name: Publish PR package
        uses: codfish/actions/npm-pr-version@v3
```

### With Token (Private Packages)

```yaml
name: PR Package Testing

on: pull_request_target

permissions:
  contents: read
  pull-requests: write

jobs:
  publish-pr-package:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6

      - uses: codfish/actions/setup-node-and-install@v3

      - name: Build package
        run: npm run build

      - name: Publish PR package
        uses: codfish/actions/npm-pr-version@v3
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
```

## Testing Downstream

After the action runs, you can install the PR version in downstream projects:

```bash
npm install my-package@0.0.0-PR-123--abc1234
```

The package is published under the `pr` tag, so it won't interfere with your regular releases.

## Inputs

<!-- start inputs -->

| Input         | Description                                                                                                    | Required | Default          |
| ------------- | -------------------------------------------------------------------------------------------------------------- | -------- | ---------------- |
| `npm-token`   | Registry authentication token with publish permissions. If not provided, OIDC trusted publishing will be used. | No       | -                |
| `comment`     | Whether to comment on the PR with the published version (true/false)                                           | No       | `true`           |
| `comment-tag` | Tag to use for PR comments (for comment identification and updates)                                            | No       | `npm-publish-pr` |

<!-- end inputs -->

## Authentication Modes

### OIDC Trusted Publishing (Recommended)

When `npm-token` is not provided, the action uses OIDC trusted publishing:

- **Requires**: `id-token: write` permission in workflow
- **Works with**: Public packages only
- **Command**: Always uses `npm publish --access public --tag pr --provenance`
- **Benefits**: No secrets required, automatic provenance attestations
- **Setup**: Configure trusted publisher on npmjs.com (see [npm docs](https://docs.npmjs.com/trusted-publishers))

### Token-Based Authentication

When `npm-token` is provided, the action detects your package manager:

- **npm**: Uses `npm publish --access public --tag pr`
- **yarn**: Uses `yarn publish --access public --tag pr --new-version {version} --no-git-tag-version`
- **pnpm**: Uses `pnpm publish --access public --tag pr`

Detection is based on lockfile presence:

- `yarn.lock` → yarn
- `pnpm-lock.yaml` → pnpm
- `package-lock.json` or no lockfile → npm

## Outputs

<!-- start outputs -->

| Output          | Description                                                           |
| --------------- | --------------------------------------------------------------------- |
| `version`       | Generated PR-specific version number (0.0.0-PR-{number}--{short-sha}) |
| `package-name`  | Package name from package.json                                        |
| `error-message` | Error message if publish fails                                        |

<!-- end outputs -->

## Version Format

Published versions follow the pattern: `0.0.0-PR-{pr-number}--{short-sha}`

Examples:

- `0.0.0-PR-123--abc1234` (PR #123, commit abc1234)
- `0.0.0-PR-456--def5678` (PR #456, commit def5678)

## Troubleshooting

### Error: "Access token expired or revoked" / 404 Not Found

This error typically occurs when using OIDC trusted publishing and indicates one of the following issues:

#### Missing `id-token: write` Permission

**Symptom:**

```sh
npm notice Access token expired or revoked. Please try logging in again.
npm error code E404
npm error 404 Not Found - PUT https://registry.npmjs.org/@your-package
```

**Solution:** Add `id-token: write` permission to your workflow:

```yaml
permissions:
  contents: read
  id-token: write # REQUIRED for OIDC!
  pull-requests: write
```

Without this permission, GitHub cannot generate the OIDC token needed for npm trusted publishing.

#### Workflow Name Mismatch

**Symptom:** Same 404 error, but permissions are set correctly.

**Solution:** Verify your npm trusted publisher configuration matches exactly:

- Repository name is case-sensitive: `my-repo` ≠ `My-Repo`
- Workflow filename must be exact: `validate.yml` not `.github/workflows/validate.yml` or `Validate Code`
- Check at: https://www.npmjs.com/package/YOUR-PACKAGE/access

#### Publishing from a Fork

**Symptom:** 404 error when PR is from a forked repository.

**Solution:** OIDC tokens are not available for forked PRs. Add a condition to skip publishing:

```yaml
- uses: codfish/actions/npm-pr-version@v3
  if: github.event.pull_request.head.repo.full_name == github.repository
```

#### Private Package with OIDC

**Symptom:** 404 error on private package.

**Solution:** OIDC trusted publishing only works with **public packages**. For private packages, use token-based
authentication:

```yaml
- uses: codfish/actions/npm-pr-version@v3
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
```

### Error: npm version too old

**Symptom:**

```sh
npm ERR! --provenance flag is not supported
```

**Solution:** OIDC trusted publishing requires npm 11.5.1+. Use `setup-node-and-install@v3` which automatically upgrades
npm to v11 for you:

```yaml
- uses: codfish/actions/setup-node-and-install@v3
  with:
    node-version: lts/*
```

This action will upgrade npm from whatever version comes with Node.js to v11 (pinned to `^11.5.1`), ensuring OIDC
compatibility.

**Manual alternative:** If not using the setup action, upgrade npm yourself:

```yaml
- run: npm install -g npm@^11.5.1
```

### Debugging OIDC Issues

To debug OIDC authentication issues, check the workflow logs for:

1. **OIDC environment variables** - Should see:

   ```txt
   🔐 Using OIDC trusted publishing (no npm-token provided)
   ```

2. **npm version** - Should be 11.5.1 or higher:

   ```txt
   npm version: 11.5.1
   ```

3. **Verify permissions** - Check workflow run permissions in GitHub UI

4. **Check npm configuration** - Go to npmjs.com → Your Package → Publishing Access → Verify trusted publisher settings
   match your workflow exactly
