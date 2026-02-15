# 资源管理体系（Godot 4.5+）: 目录规范、导入预设、预览与调用

/Users/lebupeng/Documents/games/godot-platformer
├─ core/                       # 通用基础模块（UI、combat、state_machine）
├─ game/                       # 游戏内容主目录
│  ├─ player/                  # 玩家模块（states + assets/animations）
│  ├─ enemies/                 # 敌人模块（assets/animations）
│  ├─ world/                   # 世界模块（levels、tilemaps、vehicles、assets）
│  ├─ flow/                    # 流程模块（场景流转相关）
│  └─ features/                # 具体功能模块集合
│     ├─ inventory/            # 背包功能
│     └─ items/                # 物品功能集合
│        ├─ apple/
│        ├─ axe/
│        ├─ ground_block/
│        ├─ pickaxe/
│        └─ wood/
├─ Resources/                  # 旧/临时素材仓（建议逐步迁移到 game/core 内）
├─ docs/                       # 文档（含 asset_management.md）
├─ tests/                      # 测试
└─ tools/                      # lint/脚本工具


标:
- 把角色、背景、UI 等图形资源按模块管理, 便于复用与定位, 也便于 Codex/脚本稳定引用.
- 让导入设置可复现(多人/多机器一致), 并提供一套“快速预览/浏览资产”的操作路径.

约束(对齐本项目 `AGENTS.md` / 架构共识):
- 以 Scene 作为模块边界, 每个功能目录自闭环(scene + script + resources).
- 依赖方向: `game/` 可以依赖 `core/`; `core/` 不得依赖 `game/` (避免在 `core/**` 中引用 `res://game/**` 资源路径).
- 文件/目录 `snake_case`, 节点 `PascalCase`.

---

## 1. 资源在 Godot 里的“真相”

### 1.1 两类文件
- 源文件(source): 你放进 `res://` 的 `png/webp/jpg/svg/aseprite(导出后)` 等.
- 导入配置(import metadata): Godot 会为每个源文件生成同名的 `*.import` 配置文件(保存导入选项), 并在 `.godot/imported/` 生成缓存.

建议版本控制:
- 提交: 源文件 + `*.import` (保证导入选项一致).
- 忽略: `.godot/` (本仓库已忽略), 因为其中包含导入缓存、编辑器状态等.

备注:
- 本仓库目前还忽略了 `*.gd.uid` (见 `.gitignore`). 这是一个“避免 UID sidecar 文件进入仓库”的策略. 你可以继续保持现状, 但要理解它的含义: 某些 Godot 版本/运行方式可能会生成 `.uid` sidecar 来稳定引用; 被忽略意味着引用稳定性更多依赖路径与场景/资源内部记录. 若后续遇到 UID 相关的引用抖动, 再评估是否要改策略.

参考:
- Project Organization / `.gdignore`: https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Importing resources: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_resources.html
- Importing images: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html

---

## 2. 推荐目录结构(与你当前项目对齐)

你项目现在同时存在:
- 顶层 `Resources/` (更像“素材仓库”)
- 分散的 `game/**/assets` (更像“按功能自闭环”)

从 Godot 项目维护角度, 更推荐后者. 建议把“运行时会加载的资产”最终都归档到 `core/` 或 `game/` 的具体 feature 目录中.

### 2.1 统一约定: 资源跟着模块走

#### `core/` (通用、可被 game 依赖)
- `core/ui/` 下的 UI 组件可以有自己的 `assets/`.
- `core/assets/` (可选): 放全局复用但不绑定某个 UI scene 的资源(例如通用图标、通用 shader、通用音效等).

示例:
- `core/ui/pause_menu/pause_menu.tscn`
- `core/ui/pause_menu/pause_menu.gd`
- `core/ui/pause_menu/assets/icons/*.png`
- `core/assets/fonts/*.ttf`

#### `game/` (具体玩法与内容)
- 每个功能目录自带 `assets/`, 不要把 game 资源塞到 core.

示例(与你现有结构一致):
- `game/player/player.tscn`
- `game/player/player.gd`
- `game/player/assets/animations/*.tres`
- `game/player/assets/sprites/*.png`

敌人/关卡同理:
- `game/enemies/<enemy_name>/...`
- `game/world/levels/<level_name>/...`

### 2.2 顶层 `Resources/` 的处理方式(建议迁移)

建议把 `Resources/` 视为“临时落地点”, 逐步迁移:
- `Resources/Fonts/**` -> `core/assets/fonts/**` (字体通常是全局复用)
- `Resources/Enemies/**` -> `game/enemies/<enemy_name>/assets/**`
- `Resources/<misc>` -> 找到所属模块(玩家/世界/UI/某 feature), 放进对应 `assets/`

迁移原则:
- “运行时引用的最终路径”应尽量稳定, 避免一会儿 `res://Resources/...` 一会儿 `res://game/...`.
- 迁移后在编辑器里打开相关 scene, 让 Godot 自动修正引用并生成/更新 `*.import` 元数据.

---

## 3. 命名规范(让资源可搜索、可批处理、可读)

建议在 `assets/` 里分子目录, 并用后缀表达用途:
- `assets/sprites/`: 单张图/序列帧源图
- `assets/atlases/`: 图集相关(源图 + `AtlasTexture`/相关 `.tres`)
- `assets/animations/`: `SpriteFrames`, `AnimationLibrary`, `AnimationPlayer` 相关资源
- `assets/tilesets/`: `TileSet` / tilemap 资源
- `assets/materials/`: 材质、shader
- `assets/ui/`: UI 专用贴图

文件名建议:
- 用“对象 + 用途 + 可选状态/方向”:
  - `player_idle_strip.png`, `player_run_strip.png`
  - `dead_revolver_idle.png`, `dead_revolver_shoot.png`
  - `forest_midground_01.png`, `tree_oak_02.png`
- 避免 `idle.png`, `sprite.png` 这类泛化名称(后期不可维护).

---

## 4. 导入设置与预设(Import Presets)

核心思路:
- 你想要的渲染结果(像素风/高清/是否平铺/是否需要 mipmaps)决定导入选项.
- 导入选项应该“批量一致”, 所以要用预设(preset)而不是逐个手调.

### 4.1 建议准备两套贴图预设

1) 像素风(Pixel Art)贴图预设(常见需求):
- 关闭 Filter (避免模糊)
- 通常关闭 Mipmaps (2D 像素风常不需要; 需要缩放时再评估)
- Compression 选择无损/合适选项(按效果与体积权衡)

2) 高清/背景贴图预设(常见需求):
- 开启 Filter (需要平滑)
- 需要缩放/远景时可开启 Mipmaps
- 若需要平铺, 设置 Repeat/Wrap 相关选项(具体以导入面板为准)

### 4.2 操作步骤(在 Godot 编辑器里)
1. 把图片拖进目标目录(例如 `game/world/assets/midground/`).
2. 在 FileSystem 面板选中图片.
3. 右侧 Import 面板调整选项.
4. 点击 Import 面板里的 Preset 下拉:
   - 保存为新预设(例如 `pixel_art_2d`, `hd_background_2d`).
   - 对同类图片批量应用该预设(多选资源后应用, 然后 Reimport).
5. 在同一目录下后续新增图片时, 复用同一预设.

提示:
- 导入选项改动后需要 Reimport 才会生效.
- 对“整组序列帧”务必统一导入选项, 否则同一动画不同帧会出现滤镜/色彩/边缘差异.

---

## 5. “便于 Codex 调用”的资产封装方式(强烈推荐)

不要在很多脚本里散落 `preload("res://...png")`. 更好的做法是:
- 每个 feature 用一个“资产清单资源”(Asset Manifest)集中管理引用.
- Scene/脚本只依赖清单资源, 而不是直接硬编码大量路径.

### 5.1 每个模块一个 manifest `.tres`

例如 Player:
- `game/player/player_assets.gd` (extends Resource, 不加 `class_name`)
- `game/player/player_assets.tres` (在编辑器里创建资源实例, 把贴图/动画资源拖进去)

`player_assets.gd` 示例:
```gdscript
extends Resource

@export var sprite_frames: SpriteFrames
@export var hit_fx_texture: Texture2D
@export var ui_portrait: Texture2D
```

Player 脚本中只暴露一个引用:
```gdscript
@export var assets: Resource # 实际类型是 player_assets.tres
```

好处:
- 路径改动时, 只需要在 `.tres` 里修一次.
- 更符合“模块自闭环”: 这个 manifest 放在模块目录内.
- 对 Codex 来说, “找资源”变成“打开 manifest 看导出的字段”, 非常稳定.

### 5.2 shared 资源的边界(避免 core <-> game 反向依赖)
- `core/**` 的 manifest 只能引用 `core/**` 下的资源.
- `game/**` 的 manifest 可以引用 `game/**` 和 `core/**` (比如复用通用字体/通用 UI icon).

---

## 6. 资源预览: Godot 提供的常用方式

你不需要写代码就能做 80% 的“图形资产预览”:

### 6.1 FileSystem 面板缩略图浏览
1. 打开 Godot Editor 的 FileSystem 面板.
2. 切换显示为缩略图(不同版本入口略有差异, 常见是面板右上角的视图切换按钮).
3. 调整缩略图大小, 就可以像“素材浏览器”一样快速扫图.

### 6.2 Inspector 预览与快速打开
- 在 FileSystem 里点选一个 `Texture2D`(png/webp/jpg 导入后), Inspector 通常会展示预览.
- 双击 `SpriteFrames`、`TileSet`、`Theme` 等资源, 会进入对应的专用编辑器:
  - SpriteFrames 编辑器: 预览/调序列帧/动画
  - TileSet 编辑器: 预览地形、碰撞、自动地形等

### 6.3 场景级预览(推荐给“角色/敌人”)
对角色、敌人等“组合资产”(贴图 + 动画 + hitbox/hurtbox), 最好的预览就是一个专用 scene:
- `game/enemies/<enemy>/enemy_<name>.tscn` 作为预览载体
- 挂上 `AnimatedSprite2D/Sprite2D` + `SpriteFrames` + 碰撞区
- 在 2D 视图里直接看到最终效果

这也符合“一个模块一个 scene”的闭环实践.

---

## 7. 原始素材与非运行时文件(PSD/aseprite 工程)怎么放

原则:
- Godot 只需要运行时要加载的导出文件(png/webp/ogg...), 原始工程文件不要让 Godot 导入索引, 也别污染 FileSystem.

做法:
- 建一个 `art_source/` 或 `source_art/` 目录, 放 PSD/aseprite 工程.
- 在该目录放一个空的 `.gdignore`, 让 Godot 编辑器忽略该目录.

示例:
- `source_art/.gdignore`
- `source_art/player/player.aseprite`
- `source_art/world/forest.psd`

参考:
- `.gdignore` 行为见官方 Project Organization 文档.

---

## 8. 最小落地清单(建议按这个顺序做)

1. 定义“哪些资源属于 core, 哪些属于 game”.
2. 选 1 个模块做示范闭环(例如 `game/player/`):
   - 整理 `assets/` 子目录
   - 建 `*_assets.gd` + `*_assets.tres` manifest
3. 把顶层 `Resources/` 里最常用的一类(比如字体)迁移到 `core/assets/fonts/`.
4. 在 Godot 编辑器里打开相关 scene, 让引用自动更新, 检查缺失资源.
5. 为像素风与高清背景建立 Import 预设, 批量应用并 Reimport.

---

## 9. 相关官方文档(建议从这里深入)

- Project Organization (含 `.gdignore`): https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- Importing resources: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_resources.html
- Importing images: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html
- Resource UID (背景与迁移注意点): https://docs.godotengine.org/en/stable/tutorials/migrating/uid_changes.html

