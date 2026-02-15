#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/check_headless_scene.sh"
"$SCRIPT_DIR/run_tests.sh"

# Warnings-only by default (use STRICT=1 to enforce).
"$SCRIPT_DIR/lint_architecture.sh"

echo "OK: lint gates complete"

