# Bosun

Bosun is a Claude Code plugin that helps developers get the most out of Claude Code throughout the entire development lifecycle—from initial setup to development, code review, and release.

> **Note:** This project is in early development. Features described below represent the planned roadmap.

## What is Bosun?

Like a ship's bosun who oversees the crew and equipment, Bosun guides you through your development journey with Claude Code. It provides tools, best practices, and automated workflows to streamline your coding experience.

### Planned Features

- **Initial Setup** — Project scaffolding, configuration templates, and environment setup assistance
- **Development** — Coding standards, patterns, and productivity enhancements
- **Code Review** — Automated review workflows, quality checks, and feedback integration
- **Release** — Version management, changelog generation, and deployment preparation

## Installation

First, add the Bosun marketplace:

```
/plugin marketplace add curphey/bosun
```

Then install the plugin with one of the following scopes:

**Global** (available in all projects):
```
/plugin install --global bosun@curphey/bosun
```

**Project** (available to anyone working on this repo):
```
/plugin install --project bosun@curphey/bosun
```

**User** (just for yourself in this project):
```
/plugin install bosun@curphey/bosun
```

## Usage

Once installed, Bosun's skills and commands will be available in Claude Code. You can:

- Help set up a new project with best practices
- Review your code before committing
- Prepare a release with proper versioning and changelogs

## License

MIT License — see [LICENSE](LICENSE) for details.
