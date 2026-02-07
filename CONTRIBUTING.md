# Contributing to pihole-manage

Thanks for your interest in contributing! This guide covers how to get involved.

## Ways to Contribute

- **Report bugs** — Open an issue describing the problem and steps to reproduce
- **Suggest features** — Open an issue with the `enhancement` label
- **Improve documentation** — Fix typos, clarify instructions, add examples
- **Add API coverage** — Update endpoint references when Pi-hole releases new API features
- **Improve the helper script** — Add new commands, fix compatibility issues

## Getting Started

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR-USERNAME/pihole-manage.git
   cd pihole-manage
   ```
3. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
4. Make your changes
5. Test against a Pi-hole instance if possible
6. Commit and push:
   ```bash
   git add -A
   git commit -m "feat: description of your change"
   git push origin feature/your-feature-name
   ```
7. Open a Pull Request

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — New feature or capability
- `fix:` — Bug fix
- `docs:` — Documentation changes only
- `refactor:` — Code change that neither fixes a bug nor adds a feature
- `chore:` — Maintenance tasks

## Guidelines

### SKILL.md

- Keep the body under 5,000 words — move detailed content to `references/`
- Use imperative/infinitive form (e.g., "Add a domain" not "You should add a domain")
- Include curl examples for every workflow

### references/api-endpoints.md

- Keep endpoint tables organized by category
- Include HTTP method, path, and description for every endpoint
- Document query parameters and request bodies where applicable
- Verify against the [Pi-hole FTL source](https://github.com/pi-hole/FTL/blob/master/src/api/api.c) or a live instance

### scripts/pihole-api.sh

- Maintain cross-platform compatibility (Linux, macOS, Windows/Git Bash)
- Use `jq` with Python 3 fallback for JSON parsing
- Use `#!/usr/bin/env bash` shebang
- Keep functions focused — one API call per function
- Add new commands to both the function list and the CLI `case` block

### General

- No hardcoded paths — use `~` or `$HOME`
- No secrets in committed files
- Test changes when possible

## Reporting Issues

When filing an issue, include:

1. Pi-hole version (`/api/info/version`)
2. How you're using the skill (Claude Code skill or standalone script)
3. The command or workflow that failed
4. The error message or unexpected behavior
5. Your OS and shell environment

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
