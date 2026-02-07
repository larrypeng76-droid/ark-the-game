# ark-neo 开发说明（2D 横版动作 + 对话剧情）

本文面向单人开发，目标是用 Godot 的“场景/节点”范式组织项目，并把 Codex 的日常改动集中在脚本和场景文件中，最终在编辑器里验证效果。

---

## 1. 开发顺序（从最小可玩到可发布）

### 1.1 竖切片（Vertical Slice）
目标：最小可玩闭环。
- 一名玩家角色（基础移动 + 1 种攻击）
- 一个敌人（简单 AI + 受击反馈）
- 一段对话（NPC 触发 + 分支选择）
- 一个短关卡（可通关）

### 1.2 核心系统固化
- 角色控制、战斗判定、受击反馈、相机
- 对话与剧情触发、存档/进度
- UI 框架（HUD / 对话框 / 菜单）

### 1.3 内容扩展
- 关卡与敌人类型
- 剧情线与可重用对话模板
- 音效/音乐与美术替换

### 1.4 打磨与发布
- 性能、手感、易用性
- QA 与回归测试

---

## 2. Godot 架构基线（官方原则 + 社区实践）

### 2.1 场景与节点是核心组织单位
- 一个场景有一个根节点，可保存、可多次实例化；项目可以有多个场景，但只需一个主场景即可运行。\
  （官方“Nodes and Scenes”说明）

### 2.2 以场景为中心组织资源
- 官方建议：统一使用 `snake_case` 命名文件/目录，节点用 `PascalCase`，第三方资源放在顶层 `addons/`。\
- 社区实践：以场景为单位归档其资源（scene-based assets），让场景成为第一公民，便于复用与定位。\
  （官方 Project Organization + 社区架构建议仓库）

### 2.3 单场景单控制脚本（社区高认可实践）
- 建议每个场景根节点挂 1 个主控制脚本，场景尽量自包含。\
- 跨场景依赖用信号或公开方法/字段注入，避免硬耦合。\
  （社区架构建议仓库）

### 2.4 用 Signals 进行事件通信
- Signal 是 Godot 的事件机制，可声明、连接并发射，用于模块间事件通知。\
  （官方 Signal 文档）

### 2.5 全局系统用 Autoload（最少但稳定）
- Autoload 适合跨场景持久数据、全局变量、场景切换等。\
  （官方 Autoload 文档）

---

## 3. 项目目录结构（适合单人长线维护）

> 目标：脚本、场景、资源尽量“同域管理”，减少跨目录跳转和依赖迷路。

建议结构：

```
res://
  addons/
  assets/
    player/
      player.tscn
      player.gd
      player.png
    enemy/
      enemy.tscn
      enemy.gd
      enemy.png
    level/
      level_01.tscn
      level_01.tres
  scenes/
    main/
      main.tscn
      main.gd
    ui/
      hud.tscn
      hud.gd
  scripts/
    systems/
      event_bus.gd
      save_system.gd
      scene_flow.gd
  test/
  docs/   (放文档，已加入 .gdignore)
```

- 官方建议：第三方资源放 `addons/`；项目内资产统一用 `snake_case`；节点名用 `PascalCase`。\
- 官方建议：用 `.gdignore` 忽略文档目录，避免导入并减少杂乱。\
  （官方 Project Organization）

---

## 4. 系统划分（横版动作 + 对话剧情）

### 4.1 Core（全局系统）
- `Game`：游戏全局状态（暂停、剧情阶段、主流程）
- `SceneFlow`：场景切换/过渡（Autoload）
- `SaveSystem`：存档与进度（Autoload）
- `AudioBus`：音乐/音效总线
- `EventBus`：跨系统信号（Autoload）

### 4.2 Gameplay（核心玩法）
- `Player`：移动、跳跃、受击、攻击
- `Enemy`：简单 AI、受击、掉落
- `Combat`：伤害判定、击退、硬直
- `Camera`：跟随与屏幕震动

### 4.3 Narrative（对话系统）
- `DialogueRunner`：对话播放、分支选择
- `DialogueUI`：UI 与输入
- `StoryFlags`：剧情进度与条件判断

---

## 5. 状态机：按需使用，避免过早复杂化

- 早期可以先用 `enum + match` 或轻量状态对象实现。
- 当角色/敌人逻辑复杂度上升时，再演进到更系统化的状态机。

---

## 6. 对话系统选型（社区常用方案）

> 建议先选 1 个插件/方案固化，再大量写剧情。

### 6.1 Dialogue Manager（脚本式）
- Godot 4.4+，脚本式对话编写 + 分支运行，活跃维护。\
  （Dialogue Manager 官方仓库）

### 6.2 Dialogue Engine（轻量）
- Godot 4.2.1+，轻量对话树 + 分支条件。\
  （社区资源目录）

### 6.3 Dialogue Nodes（图编辑器）
- Godot 编辑器内图形化对话树编辑与导出。\
  （Dialogue Nodes 官方仓库）

### 6.4 Parley（图编辑器）
- 图形化、面向写作流程的对话管理插件。\
  （Parley 官方页面）

### 6.5 Narrat（剧情引擎整合）
- Godot 4.1+ Web 导出可与 Narrat 集成，用于分支剧情与选择驱动。\
  （Narrat Godot 插件文档）

---

## 7. GDScript 规范（降低认知成本）

- 官方建议的代码顺序：属性/信号在前，方法在后；公共在前、私有在后；虚回调在接口前。\
- 需要时使用 `class_name` 注册全局类型。\
  （GDScript Style Guide）

---

## 8. 单人开发节奏建议

- 每周产出一个“可玩版本”（哪怕很小）
- 先做“手感”，再做“内容”
- 对话系统尽量数据驱动，避免硬编码

---

## 9. 里程碑建议（2D 横版动作）

### Milestone A：竖切片
- 玩家移动/攻击/受击
- 1 个敌人 + 1 个关卡
- 1 段对话 + 1 个分支选择

### Milestone B：剧情推进
- 对话条件与剧情旗标
- 2-3 个关卡
- 2-3 个敌人

### Milestone C：打磨
- 视觉与音效替换
- UI/UX 与节奏优化

---

## 参考（官方与社区）

- Godot 官方文档：Project Organization / Nodes & Scenes / Signals / Autoload / GDScript Style Guide
- 社区架构建议：Godot architecture & organization advice
- 对话插件：Dialogue Manager / Dialogue Engine / Dialogue Nodes / Parley / Narrat

