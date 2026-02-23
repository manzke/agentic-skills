# Agentic Skills Repository

A curated collection of reusable AI agent skills following the [Agent Skills](https://agentskills.io/) format specification, compatible with Claude Code and other AI agent platforms.

## Overview

This repository provides modular, portable skills that can be used across different AI agent platforms including Claude Code, OpenAI Codex, and more. Each skill is self-contained with clear instructions and metadata, enabling agents to discover and execute them efficiently.

## Repository Structure

```
.
├── skills/               # Collection of agent skills
│   └── [skill-name]/    # Individual skill directory
│       ├── SKILL.md     # Skill metadata and instructions
│       ├── scripts/     # Optional: executable scripts
│       ├── references/  # Optional: documentation
│       └── assets/      # Optional: templates and files
├── .claude-plugin/      # Claude Code marketplace integration
│   └── marketplace.json # Plugin marketplace catalog
└── README.md           # This file
```

## Agent Skills Format

Each skill follows the [Agent Skills specification](https://agentskills.io/specification):

### Skill Structure

Every skill is a directory containing:

- **SKILL.md** (required): Skill metadata (YAML frontmatter) and step-by-step instructions (Markdown)
- **scripts/** (optional): Executable scripts in Python, Shell, JavaScript, etc.
- **references/** (optional): Additional documentation or reference materials
- **assets/** (optional): Templates, data files, or other static resources

### SKILL.md Format

```markdown
---
name: skill-name
description: Clear description of what the skill does and when to use it
license: MIT
compatibility: Platform or environment requirements
allowed-tools: [python, bash, curl]
---

# Skill Name

## Instructions

Step-by-step instructions for the agent to follow...

## Examples

Usage examples...
```

### Metadata Fields

**Required:**
- `name`: Unique identifier (lowercase, alphanumeric, hyphens only)
- `description`: What the skill does (1-1024 characters)

**Optional:**
- `license`: License identifier or file reference
- `compatibility`: Environment requirements
- `allowed-tools`: List of tools/APIs the skill uses
- `metadata`: Custom key-value pairs

## Claude Code Marketplace

This repository includes a `.claude-plugin/marketplace.json` file that enables Claude Code users to discover and install skills as plugins. The marketplace catalog automatically lists all available skills in this repository.

### Installing Skills in Claude Code

1. Add this repository as a plugin marketplace in Claude Code
2. Browse available skills from the marketplace
3. Install skills directly into your Claude Code environment

## Available Skills

| Skill | Description | Tools |
|-------|-------------|-------|
| [code-review](skills/code-review/) | Performs comprehensive code reviews with security and quality checks | bash, git |
| [interview-to-blog](skills/interview-to-blog/) | Produce deep, long-form blog posts by interviewing the user first, researching the topic, architecting the structure, then writing | web_search (optional) |

## Usage

### For AI Agents

Agents can scan skills by:
1. Reading skill names and descriptions from directory structure
2. Loading full SKILL.md when executing a skill
3. Accessing supporting files as needed

### For Developers

```bash
# Clone the repository
git clone https://github.com/manzke/agentic-skills.git

# Browse skills
cd agentic-skills/skills

# Each skill contains complete instructions in SKILL.md
cat code-review/SKILL.md
```

## Contributing

We welcome contributions of new skills! Please ensure your skills:

1. Follow the Agent Skills format specification
2. Include clear, actionable instructions
3. Provide usage examples
4. Specify all required tools and dependencies
5. Include appropriate license information

### Adding a New Skill

1. Create a new directory in `skills/` with your skill name (lowercase, hyphens)
2. Add a `SKILL.md` file with proper YAML frontmatter
3. Include any supporting files in appropriate subdirectories
4. Update the skills table in this README
5. Submit a pull request

## License

Individual skills may have their own licenses. Please check each skill's metadata for license information.

## Resources

- [Agent Skills Specification](https://agentskills.io/specification)
- [Claude Code Documentation](https://code.claude.com/docs)
- [Agent Skills Examples](https://github.com/agentskills)

## Support

For issues, questions, or suggestions, please open an issue in this repository.
