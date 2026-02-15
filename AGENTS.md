# Project agent instructions (Godot 4.x)

## Compatibility
- Target Godot 4.5+ semantics.
- Use `process_mode` (not `pause_mode`), and `Node.PROCESS_MODE_WHEN_PAUSED` for UI that must work while paused.

## Naming and structure
- Use `snake_case` for files/folders, `PascalCase` for node names, and `class_name` only for globally reusable types.
- One scene, one root script. Keep scene logic self-contained and communicate via signals.

## Architecture / 架构（Feature-closed loop）

- CN: 以 Scene 作为模块边界；每个功能在独立目录自闭环（scene + script + resources + tests）。
  EN: Use scenes as module boundaries; each feature folder is self-contained.
- CN: 依赖方向清晰：`game/` 可以依赖 `core/`；`core/` 不得依赖 `game/`（避免 `res://game/...` 或具体实体类型耦合）。
  EN: Dependency direction: `Core` must not depend on `Game`.
- CN: 跨模块通信优先 signals / Area2D（Hitbox/Hurtbox）；禁止跨模块深链 `get_node("A/B/C")` 访问内部节点做业务逻辑。
  EN: Prefer signals/Area2D boundaries; no deep NodePath poking across modules.
- CN: Autoload 最少但稳定；新增 Autoload 必须在文档登记职责与对外 API。
  EN: Keep autoloads minimal and documented.

- CN: 场景切换/重开/回主菜单必须集中在 `GameFlow`（或明确的 Flow 层）。`core/ui/**` 不得硬编码场景路径或直接切场景，只能通过 signals 请求。
  EN: Scene changes must be centralized in `GameFlow` (or an explicit Flow layer). `core/ui/**` must not hardcode scene paths or change scenes; it should only emit signals.

See: `docs/core/architecture_consensus.md`

## Feature workflow / 功能开发流程

- CN: 新功能先做最小可玩闭环（vertical slice），再抽象为可复用模块/组件。
  EN: Build a vertical slice first, then extract shared pieces.
- CN: 交付前运行基础 gate：`./tools/lint.sh`
  EN: Run the basic gates before shipping: `./tools/lint.sh`.

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
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path /Users/lebupeng/Documents/games/godot-platformer --scene res://game/game.tscn --quit --verbose --log-file .godot/codex_logs/headless_scene.log`

  Note: In this Codex sandbox, Godot headless must use `--log-file` (otherwise it may crash trying to write to `user://logs`).

- Recommended: `./tools/lint.sh`

## Error handling
- If the editor or CLI reports a parse error, fix that first before additional edits.
