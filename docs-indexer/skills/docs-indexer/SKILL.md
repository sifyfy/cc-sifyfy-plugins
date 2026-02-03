---
name: docs-indexer
description: >-
  Generates compressed documentation indexes from local directories or URLs
  and deploys them as .claude/rules/ files for persistent AI agent context.
  This skill should be used when the user asks to "create a documentation index",
  "generate docs index", "index documentation", "add docs to context",
  "create agents.md style index", "compress documentation for AI",
  "download and index docs", "make docs available to Claude",
  or wants to make external documentation available as compressed context
  for AI coding agents.
version: 0.1.0
---

# Documentation Indexer

Generate compressed documentation indexes from arbitrary sources (local directories or URLs)
and deploy them as `.claude/rules/` files for persistent AI agent context.

Based on the compressed index format from Vercel's AGENTS.md evaluation,
where doc indexes achieved 100% pass rate vs 53% baseline without documentation.

## When to Use

- Adding third-party library/framework documentation as persistent context
- Making project-internal documentation available to the AI agent
- Converting any documentation tree into a compressed, token-efficient index

## Workflow

### Source: Local Directory

1. Confirm the source directory path and a short product name with the user
2. Copy documentation files to project-local directory `.docs/{product-name}/`
   - Preserve the original directory structure
   - Copy only documentation files (`.md`, `.mdx`, `.txt`, `.rst`, `.html`, `.htm`, `.adoc`)
   - Skip non-documentation files (images, binaries, config files)
3. Run the index generation script:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/docs-indexer/scripts/generate-index.sh ./.docs/{product-name} "{Product Name}"
   ```
4. Capture the stdout output and save it to `.claude/rules/docs/{product-name}-docs.md`
5. Verify the generated index (see Verification section below)

### Source: URL (Web Documentation)

1. Confirm the documentation URL and a short product name with the user
2. Analyze the documentation site structure:
   - Fetch the docs root/index page first using WebFetch
   - Look for sitemap.xml, navigation menus, or table of contents
   - Identify the documentation hierarchy (sections, subsections)
3. Plan and execute the download strategy:
   - Prioritize: API references, getting-started guides, core concepts
   - For large sites (>100 pages), ask the user which sections to include
   - Fetch pages in batches; if WebFetch fails on a page, skip it and note the failure
   - Convert HTML content to clean markdown, removing navigation, footers, and ads
4. Save fetched content as markdown files in `.docs/{product-name}/`:
   - Mirror the site's URL structure as directory hierarchy
   - Use descriptive filenames derived from page titles
   - Example: `/docs/api/hooks` -> `api/hooks.md`
5. Run the index generation script:
   ```bash
   bash ${CLAUDE_PLUGIN_ROOT}/skills/docs-indexer/scripts/generate-index.sh ./.docs/{product-name} "{Product Name}"
   ```
6. Capture the stdout output and save it to `.claude/rules/docs/{product-name}-docs.md`

### Post-Generation

After generating the index:
- Add `.docs/` to `.gitignore` if documentation should not be committed
- Add `.claude/rules/docs/` to `.gitignore` if the generated index should not be committed
- Inform the user that the index is active and will be loaded in future sessions
- Explain that the AI agent will now prefer reading actual docs over relying on training data

## Verification

After generating an index, verify its correctness:

1. **File count check**: Compare the number of files listed in the index against the actual
   file count in the docs directory. Run `find .docs/{product-name} -type f | wc -l`
   and compare with the comma-separated entries in the index.
2. **Path validity**: Spot-check 2-3 file paths from the index. Read the files to confirm
   they exist and contain meaningful documentation content.
3. **Structure review**: Confirm the directory grouping in the index reflects the logical
   structure of the documentation (e.g., API docs grouped together, guides grouped together).
4. **Index size**: The index should typically be 1-8KB. If significantly larger, the documentation
   set may be too broad; consider narrowing the scope.

If the script outputs only the header with no file entries, the source directory likely contains
no files matching the supported extensions. Verify the file types in the source directory.

## Error Handling

### Script Failures

- **"Directory does not exist"**: The source path is incorrect. Verify the path and retry.
- **Empty output (header only)**: No matching documentation files found. Check file extensions
  in the source directory. The script searches for: `.md`, `.mdx`, `.txt`, `.rst`, `.html`, `.htm`, `.adoc`.
- **Permission errors**: Ensure read access to the source directory and write access to the output location.

### URL Fetch Failures

- **WebFetch returns error**: The URL may be behind authentication. Ask the user for alternative
  access methods (e.g., local clone of a docs repository, downloaded archive).
- **Redirect responses**: Follow the redirect URL and retry with the new URL.
- **Rate limiting**: Space out requests. For large documentation sites, download over multiple
  rounds rather than all at once.
- **Incomplete content**: Some pages may return partial content. Note any incomplete pages
  to the user and offer to retry or skip them.

### Output Issues

- **`.claude/rules/docs/` directory does not exist**: Create it with `mkdir -p .claude/rules/docs/`.
- **Existing index file**: Ask the user whether to overwrite or create with a different name.

## Index Format

The compressed format uses pipe delimiters instead of newlines for token efficiency:

```
[Product Docs Index]|root: ./.docs/product|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning|dir:{file1.md,file2.md}|dir/sub:{file3.md}
```

For the complete format specification including delimiter rules, edge cases, and design
principles, consult `references/index-format.md`.

## Scripts

### generate-index.sh

**Location**: `${CLAUDE_PLUGIN_ROOT}/skills/docs-indexer/scripts/generate-index.sh`

**Usage**:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/docs-indexer/scripts/generate-index.sh <source-dir> <index-name>
```

**Arguments**:
- `source-dir`: Path to the documentation directory (relative or absolute)
- `index-name`: Human-readable product name for the index header (e.g., "React", "Next.js")

**Output**: Compressed pipe-delimited index string to stdout. Redirect to save:
```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/docs-indexer/scripts/generate-index.sh ./docs "MyLib" > .claude/rules/docs/mylib-docs.md
```

**Supported file types**: `.md`, `.mdx`, `.txt`, `.rst`, `.html`, `.htm`, `.adoc`

**Requirements**: Bash-compatible shell (Git Bash on Windows, bash on macOS/Linux).
The script uses process substitution (`< <(...)`) which requires bash, not sh.

## Output Structure

```
project/
├── .claude/
│   └── rules/
│       └── docs/
│           └── {product-name}-docs.md   # Compressed index (auto-loaded by Claude Code)
├── .docs/                            # Documentation files (referenced by index)
│   └── {product-name}/
│   ├── getting-started/
│   │   └── installation.md
│   └── api/
│       └── reference.md
└── ...
```

## Important Notes

- Keep `.docs/` in the project root so the agent can read referenced files
- The index is small (~1-8KB) but enables access to unlimited documentation
- For large documentation sites (>100 pages), prioritize the most relevant sections
  and ask the user to select which areas to index
- URL-based fetching may require multiple rounds; focus on API references and guides first
- The `IMPORTANT: Prefer retrieval-led reasoning` directive in the index header ensures the agent
  reads actual documentation files rather than relying on potentially outdated training data

## Additional Resources

### Reference Files

- **`references/index-format.md`** - Detailed specification of the compressed index format,
  delimiter rules, design principles, and complete examples
