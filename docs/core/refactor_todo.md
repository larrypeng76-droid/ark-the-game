# Refactor TODO（结构优化清单）

> 目标：严格遵守 `AGENTS.md` 的架构/命名/输入物理/状态机/战斗约束，持续降低耦合与回归成本。
>
> 本文是“可长期维护的 TODO”，每条包含：优先级、完成定义（DoD）、建议测试/自动化、预估改动面。

---

## P0（本轮：最紧要的模块解耦 + TDD 固化）

> （状态：P0-1 ~ P0-7 已完成；以 `./tools/lint.sh` 通过作为统一验收）


### P0-1：禁止 `core/**` 引用 `res://game/...`

- 背景：`core/` 是 shared/infrastructure，不应依赖 `game/` 具体内容。
- DoD：
  - `core/` 下不再出现 `res://game/` 字符串（尤其是切场景路径）。
  - 新增回归测试 `tests/core_no_game_path_dependency_test.gd` 并通过。
- 自动化：
  - `./tools/lint.sh` 通过。
  - `./tools/lint_architecture.sh` 不再报 `core/` 的 `res://game/` WARN。
- 预估改动面：小（通常是把 Core 的“切场景/全局流程”改成 signals）。

### P0-2：DeathScreen 解耦（Core 只发 signals，Game 负责切场景）

- DoD：
  - `core/ui/DeathScreen.gd` 不再调用 `get_tree().change_scene_to_file()`。
  - DeathScreen 通过 `restart_requested/menu_requested` signals 通知外部。
  - `game/player/Player.gd`（或未来的 GameFlow）连接 signals 并执行切场景/解除暂停。
- 测试：
  - 由 `core_no_game_path_dependency_test.gd` 间接覆盖。

### P0-3：Player states 移除 `class_name`（避免全局污染）

- DoD：
  - `game/player/states/*.gd` 不再包含 `class_name`。
  - 新增回归测试 `tests/player_states_no_class_name_test.gd` 并通过。
- 预估改动面：中（涉及多个 state 文件，但基本是删一行）。

### P0-4：修复 `sign()` 类型转换（减少 warning-as-error 风险）

- DoD：
  - `Player.gd` 中 `facing_direction: int` 的赋值不依赖隐式 Variant 推断。
  - 行为不变：`visual.scale.x` 仍是 `-1/1`。
- 测试：
  - 现有 headless load + player 相关 tests 覆盖“能加载/能跑”。

### P0-5：资源内聚（立即重组三大块，降低跨功能耦合）

- 背景：`Resources/**` 全局堆放会导致功能边界模糊、迁移困难；但一次性全量迁移风险很高。
- 范围（仅三大块，避免过度工程化/大搬家）：
  - `res://Resources/Player/Animations/*` -> `res://game/player/assets/animations/*`
  - `res://Resources/World/Tilemaps/*` -> `res://game/world/assets/tilemaps/*`
  - `res://Resources/Enemies/Animations/*` -> `res://game/enemies/assets/animations/*`
- DoD：
  - 以上目录迁移完成，相关 `.tscn` 引用全部更新。
  - 被迁移目录内的 `*.import` 一并迁移，且 `source_file="res://Resources/..."` 更新为新路径。
  - `rg -n "res://Resources/(Player/Animations|World/Tilemaps|Enemies/Animations)/" -S .` 无残留。
  - 跑 gate：`./tools/lint.sh` 通过。
- 风险与回滚：
  - 风险：`.import` 的 `source_file` 不更新会导致 headless 加载失败。
  - 回滚：全部迁移用 `git mv`；失败可 `git restore --staged --worktree .`。

### P0-6：伤害链路统一到 `Hitbox -> Hurtbox.hit()`（敌人攻击不直接 `take_damage`）

- 背景：敌人/子弹直接调用 `Player.take_damage` 会扩散实体耦合；中型项目后期会难维护。
- DoD：
  - Player 增加 `HurtBox`（`Area2D` + `res://core/combat/hurtbox.gd`）。
  - `enemy_bullet.gd` 改为命中 `area_entered` 并调用 `area.hit(damage, self)`。
  - `shooter.gd` 接触伤害改为通过 `ContactDamage.get_overlapping_areas()` 查找 Hurtbox，并调用 `area.hit(attack_damage, self)`。
  - 敌人攻击脚本中不再出现 `.take_damage(`（仅允许定义 `func take_damage`）。
  - 跑 gate：`./tools/lint.sh` 通过。
- 建议测试：
  - `tests/player_has_hurtbox_test.gd`
  - `tests/enemy_attacks_no_direct_take_damage_test.gd`

### P0-7：Player 中等瘦身（拆出 health/combat 逻辑，但不引入框架）

- 背景：`Player.gd` 逐步变“胖脚本”会拖慢迭代。目标是让职责更聚合、可测试，避免大系统化。
- DoD：
  - 新增 `game/player/player_health_logic.gd`、`game/player/player_combat_logic.gd`（`extends RefCounted`，不使用 `class_name`）。
  - `Player.take_damage()` API 保持不变，但内部委托给 health logic。
  - `_fire_bullet()`、`_is_enemy_in_melee_range()` 内部委托给 combat logic。
  - `_input` 仍是唯一输入读取入口；`move_and_slide()` 仍只在 `_physics_process`。
  - 跑 gate：`./tools/lint.sh` 通过。

---

## P1（下一轮：进一步解耦 Core→Game 类型依赖）

### P1-1：处理 `core/state_machine` 对 `Player` 的依赖

两条路线二选一：

当前状态（已落地一部分）：

- 已在 `core/state_machine/` 引入通用 `State` / `StateMachine`。
- `PlayerState` / `PlayerStateMachine` 已迁移为在通用基类之上实现的适配层。

后续仍可选的两条路线（按需要决定是否继续收敛）：

1) 迁出 Player 专用适配层：把 `core/state_machine/player_state*.gd` 移到 `game/player/`（更严格的 Core→Game 分层）。
2) 保留适配层在 Core：允许 `PlayerState*` 作为示例/模板（但需要在文档中明确其“Player 专用”定位）。

- DoD：
  - `core/` 下不出现 `Player` 等实体类型引用。
  - `tools/lint_architecture.sh` 的 “Core mentions Player/Zombie/Shooter” WARN 消失。
- 建议测试：
  - 增加 `tests/core_no_game_entity_types_test.gd`（扫描 Core `*.gd` 禁止 `\bPlayer\b` 等）。

### P1-2：引入 GameFlow autoload（集中场景流/暂停控制）

- 背景：切场景/解除暂停如果散落在 Player/UI 内，会形成隐式耦合且难以统一管控。
- DoD：
  - 新增 `GameFlow` autoload（`res://game/flow/game_flow_manager.gd`）。
  - `core/ui/**` 仅通过 signals 通知；切场景只在 `GameFlow` 内发生。
  - 新增回归测试：
    - `tests/game_flow_autoload_test.gd`（确保 `/root/GameFlow` 存在且方法齐全）。
    - `tests/zz_global_script_class_cache_no_mixed_paths_test.gd`（存在 cache 时禁止异常路径片段）。
    - `tests/scene_changes_must_go_through_game_flow_test.gd`（除 allowlist 外禁止 `change_scene_to_file` 等）。

## Done（已完成）

- Player 专用 `player_state*.gd` 已迁移到 `game/player/`（更严格的 Core→Game 分层）。

---

## P2（维护性/质量提升）

### P2-1：将动态注入的 InputMap action 固化到 `project.godot`

- 背景：运行时注入 action 会造成“某些测试/场景路径没跑到 _ready 导致 action 缺失”的隐性耦合。
- DoD：
  - `project.godot` 声明 `attackShoot`。
  - 删除 `Player.gd` 的 `_setup_input_actions()`（或只保留 debug 模式）。

### P2-2：进一步加强架构 lint（先 warn）

- 例如：扫描跨模块深链 NodePath（启发式规则），先 warn 不 fail。

### P2-3：敌人攻击去 Player 类型依赖（优先战斗边界一致性）

- 背景：EnemyBullet/Shooter 等直接 `is Player` 会让“可替换角色/复用模块”困难。
- DoD：
  - 敌人攻击脚本不再写 `is Player`；改为 group + method 能力检测（如 `is_in_group("player")` + `has_method("take_damage")`）。
  - 新增回归测试 `tests/enemy_attacks_no_player_type_test.gd` 并通过。

---

## P3（工程化约束：逐步逼近 snake_case）

### P3-1：禁止新增 PascalCase 的脚本文件名（先冻结增量）

- 背景：当前项目历史文件名较多 PascalCase，直接大迁移风险高；但可以先冻结“不要再新增”。
- DoD：
  - 新增回归测试 `tests/no_new_pascal_case_scripts_test.gd`：
    - 允许现有 legacy allowlist
    - 但一旦新增 PascalCase 脚本文件名，测试失败。
- 备注：后续可单独做一次重命名迁移（在 Godot 编辑器内移动/重命名以自动更新引用）。
