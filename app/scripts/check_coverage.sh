#!/usr/bin/env bash
# check_coverage.sh — Fails if LCOV line coverage falls below 40%.

set -euo pipefail

THRESHOLD=40
COVERAGE_FILE="coverage/lcov.info"

if [ ! -f "$COVERAGE_FILE" ]; then
  echo "ERROR: $COVERAGE_FILE not found. Run 'flutter test --coverage' first."
  exit 1
fi

# Sum total lines found (LF) and lines hit (LH) from the lcov report
LINES_FOUND=$(grep -Po 'LF:\K[0-9]+' "$COVERAGE_FILE" | awk '{s+=$1} END {print s}')
LINES_HIT=$(grep -Po 'LH:\K[0-9]+' "$COVERAGE_FILE" | awk '{s+=$1} END {print s}')

if [ -z "$LINES_FOUND" ] || [ "$LINES_FOUND" -eq 0 ]; then
  echo "ERROR: No coverage data found in $COVERAGE_FILE"
  exit 1
fi

COVERAGE=$(awk "BEGIN { printf \"%.1f\", ($LINES_HIT / $LINES_FOUND) * 100 }")
echo "Coverage: ${COVERAGE}% (${LINES_HIT}/${LINES_FOUND} lines) — threshold: ${THRESHOLD}%"

if (( $(awk "BEGIN { print ($COVERAGE < $THRESHOLD) }") )); then
  echo "FAIL: Coverage ${COVERAGE}% is below the ${THRESHOLD}% threshold."
  exit 1
fi

echo "PASS: Coverage meets the threshold."
