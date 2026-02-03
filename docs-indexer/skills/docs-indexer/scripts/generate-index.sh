#!/bin/bash
# generate-index.sh - Generate compressed documentation index
# Usage: generate-index.sh <source-dir> <index-name>
# Output: Pipe-delimited compressed index to stdout
#
# Example:
#   bash generate-index.sh ./.docs/next "Next.js" > index.txt

set -euo pipefail

SOURCE_DIR="${1:?Usage: generate-index.sh <source-dir> <index-name>}"
INDEX_NAME="${2:?Usage: generate-index.sh <source-dir> <index-name>}"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Directory '$SOURCE_DIR' does not exist" >&2
  exit 1
fi

# Normalize source dir (remove trailing slash)
SOURCE_DIR="${SOURCE_DIR%/}"

# Header
printf "[%s Docs Index]|root: %s" "$INDEX_NAME" "$SOURCE_DIR"
printf "|IMPORTANT: Prefer retrieval-led reasoning over pre-training-led reasoning"

# Collect directories and their files
# Use find to get all documentation files, grouped by directory
prev_dir=""
file_list=""

while IFS= read -r filepath; do
  dir="$(dirname "$filepath")"
  # Make dir relative to source
  rel_dir="${dir#"$SOURCE_DIR"}"
  rel_dir="${rel_dir#/}"
  [ -z "$rel_dir" ] && rel_dir="."

  filename="$(basename "$filepath")"

  if [ "$rel_dir" != "$prev_dir" ]; then
    # Flush previous directory
    if [ -n "$prev_dir" ]; then
      printf "|%s:{%s}" "$prev_dir" "$file_list"
    fi
    prev_dir="$rel_dir"
    file_list="$filename"
  else
    file_list="$file_list,$filename"
  fi
done < <(find "$SOURCE_DIR" -type f \( \
  -name "*.md" -o -name "*.mdx" -o -name "*.txt" -o -name "*.rst" \
  -o -name "*.html" -o -name "*.htm" -o -name "*.adoc" \
  \) | sort)

# Flush last directory
if [ -n "$prev_dir" ]; then
  printf "|%s:{%s}" "$prev_dir" "$file_list"
else
  echo "Warning: No documentation files found in '$SOURCE_DIR'" >&2
  echo "Supported extensions: .md .mdx .txt .rst .html .htm .adoc" >&2
fi

echo
