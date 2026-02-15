#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/_godot_env.sh
source "$SCRIPT_DIR/_godot_env.sh"

shopt -s nullglob

test_files=("$PROJECT_ROOT"/tests/*.gd)
if (( ${#test_files[@]} == 0 )); then
  echo "No tests found in tests/*.gd" >&2
  exit 0
fi

failures=0

script_error_re='(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script|Could not parse global class)'

for file in "${test_files[@]}"; do
  base="$(basename "$file")"
  name="${base%.gd}"
  script_path="res://tests/$base"
  log_file="$LOG_DIR/test_${name}.log"

  echo "[test] $script_path"

  if ! "$GODOT_BIN" \
    --headless \
    --path "$PROJECT_ROOT" \
    --quit \
    --script "$script_path" \
    --log-file "$log_file"; then
    echo "FAILED: $script_path" >&2
	    if [[ -f "$log_file" ]]; then
	      echo "--- log: $log_file ---" >&2
	      cat "$log_file" >&2
	    fi
	    failures=$((failures + 1))
	    continue
	  fi

	  # Godot may exit 0 even if it logged script parse errors.
	  if [[ -f "$log_file" ]] && grep -E -n "$script_error_re" "$log_file" >/dev/null; then
	    echo "FAILED: $script_path (script errors in log)" >&2
	    echo "--- log matches: $log_file ---" >&2
	    grep -E -n "$script_error_re" "$log_file" >&2 || true
	    echo "--- log tail: $log_file ---" >&2
	    tail -n 200 "$log_file" >&2 || true
	    failures=$((failures + 1))
	  fi
done

if (( failures > 0 )); then
  echo "FAILED: $failures test(s) failed" >&2
  exit 1
fi

echo "OK: all tests passed"
