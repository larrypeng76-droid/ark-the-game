#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GODOT_BIN_DEFAULT="/Applications/Godot.app/Contents/MacOS/Godot"
GODOT_BIN="${GODOT_BIN:-$GODOT_BIN_DEFAULT}"

LOG_DIR_DEFAULT="$PROJECT_ROOT/.godot/codex_logs"
LOG_DIR="${GODOT_LOG_DIR:-$LOG_DIR_DEFAULT}"

mkdir -p "$LOG_DIR"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "ERROR: GODOT_BIN is not executable: $GODOT_BIN" >&2
  echo "Set GODOT_BIN=/path/to/Godot (default: $GODOT_BIN_DEFAULT)" >&2
  exit 2
fi

export PROJECT_ROOT
export GODOT_BIN
export LOG_DIR

# Godot 4.x caches resource UIDs and global script classes under .godot/.
# If files are renamed/moved outside the editor, those caches can go stale and
# cause case-mismatch warnings or script parse errors in headless runs.
#
# For deterministic gates, default to cleaning these caches. Opt out with:
#   GODOT_KEEP_CACHES=1 ./tools/lint.sh
if [[ "${GODOT_KEEP_CACHES:-0}" != "1" ]]; then
  rm -f \
    "$PROJECT_ROOT/.godot/uid_cache.bin" \
    "$PROJECT_ROOT/.godot/scene_groups_cache.cfg" \
    2>/dev/null || true

  # Editor-side caches can pin old-cased paths (e.g. Core/ vs core/) on
  # case-insensitive filesystems after bulk renames. Clearing them makes
  # headless runs rebuild from the actual on-disk layout.
  rm -rf "$PROJECT_ROOT/.godot/editor" 2>/dev/null || true
fi

# Optional: force-clean global script class cache.
# Usually we keep this file so `class_name` resolution is stable across runs,
# and rely on tests to ensure it never contains legacy-cased paths.
if [[ "${GODOT_CLEAN_GLOBAL_CLASSES:-0}" == "1" ]]; then
  rm -f "$PROJECT_ROOT/.godot/global_script_class_cache.cfg" 2>/dev/null || true
fi
