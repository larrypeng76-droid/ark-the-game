# Project agent instructions (Godot 4.x)

## Compatibility
- Target Godot 4.5+ semantics.
- Use `process_mode` (not `pause_mode`), and `Node.PROCESS_MODE_WHEN_PAUSED` for UI that must work while paused.

## Naming and structure
- Use `snake_case` for files/folders, `PascalCase` for node names, and `class_name` only for globally reusable types.
- One scene, one root script. Keep scene logic self-contained and communicate via signals.

## Scenes and resources
- Do not invent UIDs in `.tscn` or `.tres` files.
- For new resources, use `ext_resource` with `path` only; allow Godot to assign UIDs when opened in the editor.

## GDScript typing
- Avoid implicit Variant inference that triggers warnings-as-errors.
- Prefer explicit types for intermediate variables when using `sign()` or other polymorphic functions.

## Input and physics
- Read input in `_input`/`_unhandled_input`, and keep movement/`move_and_slide()` in `_physics_process`.
- Prefer `@export` (or `@export_range`) for tunable values instead of hard-coded magic numbers.

## State machine (Player)
- Keep states lightweight: animation + transition checks only.
- Centralize shared movement/physics in `Player.gd`; avoid duplicating physics in states.
- Use `PlayerStateMachine.change_state()` for all transitions.
- Any non-movement/lockout state (land, hard-land, attack, hit-stun, etc.) must have a fail-safe exit:
  - If environment conditions invalidate the state (e.g., `not is_on_floor()`), immediately transition to `FallState`.
  - When timers end, re-check environment before choosing the next state; never stall on a single condition.
  - On exit, clear timers/flags that can keep the state locked.

## Combat and damage
- Only change player health via `Player.take_damage(amount)`.
- Use `Hitbox`/`Hurtbox` areas for combat; do not mix with direct `queue_free()` on the player.
- Keep collision layers consistent with `project.godot` naming: Player(1), Enemy(2), Terrain(3), PlayerAttack(4), EnemyAttack(5).

## Pause and UI
- If the game is paused, UI that must stay interactive should set `process_mode = Node.PROCESS_MODE_WHEN_PAUSED`.
- Avoid pausing for a transition if it needs to animate (use `process_mode` on the transition UI).

## Runtime checks
- After changes, run a headless scene load to catch script parse errors:
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lebupeng/Documents/games/godot-platformer --scene res://Game/Game.tscn --quit --verbose`

## Error handling
- If the editor or CLI reports a parse error, fix that first before additional edits.
