# npm-publish-pr

Publishes packages with PR-specific version numbers for testing in downstream applications before merging. Automatically
detects your package manager (npm, yarn, or pnpm) and uses the appropriate publish command. The action generates
versions in the format `0.0.0-PR-{number}--{short-sha}` and automatically comments on the pull request with the
published version.

**Key Features:**

- Automatic package manager detection (npm/yarn/pnpm)
- Automatic PR version generation
- Publishes to registry with `pr` tag
- Automatic PR commenting with version info
- No git history modification

<!-- DOCTOC SKIP -->

## Usage

See [action.yml](action.yml).

```yaml
steps:
  - uses: actions/checkout@v5

  - uses: codfish/actions/setup-node-and-install@v1
    with:
      node-version: lts/*

  - run: npm run build

  - uses: codfish/actions/npm-pr-version@v1
    with:
      npm-token: ${{ secrets.NPM_TOKEN }}
      github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Disable PR Comments

```yaml
- uses: codfish/actions/npm-pr-version@v1
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    comment: false
```

### Custom Comment Tag

```yaml
- uses: codfish/actions/npm-pr-version@v1
  with:
    npm-token: ${{ secrets.NPM_TOKEN }}
    github-token: ${{ secrets.GITHUB_TOKEN }}
    comment-tag: my-custom-tag
```

## Complete Workflow Example

```yaml
name: PR Package Testing

on: pull_request_target

permissions:
  contents: write
  pull-requests: write

jobs:
  publish-pr-package:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5

      - uses: codfish/actions/setup-node-and-install@v1
        with:
          node-version: 'lts/*'

      - name: Build package
        run: npm run build

      - name: Publish PR package
        uses: codfish/actions/npm-pr-version@v1
        with:
          npm-token: ${{ secrets.NPM_TOKEN }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Testing Downstream

After the action runs, you can install the PR version in downstream projects:

```bash
npm install my-package@0.0.0-PR-123--abc1234
```

The package is published under the `pr` tag, so it won't interfere with your regular releases.

## Inputs

<!-- start inputs -->

| Input          | Description                                                                         | Required | Default          |
| -------------- | ----------------------------------------------------------------------------------- | -------- | ---------------- |
| `npm-token`    | Registry authentication token with publish permissions (works with npm/yarn/pnpm)   | Yes      | -                |
| `github-token` | GitHub token with pull request comment permissions (typically secrets.GITHUB_TOKEN) | Yes      | -                |
| `comment`      | Whether to comment on the PR with the published version (true/false)                | No       | `true`           |
| `comment-tag`  | Tag to use for PR comments (for comment identification and updates)                 | No       | `npm-publish-pr` |

<!-- end inputs -->

## Package Manager Support

The action automatically detects your package manager and uses the appropriate publish command:

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
