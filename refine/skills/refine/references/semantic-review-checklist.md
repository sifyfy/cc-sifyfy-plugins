# Semantic Review Checklist

Review each modified file against the patterns below.
For each applicable pattern found, apply the simplification directly.
Skip patterns irrelevant to the target language.

## Iterator Chain Simplification

- Manual loop collecting into a Vec → `.iter().map(...).collect()`
- Manual loop with conditional push → `.iter().filter(...).collect()`
- Manual loop accumulating a value → `.iter().fold(...)` / `.sum()` / `.product()`
- Nested loops building a flat collection → `.flat_map()`
- Manual key-dedup loop → `.collect::<BTreeSet<_>>()` or `.collect::<HashSet<_>>()`
- Manual contains-check before push → use a Set directly

## String Construction

- Sequential `push_str` / `push` / `+=` calls → single `format!()` macro
- String concatenation chain → `format!()` or `.join()`
- `format!("{}", x)` where `x.to_string()` or just `x` suffices → simplify

## Unnecessary Code

- Helper function called exactly once that does not improve readability → inline
- Intermediate variable that is assigned and immediately returned → return the expression directly
- Argument validation not required by specification → remove
- Usage/help messages not required by specification → remove
- Unreachable match arms or else branches → remove

## Repetitive Patterns

- Two or more code blocks with identical structure → extract shared logic
- Repeated `PathBuf::from(X).join(y)` → `format!()` or a shared helper (only if 3+ occurrences)
- Repeated error handling with identical messages → shared closure or function

## Type Annotations and Verbosity

- Explicit type annotations where inference is unambiguous → remove
- `String::from("x")` / `"x".to_string()` where `"x"` with `impl Into<String>` or `&str` suffices → use simpler form
- `return x;` at end of function → `x` (expression-oriented style)
- `.iter()` on a reference that already implements `IntoIterator` → remove `.iter()`

## Language-Specific

### Rust
- Verbose `match` on `Result`/`Option` where `?`, `map`, `and_then`, `unwrap_or_else` suffices → use combinator
- `if let Some(x) = opt { x } else { default }` → `opt.unwrap_or(default)`
- `.clone()` on a value that is not used after the clone point → remove clone, move instead
- `impl` block with only associated functions (no `self`) on a struct with no fields → use free functions

### Python
- Manual loop building a list → list comprehension
- `if x is not None:` guarding the only usage → use `x or default` / early return
- Manual dict construction from pairs → dict comprehension

### JS/TS
- `.forEach` with side effects that could be a `for...of` → `for...of`
- Manual promise chain where `async/await` is cleaner → `async/await`
- Verbose `if/else` returning values → ternary or nullish coalescing
