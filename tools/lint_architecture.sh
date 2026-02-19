#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/_godot_env.sh
source "$SCRIPT_DIR/_godot_env.sh"

STRICT="${STRICT:-0}"
warnings=0

warn() {
  echo "WARN: $*" >&2
  warnings=$((warnings + 1))
}

check_rg() {
  if ! command -v rg >/dev/null 2>&1; then
    echo "ERROR: rg (ripgrep) not found. Install it or skip lint_architecture." >&2
    exit 2
  fi
}

check_rg

# Rule: prefer process_mode; do not use pause_mode.
# Scope to real engine files to avoid false positives in docs/AGENTS/tools.
if rg -n \
  --glob '*.gd' \
  --glob '*.tscn' \
  --glob 'project.godot' \
  -- "pause_mode" "$PROJECT_ROOT" >/dev/null; then
  warn "Found 'pause_mode' usage; use 'process_mode' instead."
  rg -n \
    --glob '*.gd' \
    --glob '*.tscn' \
    --glob 'project.godot' \
    -- "pause_mode" "$PROJECT_ROOT" >&2 || true
fi

# Rule: Core must not reference Game resources directly.
if rg -n -- "res://game/" "$PROJECT_ROOT/core" >/dev/null; then
  warn "Found 'res://game/' reference(s) inside core/. Consider moving code to game/ or injecting dependencies."
  rg -n -- "res://game/" "$PROJECT_ROOT/core" >&2 || true
fi

# Rule: core/ui must not reference GameFlow directly.
if rg -n --glob '*.gd' -- "\\bGameFlow\\b|res://game/flow/|game_flow_manager\\.gd" "$PROJECT_ROOT/core/ui" >/dev/null; then
  warn "core/ui must not reference GameFlow directly; UI should emit signals only."
  rg -n --glob '*.gd' -- "\\bGameFlow\\b|res://game/flow/|game_flow_manager\\.gd" "$PROJECT_ROOT/core/ui" >&2 || true
fi

# Soft check: forbid legacy-cased resource paths in repo-tracked files.
# (Cache files are guarded by tests; this is just a quick local reminder.)
if rg -n \
  --glob '*.gd' \
  --glob '*.tscn' \
  --glob '*.tres' \
  --glob 'project.godot' \
  -- "res://Core/|res://Game/" "$PROJECT_ROOT" \
  | rg -v -- "tests/zz_global_script_class_cache_" \
  | rg -v -- "tests/zz_global_script_classes_registry_test\.gd" \
  >/dev/null; then
  warn "Found legacy-cased path(s) (res://Core/ or res://Game/) in repo files; use res://core/ and res://game/."
  rg -n \
    --glob '*.gd' \
    --glob '*.tscn' \
    --glob '*.tres' \
    --glob 'project.godot' \
    -- "res://Core/|res://Game/" "$PROJECT_ROOT" \
    | rg -v -- "tests/zz_global_script_class_cache_" \
    | rg -v -- "tests/zz_global_script_classes_registry_test\.gd" \
    >&2 || true
fi

# Soft check: Core mentioning concrete Game entity types (warn-only by default).
# Use STRICT=1 to fail.
if rg -n --glob '*.gd' -- "\\b(Player|Zombie|Shooter)\\b" "$PROJECT_ROOT/core" \
  >/dev/null; then
  warn "core/ mentions concrete Game entity type(s) (Player/Zombie/Shooter). Consider decoupling or moving to game/."
  rg -n --glob '*.gd' -- "\\b(Player|Zombie|Shooter)\\b" "$PROJECT_ROOT/core" \
    >&2 || true
fi

# Turret P0 rule: placement authority must route through TurretManager.
if rg -n -- "TempTurretScene\\.instantiate\\(" "$PROJECT_ROOT/game/player/player.gd" >/dev/null; then
  warn "Player must not instantiate TempTurret directly; route via TurretManager.place_turret_at_world()."
  rg -n -- "TempTurretScene\\.instantiate\\(" "$PROJECT_ROOT/game/player/player.gd" >&2 || true
fi

# Turret P0 rule: manager + rule entrypoints must exist.
if ! rg -n -- "func can_place_turret_at_world\\(" "$PROJECT_ROOT/game/features/turret/turret_manager.gd" >/dev/null; then
  warn "Missing TurretManager.can_place_turret_at_world() entrypoint."
fi
if ! rg -n -- "func can_place_turret\\(" "$PROJECT_ROOT/game/features/turret/turret_rules.gd" >/dev/null; then
  warn "Missing TurretRules.can_place_turret() constraint entrypoint."
fi

if (( warnings == 0 )); then
  echo "OK: architecture lint (no warnings)"
  exit 0
fi

echo "Architecture lint: $warnings warning(s)" >&2

if [[ "$STRICT" == "1" ]]; then
  echo "STRICT=1 enabled; failing due to warnings" >&2
  exit 1
fi

exit 0
