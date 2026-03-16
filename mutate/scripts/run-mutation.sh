#!/usr/bin/env bash
# Run mutation testing for detected language
# Usage: run-mutation.sh <tool> <mutate_target> [report_output_dir]
# Requires: the appropriate mutation testing tool to be installed

set -euo pipefail

TOOL="${1:?Usage: run-mutation.sh <tool> <mutate_target> [report_output_dir]}"
TARGET="${2:?Mutate target is required}"
REPORT_DIR="${3:-reports}"

mkdir -p "$REPORT_DIR"

case "$TOOL" in
  stryker)
    # Check if stryker config exists, create minimal one if not
    if [[ ! -f stryker.config.json ]]; then
      cat > stryker.config.json <<EOF
{
  "testRunner": "vitest",
  "mutate": ["$TARGET"],
  "reporters": ["clear-text", "json"],
  "jsonReporter": { "fileName": "$REPORT_DIR/mutation.json" }
}
EOF
    else
      # Update mutate target in existing config using node
      node -e "
        const fs = require('fs');
        const config = JSON.parse(fs.readFileSync('stryker.config.json', 'utf-8'));
        config.mutate = ['$TARGET'];
        config.reporters = config.reporters || [];
        if (!config.reporters.includes('json')) config.reporters.push('json');
        config.jsonReporter = { fileName: '$REPORT_DIR/mutation.json' };
        fs.writeFileSync('stryker.config.json', JSON.stringify(config, null, 2));
      "
    fi
    npx stryker run
    echo "$REPORT_DIR/mutation.json"
    ;;

  cargo-mutants)
    cargo mutants --output "$REPORT_DIR" -- "$TARGET"
    echo "$REPORT_DIR"
    ;;

  mutmut)
    mutmut run --paths-to-mutate "$TARGET"
    mutmut results > "$REPORT_DIR/mutation.txt"
    echo "$REPORT_DIR/mutation.txt"
    ;;

  go-mutesting)
    go-mutesting "$TARGET" > "$REPORT_DIR/mutation.txt" 2>&1
    echo "$REPORT_DIR/mutation.txt"
    ;;

  *)
    echo "Error: Unknown tool: $TOOL" >&2
    exit 1
    ;;
esac
