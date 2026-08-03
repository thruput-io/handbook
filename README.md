# Handbook

This repository contains guidelines and rules on how we build systems.

## Usage

1. Check out this project into your workspace directory as a sibling to your projects.
2. Create a `.junie` folder in your project.

### Configuration Options

#### Option 1: Symlink the Entire .junie Folder

Symlink the `.junie` folder from this repository to your project:

```bash
ln -s ../../.junie .
```

#### Option 2: Symlink Specific Guidelines

Symlink individual files from this repository to your `.junie` folder:

```bash
ln -s ../../handbook/bootstrap_prompt.md .
ln -s ../../handbook/frontend_guidelines.md .
ln -s ../../handbook/backend_guidelines.md .
```

## Skills

Skills live in [`thruput-io/skills`](https://github.com/thruput-io/skills), not here. They
reference the documents in this repository rather than copying them, so the handbook stays the
single source of truth.

| Skill | Handbook document it follows |
|---|---|
| `planning` | [`PLANNING.md`](./PLANNING.md) + [`PLAN_TEMPLATE.md`](./PLAN_TEMPLATE.md) |
| `pr-review` | [`CODE_REVIEW.md`](./CODE_REVIEW.md) |
