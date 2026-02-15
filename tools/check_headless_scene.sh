#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/_godot_env.sh
source "$SCRIPT_DIR/_godot_env.sh"

SCENE_PATH="${1:-res://game/game.tscn}"
LOG_FILE="$LOG_DIR/headless_scene.log"

echo "[headless] Loading scene: $SCENE_PATH"

if ! "$GODOT_BIN" \
  --headless \
  --path "$PROJECT_ROOT" \
  --scene "$SCENE_PATH" \
  --quit \
  --verbose \
  --log-file "$LOG_FILE"; then
  echo "FAILED: headless scene load: $SCENE_PATH" >&2
  if [[ -f "$LOG_FILE" ]]; then
    echo "--- log: $LOG_FILE ---" >&2
    cat "$LOG_FILE" >&2
  fi
  exit 1
fi

# Godot may exit 0 even if it logged script parse errors.
if [[ -f "$LOG_FILE" ]] && grep -E -n \
  "(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script|Could not parse global class)" \
  "$LOG_FILE" \
  >/dev/null; then
  echo "FAILED: headless scene load logged script errors: $SCENE_PATH" >&2
  echo "--- log matches: $LOG_FILE ---" >&2
  grep -E -n \
    "(SCRIPT ERROR:|Parse Error:|ERROR: Failed to load script|Could not parse global class)" \
    "$LOG_FILE" \
    >&2 || true
  echo "--- log tail: $LOG_FILE ---" >&2
  tail -n 200 "$LOG_FILE" >&2 || true
  exit 1
fi

echo "OK: headless scene load"
