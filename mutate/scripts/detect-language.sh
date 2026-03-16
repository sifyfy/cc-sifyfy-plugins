#!/usr/bin/env bash
# Detect project language and mutation testing tool
# Usage: detect-language.sh [project_dir]
# Output: language\ttool\ttest_framework

set -euo pipefail

DIR="${1:-.}"

if [[ -f "$DIR/package.json" ]]; then
  # Check for test framework
  if grep -q '"vitest"' "$DIR/package.json" 2>/dev/null; then
    echo "typescript	stryker	vitest"
  elif grep -q '"jest"' "$DIR/package.json" 2>/dev/null; then
    echo "typescript	stryker	jest"
  else
    echo "typescript	stryker	unknown"
  fi
elif [[ -f "$DIR/Cargo.toml" ]]; then
  echo "rust	cargo-mutants	cargo-test"
elif [[ -f "$DIR/pyproject.toml" ]] || [[ -f "$DIR/setup.py" ]]; then
  echo "python	mutmut	pytest"
elif [[ -f "$DIR/go.mod" ]]; then
  echo "go	go-mutesting	go-test"
else
  echo "unknown	unknown	unknown"
fi
