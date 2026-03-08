#!/bin/bash
set -euo pipefail

# detect-and-lint.sh - Detect language and run appropriate linter
# Usage:
#   detect-and-lint.sh --git-diff           # lint changed files from git diff
#   detect-and-lint.sh file1.rs file2.rs    # lint specific files
#
# Output: linter results to stdout
# Exit 0: success (or no linter available)
# Exit 1: lint errors found

collect_files() {
  if [[ "${1:-}" == "--git-diff" ]]; then
    if git diff --name-only HEAD 2>/dev/null | head -1 | grep -q .; then
      git diff --name-only HEAD
    elif git diff --name-only 2>/dev/null | head -1 | grep -q .; then
      git diff --name-only
    else
      echo "No changed files detected" >&2
      exit 0
    fi
  else
    printf '%s\n' "$@"
  fi
}

detect_languages() {
  local langs=()
  while IFS= read -r file; do
    case "$file" in
      *.rs)           [[ " ${langs[*]:-} " != *" rust "* ]] && langs+=(rust) ;;
      *.py)           [[ " ${langs[*]:-} " != *" python "* ]] && langs+=(python) ;;
      *.js|*.ts|*.tsx) [[ " ${langs[*]:-} " != *" js "* ]] && langs+=(js) ;;
    esac
  done
  printf '%s\n' "${langs[@]}"
}

run_lint() {
  local lang="$1"
  local found_issues=false

  case "$lang" in
    rust)
      if command -v cargo >/dev/null 2>&1; then
        echo "=== Rust: cargo clippy ==="
        if ! cargo clippy -- -D warnings 2>&1; then
          found_issues=true
        fi
      else
        echo "=== Rust: cargo not found, skipping ==="
      fi
      ;;
    python)
      if command -v ruff >/dev/null 2>&1; then
        echo "=== Python: ruff check ==="
        if ! ruff check 2>&1; then
          found_issues=true
        fi
      else
        echo "=== Python: ruff not found, skipping ==="
      fi
      ;;
    js)
      if command -v npx >/dev/null 2>&1 && [ -f "node_modules/.bin/eslint" ]; then
        echo "=== JS/TS: eslint ==="
        if ! npx eslint . 2>&1; then
          found_issues=true
        fi
      else
        echo "=== JS/TS: eslint not found, skipping ==="
      fi
      ;;
  esac

  $found_issues && return 1 || return 0
}

# Main
files=$(collect_files "$@")
languages=$(echo "$files" | detect_languages)

if [[ -z "$languages" ]]; then
  echo "No supported source files found"
  exit 0
fi

overall_result=0
while IFS= read -r lang; do
  run_lint "$lang" || overall_result=1
done <<< "$languages"

exit $overall_result
