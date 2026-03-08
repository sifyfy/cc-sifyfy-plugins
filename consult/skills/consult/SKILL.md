---
name: consult
description: >-
  Performs a pre-implementation consulting analysis on work requests before
  writing any code. This skill MUST be triggered whenever the user gives a
  work instruction, task request, bug fix request, refactoring request,
  feature request, or any request that would lead to code changes or
  creation of new artifacts (rules, skills, hooks, configuration, etc.).
  This includes both imperative instructions AND questions that describe
  a problem to be solved — if the answer likely involves implementation,
  this skill applies.
  Trigger phrases include: "fix this", "add a feature", "refactor",
  "implement", "change this to", "update", "modify", "create",
  "move this", "extract", "rename", "optimize", "improve",
  "there's a bug", "this doesn't work", "make it so that",
  "how do I prevent", "how should I solve", "how to avoid",
  "I want to stop X from happening", "X is a problem, what should I do",
  or any imperative or problem statement requesting a change.
  Do NOT trigger for questions that seek only explanations, information,
  or understanding with no implication of implementation (e.g.,
  "what does this function do?", "explain how X works").
version: 0.1.0
---

# Consult

Analyze a work request from the requirements layer down through each
abstraction level before committing to implementation. The goal is to
identify the most appropriate intervention layer — which may be higher
or lower than what the user explicitly requested.

## Why This Phase Exists

Users often frame requests at a specific abstraction level ("add a null
check here", "redesign this module") based on their current understanding.
The actual best intervention may be at a completely different level:
a design-level request might be solved with a one-line fix, or a
one-line fix request might reveal a design flaw. This phase prevents
anchoring to the instruction's framing.

## Workflow

### 1. Capture the Request

Restate the user's request neutrally without adopting its framing.
Identify:
- The **observable problem or goal** (what the user actually wants to achieve)
- The **intervention level implied** by the user's wording
- Any **assumptions embedded** in the request

### 2. Investigate the Context

Before analyzing layers, gather sufficient understanding:
- Read the relevant code, tests, and surrounding modules
- Understand the current behavior vs. desired behavior
- Check for existing patterns, conventions, and constraints in the codebase

### 3. Layer-by-Layer Analysis (Top-Down)

Starting from the requirements layer, descend through each level.
At every layer, evaluate whether a viable solution exists and what the
tradeoffs would be. Skip layers that are clearly irrelevant, but do not
skip a layer just because the user's request didn't mention it.

**Layer definitions (descend in this order):**

#### Requirements / Purpose
- Is the stated goal the right goal? Could the underlying need be met differently?
- Are there unstated requirements or constraints that change the problem?

#### Architecture
- Does the solution require structural changes across multiple modules or systems?
- Would an architectural change prevent this class of problem entirely?

#### Design / Interface
- Can the problem be solved by changing how modules interact, APIs are shaped, or responsibilities are assigned?
- Would a design change improve the situation without broader architectural impact?

#### Module / Component
- Is there a localized change within a single module or component that resolves the issue?
- Does the module's internal structure need adjustment?

#### Function / Method
- Can the problem be solved by modifying, extracting, or reorganizing a single function?

#### Line-Level Fix
- Is a minimal, targeted edit (a few lines) sufficient to address the problem correctly?

### 4. Present Findings

Output a structured analysis. For each relevant layer:

```
## Layer: [layer name]

**Viable:** Yes / No / Partially
**Proposal:** [concise description of what would be done at this layer]
**Tradeoffs:** [benefits and costs of intervening at this layer]
```

After all layers, provide:

```
## Recommendation

**Recommended layer:** [layer name]
**Rationale:** [why this layer is the best intervention point]
```

### 5. Await Confirmation

After presenting the analysis, explicitly ask the user which layer
to proceed with. Do not begin implementation until the user confirms.

After implementation is complete, consider running `/refine` for
post-implementation review (linting + structural simplification).

## Important Rules

- **Do not anchor to the user's framing.** The user's wording suggests a
  layer, but the analysis must be independent of that suggestion.
- **Lower layers can be correct.** A request phrased at the design level
  may genuinely be best solved with a 2-line fix. Do not artificially
  elevate the scope.
- **Higher layers can be correct.** A request for a small fix may reveal
  a systemic issue. Surface it, but let the user decide.
- **Be concise at irrelevant layers.** If a layer has no viable or
  useful solution, a single line ("No meaningful intervention at this
  layer") is sufficient. Do not pad the analysis.
- **Preserve the user's agency.** Present options and tradeoffs;
  do not dictate. The user may have context (timeline, priorities,
  risk tolerance) that changes which layer is appropriate.
- **This phase replaces, not delays, implementation.** The analysis
  should be fast and focused. It is not a lengthy design document —
  it is a structured sanity check.
