# ehr-keys-management-system

Electronic Health Records (EHR) Keys Management System

## Getting Started

### Prerequisites

- Node.js and npm (for commit tooling only, not the main application)

### Installation

1. Clone the repository
2. Install commit tooling dependencies:

```bash
npm install
```

This will automatically set up git hooks via Husky.

## Development Workflow

### Making Commits

This project uses **Conventional Commits** format to maintain a clear and structured commit history.

#### Interactive Commit (Recommended)

Use the interactive commit prompt:

```bash
npm run commit
```

Or directly:

```bash
npx cz
```

This will guide you through creating a properly formatted commit message with:
- **Type**: The kind of change (feat, fix, docs, etc.)
- **Scope** (optional): The area affected by the change
- **Subject**: A short description of the change
- **Body** (optional): A longer description
- **Breaking changes** (optional): Any breaking changes
- **Issues** (optional): Related issue numbers

#### Manual Commits

You can still use `git commit -m "message"`, but your commit message will be validated against the Conventional Commits format.

**Format**: `<type>(<scope>): <subject>`

**Example**: `feat(auth): add user authentication module`

#### Commit Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, white-space, etc.)
- **refactor**: Code changes that neither fix bugs nor add features
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

### Git Hooks

Two git hooks are automatically configured:

#### commit-msg Hook

Validates that your commit message follows the Conventional Commits format. If the format is incorrect, the commit will be rejected with an error message.

#### pre-commit Hook

Runs before each commit to check code quality. Currently configured with a placeholder.

**To customize for your project**, edit `.husky/pre-commit`:

```bash
# For Python projects
# black . && isort .
# pylint src/

# For Go projects
# go fmt ./...
# go vet ./...

# For JavaScript/TypeScript
# npm run lint
# npm run format
```

## Configuration Files

- `package.json`: Node.js dependencies for commit tooling
- `.czrc`: Commitizen configuration (commit types, line lengths)
- `.commitlintrc.json`: Commit message validation rules
- `.husky/`: Git hooks directory
  - `commit-msg`: Validates commit messages
  - `pre-commit`: Runs pre-commit checks

## Troubleshooting

### Hooks Not Running

If git hooks aren't running after `npm install`, manually reinstall Husky:

```bash
npm run prepare
```

### Bypass Hooks (Emergency Only)

To bypass hooks in exceptional circumstances:

```bash
git commit --no-verify -m "message"
```

**Note**: Only use this when absolutely necessary, as it skips validation.

## Contributing

1. Install dependencies: `npm install`
2. Make changes to your code
3. Commit using: `npm run commit`
4. Push your changes
