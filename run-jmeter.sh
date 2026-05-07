#!/usr/bin/env sh
set -eu

JMETER_BIN="${JMETER_BIN:-jmeter}"
TEST_PLAN="${TEST_PLAN:-/tests/test.jmx}"
RESULTS_FILE="${RESULTS_FILE:-/results/results.jtl}"
LOG_FILE="${LOG_FILE:-/results/jmeter.log}"

if [ "${1:-}" != "" ]; then
  TEST_PLAN="$1"
  shift
fi

if [ ! -f "$TEST_PLAN" ]; then
  echo "Test plan not found: $TEST_PLAN" >&2
  exit 1
fi

mkdir -p "$(dirname "$RESULTS_FILE")" "$(dirname "$LOG_FILE")"

exec "$JMETER_BIN" -n -t "$TEST_PLAN" -l "$RESULTS_FILE" -j "$LOG_FILE" "$@"
