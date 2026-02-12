#!/usr/bin/env bash

set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STRICT=false

while [[ $# -gt 0 ]]; do
	case "$1" in
	--strict)
		STRICT=true
		;;
	-h | --help)
		cat <<'EOF'
Usage: ./scripts/local-sast.sh [--strict]

Options:
  --strict   Exit non-zero if findings are reported
EOF
		exit 0
		;;
	*)
		echo "[sast] unknown option: $1" >&2
		exit 1
		;;
	esac
	shift
done

cd "$ROOT_DIR"

if ! command -v opengrep >/dev/null 2>&1; then
	echo "[sast] opengrep not found; install with: brew install opengrep" >&2
	exit 1
fi

echo "[sast] running opengrep (rules: .config/opengrep/rules.yml)"

results_file="$(mktemp)"
trap 'rm -f "$results_file"' EXIT

if ! opengrep scan \
	--config .config/opengrep/rules.yml \
	--no-error \
	--json-output "$results_file" \
	--exclude ".config/zsh/plugins/**" \
	--exclude ".config/opencode/**" \
	dot scripts/lib .config/zsh .config/aerospace/aerospace.toml; then
	echo "[sast] opengrep scan failed" >&2
	exit 1
fi

findings_count="$(
	python3 - "$results_file" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)

print(len(data.get('results', [])))
PY
)"

echo "[sast] findings: ${findings_count}"

if [[ "$findings_count" -gt 0 ]]; then
	if [[ "$STRICT" == "true" ]]; then
		echo "[sast] failing due to findings (--strict)"
		exit 1
	fi

	echo "[sast] findings detected (non-blocking mode)"
	exit 2
fi

echo "[sast] scan completed"
