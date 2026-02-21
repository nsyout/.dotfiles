#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

cd "$ROOT_DIR" || exit 1

blocking_failures=0
warnings=0
summary_lines=()

section() {
	echo
	echo "[qa] === $1 ==="
}

record_summary() {
	local check_name="$1"
	local status="$2"
	summary_lines+=("$check_name: $status")
}

run_blocking() {
	local check_name="$1"
	shift

	echo "[qa] -> $check_name"
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

	echo "[qa] -> $check_name (warn-only)"
	if "$@"; then
		record_summary "$check_name" "PASS"
	else
		record_summary "$check_name" "WARN"
		warnings=$((warnings + 1))
	fi
}

print_summary() {
	echo
	echo "[qa] === SUMMARY ==="
	for line in "${summary_lines[@]}"; do
		echo "  - $line"
	done
	echo "[qa] blocking failures: $blocking_failures | warnings: $warnings"
}

section "BLOCKING CHECKS"
run_blocking "shellcheck" shellcheck dot scripts/lib/*.sh scripts/*.sh scripts/pre-commit
run_blocking "bash syntax" bash -n dot scripts/lib/*.sh scripts/*.sh scripts/pre-commit
run_blocking "zsh syntax" zsh -n .config/zsh/.zshrc .config/zsh/.zshrc.d/*.zsh .config/zsh/*.zsh
run_blocking "dot help consistency" ./scripts/check-help-consistency.sh

run_blocking "aerospace config syntax" python3 - <<'PY'
import tomllib
from pathlib import Path

path = Path('.config/aerospace/aerospace.toml')
with path.open('rb') as f:
    tomllib.load(f)
print('[qa] aerospace.toml: ok')
PY

section "WARN-ONLY CHECKS"
if command -v shfmt >/dev/null 2>&1; then
	run_warn "shfmt" shfmt -d dot scripts/lib/*.sh scripts/*.sh scripts/pre-commit
else
	record_summary "shfmt" "WARN (missing: brew install shfmt)"
	warnings=$((warnings + 1))
fi

if command -v markdownlint-cli2 >/dev/null 2>&1; then
	run_warn "markdownlint-cli2" markdownlint-cli2 README.md
else
	record_summary "markdownlint-cli2" "WARN (missing: brew install markdownlint-cli2)"
	warnings=$((warnings + 1))
fi

if command -v opengrep >/dev/null 2>&1; then
	run_warn "opengrep sast" ./scripts/local-sast.sh
else
	record_summary "opengrep sast" "WARN (missing: brew install opengrep)"
	warnings=$((warnings + 1))
fi

section "SECRETS"
if command -v gitleaks >/dev/null 2>&1; then
	run_blocking "gitleaks working tree" gitleaks detect --no-git --redact
else
	record_summary "gitleaks working tree" "FAIL (missing: brew install gitleaks)"
	blocking_failures=$((blocking_failures + 1))
fi

print_summary

if [[ "$blocking_failures" -gt 0 ]]; then
	echo "[qa] failed"
	exit 1
fi

echo "[qa] passed"
