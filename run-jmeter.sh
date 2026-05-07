#!/usr/bin/env sh
set -eu

JMETER_BIN="${JMETER_BIN:-jmeter}"
TEST_PLAN="${TEST_PLAN:-/tests/test.jmx}"
RESULTS_FILE="${RESULTS_FILE:-/results/results.csv}"
LOG_FILE="${LOG_FILE:-/results/jmeter.log}"
RESULTS_FORMAT="${RESULTS_FORMAT:-csv}"
GENERATE_HTML_REPORT="${GENERATE_HTML_REPORT:-false}"
HTML_REPORT_DIR="${HTML_REPORT_DIR:-/results/html-report}"

if [ "${1:-}" != "" ]; then
  TEST_PLAN="$1"
  shift
fi

if [ ! -f "$TEST_PLAN" ]; then
  echo "Test plan not found: $TEST_PLAN" >&2
  exit 1
fi

mkdir -p "$(dirname "$RESULTS_FILE")" "$(dirname "$LOG_FILE")"

set -- -n -t "$TEST_PLAN" -l "$RESULTS_FILE" -j "$LOG_FILE" "$@"
set -- "$@" "-Jjmeter.save.saveservice.output_format=${RESULTS_FORMAT}"

case "$(printf "%s" "${GENERATE_HTML_REPORT}" | tr "[:upper:]" "[:lower:]")" in
  1|true|yes|y)
    if [ "${HTML_REPORT_DIR}" = "/" ] || [ "${HTML_REPORT_DIR}" = "" ]; then
      echo "Invalid HTML report directory: ${HTML_REPORT_DIR}" >&2
      exit 1
    fi
    rm -rf "${HTML_REPORT_DIR}"
    set -- "$@" -e -o "${HTML_REPORT_DIR}"
    ;;
esac

exec "$JMETER_BIN" "$@"
