# Godot 平台动作项目：架构共识（Architecture Consensus）

> 中文为主，关键结论附英文摘要（EN summary）。
>
> 目标：随着代码量增长，仍能按“功能自闭环（feature-closed loop）”清晰扩展；并用 **文档 + Agent 约束 + 自动化检查** 保持一致性。

---

## 1. 目的 / Purpose

**CN**

- 让功能按模块/切片开发：每个小功能自我闭环、可独立演进、可独立测试。
- 降低耦合与回归成本：模块间交互通过稳定边界（signals/areas），避免互相“深挖内部节点”。
- 与 Godot 场景系统对齐：以 **Scene** 作为最自然的模块边界。

**EN summary**

- Keep the project scalable by building features as self-contained slices, with clear module boundaries aligned to Godot scenes.

---

## 2. 现状快照（基于仓库） / Current repo snapshot

> 以当前仓库为事实来源（非理想化结构）。

**CN**

- `core/`：偏基础设施（UI、Combat、StateMachine）。
- `game/`：偏具体玩法内容（Player、Enemies、World、Screens）。
- `tests/`：已存在 SceneTree headless 测试，用于回归与“能加载/关键节点存在”。
- 入口：`project.godot` 的 `run/main_scene` 指向 `game/game.tscn`（Game 下实例化 Player + Level）。

**风险点（当前）**

- `core/state_machine/` 已提供通用的 `State` / `StateMachine` 基类；Player 相关逻辑通过 `PlayerState` / `PlayerStateMachine` 适配（属于“逐步演进”的结构）。
- `Player.gd` 承担职责较多（输入/状态/移动/战斗/UI/暂停），规模增长时会成为维护热点。
- 个别敌人逻辑会直接调用 `Player` 方法（耦合点），建议逐步收敛到 `Hitbox/Hurtbox` 边界交互。

**EN summary**

- The current repo already has `core/` vs `game/` separation and tests. Main risks are Core depending on Player-specific types, a growing “fat Player” script, and direct cross-entity method calls.

---

## 3. 核心原则 / Core principles

> 这些是“长期不变”的共识，优先写入 `AGENTS.md` 作为提示词约束。

### P1：Scene 即模块边界 / Scene as the module boundary

**CN**

- 一个功能（feature）优先以一个场景（`.tscn`）作为入口（prefab），场景内部自包含。

**EN**

- Prefer a scene as the entrypoint boundary for each feature.

### P2：功能自闭环（Feature-closed loop）

**CN**

- 一个功能目录内应包含：`*.tscn` + `*.gd` + 资源（textures/animations/resources）+ 对应测试（至少 1 个最小测试）。
- 对外只暴露少量稳定接口：**signals + 1~3 个方法**（或一个配置 resource）。

**EN**

- Each feature folder is self-contained and exposes a small, stable API.

### P3：依赖方向清晰 / Clear dependency direction

**CN**

- `game/` 可以依赖 `core/`。
- `core/` 不应依赖 `game/`（不要引用 `res://game/...`，不要写死 `Player/Zombie/...` 等具体实体）。

**EN**

- `Core` must not depend on `Game`.

### P4：模块通信优先用 Signals / Areas / Groups

**CN**

- 优先用 **signals** 表达事件。
- 需要“接触/命中”类交互时，优先用 `Area2D`（`Hitbox/Hurtbox`）表达边界。
- `Groups` 作为弱引用发现机制可以用，但要克制（避免全局到处查）。

**EN**

- Prefer signals and Area2D boundaries; use groups sparingly.

### P5：先竖切片，再固化系统 / Vertical slice first

**CN**

- 先做最小可玩闭环（vertical slice），再抽象为通用组件/系统。

**EN**

- Build a playable slice first, then extract shared systems.

---

## 4. 类 FSD 的 Godot 落地映射 / FSD-like mapping in Godot

**CN**

FSD（Feature-Sliced Design）的关键是“切片 + 依赖规则 + 自闭环”，不是文件夹名字。
在 Godot 中，最自然的切片边界是 **Scene（场景）**，其次是场景下的子节点组件。

建议目标结构（不要求立刻迁移，作为新功能与重构方向）：

```text
res://
  core/                # shared / infrastructure
  game/
    Entities/          # Player/Enemies/NPC...
    Features/          # Dash/PauseMenu/Dialogue/Inventory...
    Screens/           # MainMenu/Game...
    World/             # Levels/Tilemaps...
  tests/
  docs/
```

**EN summary**

- Use scenes as slices. Use folders like Entities/Features/Screens/World to keep responsibilities clear.

---

## 5. 模块边界与对外 API 规则 / Module boundary & public API rules

**CN（规则）**

1. 一个功能一个入口场景（prefab）。
2. 模块外部禁止通过 `get_node("A/B/C")` 深链访问内部节点来做业务逻辑。
   - 允许：在实例化时注入依赖引用（构造/`setup()`），或通过 signals 通知。
3. 模块外部禁止直接修改模块内部状态；只通过公开方法或信号交互。

**EN summary**

- No deep NodePath poking across modules; interact via explicit APIs and signals.

---

## 6. 通信模式推荐 / Communication patterns

**Signals（推荐）**

- 适合：状态变化、事件广播、跨模块通知。
- 优点：低耦合、可视化连接、易测。

**Area2D（Hitbox/Hurtbox）**

- 适合：战斗命中、接触伤害、可交互触发。
- 优点：边界清晰（碰撞即边界），减少实体间互相调用。

**Groups（谨慎）**

- 适合：弱引用发现（如 `player`、`enemy`）。
- 约束：不要在“任何地方都查 group”替代注入；明确哪些系统可查、哪些不可查。

**Autoload（最少但稳定）**

- 适合：跨场景持久系统（Save/Audio/SceneFlow 等）。
- 约束：新增 Autoload 必须在文档登记（职责 + API），避免变成“全局杂物间”。

### Autoload registry / Autoload 登记表

| Name | Path | Responsibility / 职责 | Public API / 对外 API | Non-goals / 不做什么 |
|---|---|---|---|---|
| `GameFlow` | `res://game/flow/game_flow_manager.gd` | 场景流/暂停控制（重开、回主菜单、解除暂停） | `set_paused(paused)`, `restart_game()`, `go_to_main_menu()` | 不承载战斗/角色/关卡逻辑；不直接读写具体实体状态 |

---

## 7. Player 与状态机边界（与现有约束对齐） / Player & state machine boundaries

**CN**

- 状态脚本保持轻量：动画 + 过渡检查。
- 共享移动/物理集中在 `Player.gd`，避免在状态里复制 `move_and_slide()` 逻辑。
- 所有状态切换必须走 `PlayerStateMachine.change_state()`。
- 任何锁定/不可控状态必须有 fail-safe 退出：
  - 环境条件失效（例如 `not is_on_floor()`）立即切 `FallState`。
  - timer 结束时重新判断环境再决定下一状态。
  - `exit()` 清理 timer/flags，避免锁死。

**EN summary**

- Keep states small and always provide fail-safe exits.

---

## 8. Combat 边界：统一到 Hitbox/Hurtbox / Combat boundary: converge on Hitbox/Hurtbox

**CN**

目标：模块间通过 `Hitbox -> Hurtbox.hit()` 交互，避免敌人/玩家互相直接调用大量内部方法。

- **边界事件（跨模块）**：`Hurtbox.hit(damage, damaged_by)`
- **模块内逻辑（各自闭环）**：扣血、击退、硬直、震屏、死亡、掉落。

这样做的收益：

- 敌人不需要知道玩家内部实现（是否有护盾/无敌帧/抗性）。
- 玩家也不需要知道敌人内部实现（不同敌人死亡/受击表现不同）。

**EN summary**

- Decouple entities by routing damage through Area2D boundaries.

---

## 9. 开发闭环 checklist / Feature closed-loop checklist

**CN**

每新增一个功能（Feature），至少满足：

1. 新建功能目录（scene + script + resources）。
2. 定义对外 API（signals + 少量方法）。
3. 增加最小测试（至少能 headless load 或验证关键节点/规则）。
4. 提供一个手工验证入口（例如 sandbox level 挂载）。

### Feature folder template / 功能目录模板（建议）

> 目标：新功能从一开始就“自闭环”（scene+script+assets+tests），避免后期大拆分。

```text
res://game/<feature_or_entity>/
  <thing>.tscn
  <thing>.gd
  assets/
  tests/
    <thing>_test.gd
```

约束：

- 场景切换/重开/回主菜单：只通过 `GameFlow`（signals 请求）。
- 跨模块交互：优先 signals / Area2D（Hitbox/Hurtbox），避免互相调用内部方法。

**EN summary**

- Each feature ships with a scene entrypoint, a tiny public API, and at least one minimal test.

---

## 10. 质量门禁与工具 / Quality gates & tooling

**Gate 1：主场景 headless load**

- 目的：尽早发现脚本解析错误、资源缺失、场景引用断裂。

**Gate 2：tests 全通过**

- 目的：保证关键规则不回退（例如状态 fail-safe、关键节点存在）。

**非阻塞：架构 lint（warnings）**

- 目的：把“结构性风险”前置提示，但不阻塞当下开发（后续可通过 `STRICT=1` 收紧）。

推荐命令（统一入口）：

```bash
./tools/lint.sh
```

### global_script_class_cache 护栏 / Guardrails

当项目使用 `class_name`（全局脚本类）时，Godot 可能会在 `.godot/global_script_class_cache.cfg` 写入缓存。

- CN: 我们用 tests 把缓存当作“可选但一旦存在就必须正确”的护栏，重点防止大小写与路径异常（例如 `res://Core/` / `res://Game/` 或双斜杠拼接）。
  EN: When the cache file exists, tests enforce consistent casing and sane paths.

相关环境变量：

- `GODOT_KEEP_CACHES=1`：跳过清理 `.godot/editor` 等缓存（默认会清理以保证 headless gate 稳定）。
- `GODOT_CLEAN_GLOBAL_CLASSES=1`：强制删除 `.godot/global_script_class_cache.cfg`（仅在需要重建时使用）。

---

## 11. 哪些可 lint、哪些不可 lint（表格）/ Lintability matrix

| Rule / 规则 | Enforceability / 可自动化程度 | Tooling / 工具形态 | Notes / 备注 |
|---|---:|---|---|
| `pause_mode` 禁用，改用 `process_mode` | 高 / High | `rg` 检查 | 可直接阻止（未来可升级为强制） |
| `core/` 不得引用 `res://game/` | 中高 / Med-High | `rg` 检查 `core/` | 可先警告，逐步收紧 |
| “禁止深链 NodePath 跨模块访问” | 低 / Low | Code review + agent 约束 | 静态判断困难，靠约束与评审 |
| “功能目录自闭环（scene+script+resources+tests）” | 中 / Medium | 脚本扫描（目录约定） | 需要先统一目录约定 |
| “states 只做动画+过渡检查” | 低 / Low | tests + review | 可通过具体回归用例覆盖关键情况 |
| “新增 Autoload 需登记” | 低 / Low | review + doc checklist | 自动化成本高，靠流程约束 |
| `global_script_class_cache.cfg` 大小写/路径一致性 | 中 / Medium | tests 扫描 `.godot/`（存在时强制） | headless 下可能不生成 cache；存在时必须正确 |

---

## 12. Appendix：项目约束汇总（引用 AGENTS.md） / Appendix

- 项目强约束与 Codex 工作约束以 `res://` 项目的 `AGENTS.md` 为准。
- 运行 gate/检查以 `./tools/lint.sh` 为准。
