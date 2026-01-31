# Compressed Documentation Index Format Specification

## Background

A compressed index format for AI coding agents, based on Vercel's evaluation
(https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals).
Keeps only a lightweight index in context, allowing the agent to read full
documentation files on demand.

## Format Specification

### Basic Structure

```
[{Name} Docs Index]|root: {root-path}|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning|{relative-path}:{file-list}|...
```

### Elements

| Element | Description | Example |
|---------|-------------|---------|
| Header | `[Name Docs Index]` | `[React Docs Index]` |
| Root | `root: {path}` | `root: ./.react-docs` |
| Directive | Retrieval-first instruction | `IMPORTANT: Prefer retrieval-led reasoning...` |
| Entry | `path:{files}` | `guides:{intro.md,setup.md}` |

### Delimiters

| Character | Purpose |
|-----------|---------|
| `\|` (pipe) | Line separator (replaces newlines) |
| `:` | Separates directory path from file list |
| `{}` | Groups files within a directory |
| `,` | Separates file names within a group |

### Root Directory Files

Files directly under the root directory use `.` as the path:

```
|.:{README.md,CHANGELOG.md}
```

### Nested Directories

Use forward slashes for directory hierarchy:

```
|api/v2/endpoints:{users.md,posts.md,auth.md}
```

### Empty Directories

Directories containing no matching documentation files are omitted from the index.

### Sorting

- Entries are sorted alphabetically by directory path
- Files within each directory group are sorted alphabetically

## Complete Example

```
[Next.js Docs Index]|root: ./.next-docs|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning|01-app/01-getting-started:{01-installation.mdx,02-project-structure.mdx}|01-app/02-building:{01-layouts.mdx,02-pages.mdx,03-css.mdx}|02-api:{01-next-config.mdx,02-cli.mdx}
```

## Design Principles

1. **Minimal context consumption**: Only the index occupies context; full docs are read on demand
2. **Retrieval-first**: The `Prefer retrieval-led reasoning` directive prioritizes documentation
   over pre-training knowledge, which may be outdated or incomplete
3. **Structure preservation**: Maintains directory hierarchy to express relationships between documents
4. **Compression efficiency**: Pipe delimiters + grouping achieves ~40% token reduction vs newline-based format

## Supported File Types

Default file extensions scanned by `generate-index.sh`:

- `.md` - Markdown
- `.mdx` - MDX (Markdown + JSX)
- `.txt` - Plain text
- `.rst` - reStructuredText
- `.html` / `.htm` - HTML
- `.adoc` - AsciiDoc

## Placement in .claude/rules/

Save the generated index as `.claude/rules/docs/{product-name}-docs.md`.
Claude Code's rules system automatically loads it into context at session start.

### File Layout Example

```
project/
├── .claude/
│   └── rules/
│       └── docs/
│           └── react-docs.md    # Compressed index
├── .react-docs/                  # Documentation files
│   ├── guides/
│   │   ├── intro.md
│   │   └── setup.md
│   └── api/
│       └── hooks.md
└── src/
```

## Limitations

- File names containing commas (`,`), colons (`:`), or pipe characters (`|`) may break the format
- Very deep directory nesting produces long path strings, reducing compression benefit
- The format is line-oriented; it does not capture file metadata (size, last modified, etc.)
