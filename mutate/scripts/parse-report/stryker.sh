#!/usr/bin/env bash
# Stryker mutation report parser
# Usage: stryker.sh <report.json> [max_mutants]
# Output: surviving mutants summary in structured text format

set -euo pipefail

REPORT="${1:?Usage: stryker.sh <report.json> [max_mutants]}"
MAX_MUTANTS="${2:-10}"

if [[ ! -f "$REPORT" ]]; then
  echo "Error: Report file not found: $REPORT" >&2
  exit 1
fi

# Extract summary and surviving mutants using node (available in any JS project)
node --input-type=module <<SCRIPT
import { readFileSync } from 'fs';

const report = JSON.parse(readFileSync('$REPORT', 'utf-8'));

let totalKilled = 0;
let totalSurvived = 0;
let totalNoCoverage = 0;
let totalTimeout = 0;
const surviving = [];

for (const [file, data] of Object.entries(report.files)) {
  for (const m of data.mutants) {
    if (m.status === 'Killed') totalKilled++;
    else if (m.status === 'Survived') totalSurvived++;
    else if (m.status === 'NoCoverage') totalNoCoverage++;
    else if (m.status === 'Timeout') totalTimeout++;

    if (m.status === 'Survived' || m.status === 'NoCoverage') {
      const lines = data.source.split('\n');
      const lineNum = m.location.start.line;
      const originalLine = lines[lineNum - 1]?.trim() || '';
      surviving.push({
        file,
        line: lineNum,
        mutatorName: m.mutatorName,
        replacement: m.replacement,
        status: m.status,
        originalLine,
        testsRan: (m.coveredBy || []).length,
      });
    }
  }
}

const total = totalKilled + totalSurvived + totalNoCoverage + totalTimeout;
const score = total > 0 ? ((totalKilled + totalTimeout) / total * 100).toFixed(2) : '0.00';

console.log('## Mutation Test Summary');
console.log('');
console.log('| Metric | Value |');
console.log('|--------|-------|');
console.log('| Mutation Score | ' + score + '% |');
console.log('| Killed | ' + totalKilled + ' |');
console.log('| Survived | ' + totalSurvived + ' |');
console.log('| NoCoverage | ' + totalNoCoverage + ' |');
console.log('| Timeout | ' + totalTimeout + ' |');
console.log('| Total | ' + total + ' |');
console.log('');

if (surviving.length === 0) {
  console.log('All mutants killed!');
  process.exit(0);
}

console.log('## Surviving Mutants (top ' + Math.min(surviving.length, ${MAX_MUTANTS}) + ' of ' + surviving.length + ')');
console.log('');

for (const m of surviving.slice(0, ${MAX_MUTANTS})) {
  console.log('### ' + m.file + ':' + m.line + ' [' + m.status + ']');
  console.log('- **Mutator**: ' + m.mutatorName);
  console.log('- **Original**: \`' + m.originalLine + '\`');
  console.log('- **Replacement**: \`' + m.replacement + '\`');
  console.log('- **Tests covering**: ' + m.testsRan);
  console.log('');
}
SCRIPT
