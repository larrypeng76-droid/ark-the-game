#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[scan] lint"
"$SCRIPT_DIR/lint.sh"

echo "OK: pre-commit scan complete"
