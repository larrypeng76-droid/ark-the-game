# AGENTS (Godot 4.x, HDD)

> TYPE: EXECUTION CONTRACT / HDD
> GOAL: 中文高密逻辑 + 英文锚点；`InfoDensity↑ Ambiguity↓ TokenCost↓`。

## 1. AXIOM
- 模块边界: `Scene = Module`（feature 目录自闭环：`scene + script + resources + tests`）。
- 依赖方向: `game -> core` `ALLOW`；`core -> game` `FORBID`。
- 通信边界: 跨模块优先 `signals` / `Area2D(Hitbox/Hurtbox)`；业务深链节点访问 `FORBID`。
- 场景流归属: `change/restart/menu` only `GameFlow`。

## 2. CONSTRAINTS
- 引擎语义: Godot `4.5+`; use `process_mode`, never `pause_mode`。
- 暂停交互: pause 下可交互 UI 必须 `Node.PROCESS_MODE_WHEN_PAUSED`。
- 输入/物理: `_input/_unhandled_input` 读输入；`_physics_process + move_and_slide()` 处理运动。
- 参数配置: `@export/@export_range` `MUST`; magic number `MINIMIZE`。
- 类型规则: 隐式 `Variant`、built-in/member shadowing、意外整除 `FORBID`。
- 浮点意图: `float(...)` 显式转换 `MUST`。
- 资源规则: `.tscn/.tres` 手写 UID `FORBID`; `ext_resource` path-first。
- 碰撞层契约: Player(1), Enemy(2), Terrain(3), PlayerAttack(4), EnemyAttack(5)。
- 状态迁移入口: only `PlayerStateMachine.change_state()`。
- Lockout fail-safe: env invalid => `FallState`; timer end => re-check; exit => clear locks。
- 生命入口: only `Player.take_damage(amount)`。
- 伤害链路: keep `Hitbox -> Hurtbox.hit() -> owner.take_damage()`。

## 3. ALGO (Delivery)
1. `Vertical Slice First` -> 先最小可玩闭环。
2. `Then Extract` -> 稳定后抽象复用。
3. `Boundary Check` -> 逐项核对依赖/通信/场景流边界。
4. `Fix Priority` -> `Parse Error > Type/Warning > Visual Tuning`。

## 4. GATE (Must Pass)
- 开发与提交前统一执行: `./tools/lint.sh`。
- Pre-commit 已接入: `.githooks/pre-commit -> tools/pre_commit_scan.sh -> tools/lint.sh`。

## 5. DELIVERABLE
- 代码交付必须同时满足: 规则一致 + gate 通过 + 必要文档同步。
- 架构级变更必须同步更新: `docs/core/architecture_contract.md`。

## 6. REFERENCE
- 完整架构契约: `docs/core/architecture_contract.md`。
- 架构共识背景: `docs/core/architecture_consensus.md`。

## 7. SKILL ROUTING
- 默认执行: `godot-default`（`.agent/skills/godot-default/SKILL.md`）。
- 规划/规格/评审/解释: 叠加 `hdd-prompt-engineering`（`.agent/skills/hdd-prompt-engineering/SKILL.md`）。
- 显式触发: `$godot-default` / `$hdd-prompt-engineering`。
