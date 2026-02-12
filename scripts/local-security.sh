#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUN_HISTORY=false
WARN_SAST=false
blocking_failures=0
warnings=0
summary_lines=()

section() {
	echo
	echo "[security] === $1 ==="
}

while [[ $# -gt 0 ]]; do
	case "$1" in
	--history)
		RUN_HISTORY=true
		;;
	--warn-sast)
		WARN_SAST=true
		;;
	-h | --help)
		cat <<'EOF'
Usage: ./scripts/local-security.sh [--history] [--warn-sast]

Options:
  --history   Also scan git history for leaked secrets
  --warn-sast Run SAST in warn mode (default is strict)
EOF
		exit 0
		;;
	*)
		echo "[security] unknown option: $1" >&2
		exit 1
		;;
	esac
	shift
done

cd "$ROOT_DIR" || exit 1

record_summary() {
	local check_name="$1"
	local status="$2"
	summary_lines+=("$check_name: $status")
}

run_blocking() {
	local check_name="$1"
	shift
	echo "[security] -> $check_name"
	if "$@"; then
		record_summary "$check_name" "PASS"
	else
		record_summary "$check_name" "FAIL"
		blocking_failures=$((blocking_failures + 1))
	fi
}

run_warn() {
	local check_name="$1"
	shift
	echo "[security] -> $check_name (warn-only)"
	if "$@"; then
		record_summary "$check_name" "PASS"
	else
		record_summary "$check_name" "WARN"
		warnings=$((warnings + 1))
	fi
}

if ! command -v gitleaks >/dev/null 2>&1; then
	record_summary "gitleaks" "FAIL (missing: brew install gitleaks)"
	blocking_failures=$((blocking_failures + 1))
else
	section "SECRETS"
	run_blocking "gitleaks working tree" gitleaks detect --no-git --redact

	if [[ "$RUN_HISTORY" == "true" ]]; then
		run_blocking "gitleaks git history" gitleaks git --redact
	else
		record_summary "gitleaks git history" "SKIP"
	fi
fi

if ! command -v opengrep >/dev/null 2>&1; then
	record_summary "opengrep sast" "FAIL (missing: brew install opengrep)"
	blocking_failures=$((blocking_failures + 1))
else
	section "SAST"
	if [[ "$WARN_SAST" == "true" ]]; then
		run_warn "opengrep sast" ./scripts/local-sast.sh
	else
		run_blocking "opengrep sast" ./scripts/local-sast.sh --strict
	fi
fi

echo
echo "[security] === SUMMARY ==="
for line in "${summary_lines[@]}"; do
	echo "  - $line"
done
echo "[security] blocking failures: $blocking_failures | warnings: $warnings"

if [[ "$blocking_failures" -gt 0 ]]; then
	echo "[security] failed"
	exit 1
fi

echo "[security] passed"
