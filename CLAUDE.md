# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Claude Code plugin marketplace (`sifyfy-plugins`). Each top-level directory is an independent plugin with its own `.claude-plugin/plugin.json`. The marketplace catalog is defined in `.claude-plugin/marketplace.json`.

## Architecture

```
.claude-plugin/marketplace.json    # Marketplace catalog (lists all plugins)
{plugin-name}/                     # Each plugin is a self-contained directory
  .claude-plugin/plugin.json       # Plugin manifest
  skills/                          # Auto-discovered by Claude Code
  commands/                        # Auto-discovered by Claude Code
  agents/                          # Auto-discovered by Claude Code
  hooks/                           # Auto-discovered by Claude Code
```

Adding a new plugin: create a directory at repo root with `.claude-plugin/plugin.json`, then add an entry to `.claude-plugin/marketplace.json` `plugins` array.

## Validation and Testing

```bash
# Validate marketplace structure
claude plugin validate .

# Test locally
/plugin marketplace add ./path/to/this/repo
/plugin install docs-indexer@sifyfy-plugins

# Test a skill's script directly
bash docs-indexer/skills/docs-indexer/scripts/generate-index.sh <source-dir> <index-name>
```

## Key Conventions

- Plugin names use kebab-case
- Skills follow progressive disclosure: lean SKILL.md (~1500-2000 words), detailed content in `references/`, utilities in `scripts/`
- SKILL.md frontmatter `description` must use third-person with trigger phrases
- SKILL.md body uses imperative/infinitive form, not second person
- Scripts use `${CLAUDE_PLUGIN_ROOT}` for portable path references
- Temporary files go in `.temp/` (gitignored)
