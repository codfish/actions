# setup-node-and-install

Sets up Node.js environment and installs dependencies with automatic package manager detection, intelligent caching, and
dynamic Node version detection via the `node-version` input, `.node-version`, `.nvmrc`, or `package.json` `volta.node`.

This action provides the following functionality:

- Automatically detects package manager (npm, yarn, or pnpm) from lockfiles
- Uses GitHub's official `setup-node` action (v6) with optimized caching
- **Upgrades npm to v11** (pinned to `^11.5.1` for OIDC trusted publishing support)
- Installs dependencies with appropriate commands based on detected package manager
- Supports `.node-version`, `.nvmrc`, and `package.json` `volta.node` for version specification
- Intelligent caching of node_modules when lockfiles are present

<!-- DOCTOC SKIP -->

## Usage

See [action.yml](action.yml).

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

The `node-version` input is optional. If not supplied, this action will attempt to resolve a version using, in order:

1. `.node-version`, 2) `.nvmrc`, 3) `package.json` `volta.node`. If none are present, `actions/setup-node` runs without
   an explicit version and will use its default behavior.

The `install-options` input is optional. If not supplied, the npm install commands will execute as defined without any
additional options.

**With `.nvmrc` file**

```sh
# .nvmrc
v18.14.1
```

```yml
steps:
  - uses: actions/checkout@v6
  # will install Node v18.14.1
  - uses: codfish/actions/setup-node-and-install@v3
  - run: npm test
```

**With `.node-version` file**

```sh
# .node-version
20.10.0
```

```yml
steps:
  - uses: actions/checkout@v6
  # will install Node v20.10.0
  - uses: codfish/actions/setup-node-and-install@v3
  - run: npm test
```

## Node Version Resolution Priority

When multiple version specification methods are present, the action uses this priority order:

1. **Input parameter** (`node-version`) - highest priority
2. **`.node-version` file**
3. **`.nvmrc` file**
4. **`package.json` `volta.node` property**
5. **`actions/setup-node` default behavior** when no version is specified

## Inputs

<!-- start inputs -->

| Input               | Description                                                                                                                                                                                    | Required | Default |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- |
| `node-version`      | Node.js version to install (e.g. "24", "lts/\*"). Precedence: node-version input > .node-version > .nvmrc > package.json volta.node.                                                           | No       | -       |
| `install-options`   | Extra command-line options to pass to npm/pnpm/yarn install.                                                                                                                                   | No       | -       |
| `working-directory` | Directory containing package.json and lockfile.                                                                                                                                                | No       | `.`     |
| `upgrade-npm`       | Whether to upgrade npm to v11.5.1. This is required for OIDC trusted publishing but can be disabled if you want to shave off some run time and you are still using token-based authentication. | No       | `true`  |

<!-- end inputs -->

## Package Manager Detection

The action automatically detects your package manager:

- **pnpm**: Detected when `pnpm-lock.yaml` exists
- **yarn**: Detected when `yarn.lock` exists
- **npm**: Detected when `package-lock.json` exists or as fallback

## npm Version Upgrade

This action automatically upgrades npm to **v11** after Node.js setup (pinned to `^11.5.1`). This ensures:

- npm 11.5.1+ is available for **OIDC trusted publishing** support (required as of January 2026)
- Stable, predictable npm behavior across workflows
- Security fixes and improvements within the v11 release line
- No unexpected breaking changes from major version updates

The upgrade happens transparently and is logged in the workflow output. The version is pinned to prevent unexpected
breaking changes while still receiving patch and minor updates within v11.

## Examples

### With specific Node version

```yml
- uses: codfish/actions/setup-node-and-install@v3
  with:
    node-version: '18'
```

### With pnpm in subdirectory

```yml
- uses: codfish/actions/setup-node-and-install@v3
  with:
    working-directory: './frontend'
    install-options: '--frozen-lockfile'
```

## Migrating

Replace multiple setup steps with this single action:

```diff
- - uses: actions/setup-node@v4
-   with:
-     node-version-file: '.nvmrc'
-     cache: 'npm'
- - run: npm ci --prefer-offline --no-audit
+ - uses: codfish/actions/setup-node-and-install@v3
```
