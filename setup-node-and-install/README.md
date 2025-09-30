# setup-node-and-install

Sets up Node.js environment and installs dependencies with automatic package manager detection, intelligent caching, and
dynamic Node version detection via the `node-version` input, `.node-version`, `.nvmrc`, or `package.json` `volta.node`.

This action provides the following functionality:

- Automatically detects package manager (npm, yarn, or pnpm) from lockfiles
- Uses GitHub's official `setup-node` action with optimized caching
- Installs dependencies with appropriate commands based on detected package manager
- Supports `.node-version`, `.nvmrc`, and `package.json` `volta.node` for version specification
- Intelligent caching of node_modules when lockfiles are present

<!-- DOCTOC SKIP -->

## Usage

See [action.yml](action.yml).

```yaml
steps:
  - uses: actions/checkout@v5

  # will install latest Node v18.x
  - uses: codfish/actions/setup-node-and-install@v1
    with:
      node-version: 18
      cache-key-suffix: '-${{ github.head_ref || github.event.release.tag_name }}'

  - run: npm test
```

The `node-version` input is optional. If not supplied, this action will attempt to resolve a version using, in order:

1. `.node-version`, 2) `.nvmrc`, 3) `package.json` `volta.node`. If none are present, `actions/setup-node` runs without
   an explicit version and will use its default behavior.

The `cache-key-suffix` input is optional. If not supplied, no suffix will be applied to the cache key used to restore
cache in subsequent workflow runs.

The `install-options` input is optional. If not supplied, the npm install commands will execute as defined without any
additional options.

**With `.nvmrc` file**

```sh
# .nvmrc
v18.14.1
```

```yaml
steps:
  - uses: actions/checkout@v5
  # will install Node v18.14.1
  - uses: codfish/actions/setup-node-and-install@v1
  - run: npm test
```

**With `.node-version` file**

```sh
# .node-version
20.10.0
```

```yaml
steps:
  - uses: actions/checkout@v5
  # will install Node v20.10.0
  - uses: codfish/actions/setup-node-and-install@v1
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

| Input               | Description                                                                                                                          | Required | Default |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ | -------- | ------- |
| `node-version`      | Node.js version to install (e.g. "24", "lts/\*"). Precedence: node-version input > .node-version > .nvmrc > package.json volta.node. | No       | -       |
| `install-options`   | Extra command-line options to pass to npm/pnpm/yarn install.                                                                         | No       | -       |
| `working-directory` | Directory containing package.json and lockfile.                                                                                      | No       | `.`     |

<!-- end inputs -->

## Package Manager Detection

The action automatically detects your package manager:

- **pnpm**: Detected when `pnpm-lock.yaml` exists
- **npm**: Detected when `package-lock.json` exists or as fallback

## Examples

### With specific Node version

```yaml
- uses: codfish/actions/setup-node-and-install@v1
  with:
    node-version: '18'
```

### With pnpm in subdirectory

```yaml
- uses: codfish/actions/setup-node-and-install@v1
  with:
    working-directory: './frontend'
    install-options: '--frozen-lockfile'
```

### With custom cache key

```yaml
- uses: codfish/actions/setup-node-and-install@v1
  with:
    cache-key-suffix: '-${{ github.head_ref }}'
```

## Migrating

Replace multiple setup steps with this single action:

```diff
- - uses: actions/setup-node@v4
-   with:
-     node-version-file: '.nvmrc'
-     cache: 'npm'
- - run: npm ci --prefer-offline --no-audit
+ - uses: codfish/actions/setup-node-and-install@v1
```
