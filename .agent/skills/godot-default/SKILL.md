---
name: godot-default
description: HDD-style default protocol for Godot 4.5+ work in this repo. Use for implement/debug/refactor/review of scenes, player state machine, combat, resources, and pause/UI behavior with strict architecture boundaries and mandatory validation gates.
---

# Godot Default Skill
> TYPE: STANDARD / ALGO
> STATUS: ACTIVE

## 1. AXIOM (CN logic + EN anchors)
- Boundary: `Scene = Module` (feature closed-loop: `scene + script + resources + tests`).
- Dependency: `game -> core` allowed; `core -> game` forbidden.
- Communication: use `signals` / `Area2D` (`Hitbox/Hurtbox`), forbid deep NodePath business poking.
- Flow ownership: scene switch/restart/menu only in `GameFlow`; `core/ui/**` emits request signals only.
- Pause semantics: use `process_mode`; paused-interactive UI => `Node.PROCESS_MODE_WHEN_PAUSED`.

## 2. CODE RULES (must)
- Naming: paths/files `snake_case`; node names `PascalCase`; `class_name` only for reusable global types.
- Input/Physics split: input in `_input` / `_unhandled_input`; movement + `move_and_slide()` in `_physics_process`.
- Tunables: prefer `@export` / `@export_range`; avoid magic numbers.
- Typing: avoid implicit `Variant`; avoid shadowing built-ins/members; float division intent must cast via `float(...)`.
- Annotation args must be separate params (e.g. `@export_file("*.png", "*.jpg")`).

## 3. PLAYER/COMBAT INVARIANTS
- State transition API: only `PlayerStateMachine.change_state()`.
- Lockout fail-safe:
  - env invalid (e.g. `not is_on_floor()`) => immediate `FallState`;
  - timer end => re-check env then choose next state;
  - on exit => clear lock timers/flags.
- HP mutation: only `Player.take_damage(amount)`.
- Combat boundary: `Hitbox/Hurtbox` only; no direct player `queue_free()` logic.
- Collision layers: Player(1), Enemy(2), Terrain(3), PlayerAttack(4), EnemyAttack(5).

## 4. RESOURCE RULES
- Do not invent UIDs in `.tscn/.tres`.
- `ext_resource` is path-first; if UID invalid/stale => remove UID, keep valid `path`.
- Keep path casing stable/consistent (prefer `snake_case`).

## 5. ALGO (delivery)
1. `Vertical Slice First`: deliver minimal playable loop in feature folder.
2. `Then Extract`: abstract shared components only after slice is stable.
3. `Boundary Check`: cross-module behavior must be via signals/Area2D.
4. `Fix Priority`: `Parse Error > Type/Warning > Visual Tuning`.

## 6. GATE (must pass before handoff)
- `./tools/lint.sh`
- Headless parse check:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lebupeng/Documents/games/godot-platformer --scene res://game/game.tscn --quit --verbose --log-file .godot/codex_logs/headless_scene.log`
- If log has errors: fix first `SCRIPT ERROR` in `.godot/codex_logs/headless_scene.log` before further edits.

## 7. RESPONSE FORMAT
- concise + actionable, no prose padding.
- code changes: list files + reason.
- review mode: findings first, severity ordered, include precise file/line refs.
