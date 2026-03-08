---
name: refine
description: >-
  Performs post-implementation code refinement by running language-appropriate
  linters and applying a focused semantic review to eliminate structural
  verbosity. This skill should be used after completing an implementation task.
  Trigger phrases include: "refine this code", "refine the code",
  "clean up the implementation", "simplify this code",
  "review what was written", "post-implementation review",
  "make this more concise", "reduce verbosity",
  or when the user requests code quality improvement on recently written code.
version: 0.1.0
---

# Refine

Apply post-implementation refinement: automated linting followed by
a focused semantic review to eliminate structural verbosity. This is
a separate review step from the writing step — reviewing code from
a fresh perspective catches patterns that self-review during writing misses.

## When to Use

- After completing an implementation task (new feature, bug fix, refactoring)
- When code was written by a subagent or teammate and needs quality review
- When the user requests simplification of recently written code
- As the final step before presenting implemented code to the user

## Workflow

### 1. Determine Scope

Identify target files in this order of priority:
1. Files explicitly specified by the user
2. Uncommitted changes: `git diff --name-only`
3. Changes since last commit: `git diff --name-only HEAD~1`

Filter to source code files only — skip configs, lockfiles, and generated files.

### 2. Run Linter

Execute the linting script to detect language and run the appropriate linter:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/refine/scripts/detect-and-lint.sh --git-diff
```

Or for specific files:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/refine/scripts/detect-and-lint.sh path/to/file.rs
```

If the linter reports issues, fix them before proceeding to semantic review.

### 3. Semantic Review

Read each target file and check against the patterns in
`${CLAUDE_PLUGIN_ROOT}/skills/refine/references/semantic-review-checklist.md`.

For each file:
1. Read the full file to understand context
2. Check each applicable pattern from the checklist
3. For every match found, apply the simplification directly
4. Do not pad — if no patterns match, move on

Focus on functions that were recently changed, but read the full file
for context.

### 4. Verify

After applying changes:
1. Re-run the linter to confirm no regressions
2. Run existing tests if available to confirm correctness
3. If tests fail, revert the problematic simplification

### 5. Report

Summarize what was changed:
- Number of linter issues fixed
- Semantic simplifications applied (list each with a one-line description)
- Lines of code before and after (if significant change)

## Important Rules

- **Do not change behavior.** Refinement must preserve the exact same
  observable behavior. If unsure whether a simplification changes behavior,
  skip it.
- **Do not add features.** Do not add error handling, documentation,
  tests, or functionality that was not in the original implementation.
- **Prefer smaller changes.** Multiple small, safe simplifications are
  better than one large refactor.
- **Respect the spec.** If the code follows a specification, ensure all
  simplifications still meet the specification requirements.
- **Skip when unnecessary.** If the code is already concise and idiomatic,
  say so and finish. Not every implementation needs refinement.
