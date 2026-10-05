# PVZ1 · Godot Mod：长按、军衔与连锁初版

**素材来源版本：PVZ 汉化2版（PVZ1 1.0.0.1051 CN V2）**。本仓库从 `v1` 还原基线分离，当前本地阶段为 **mod-v0.2.0-local**。GitHub 本次仅同步开发方案与阳光收集 UI；下述新玩法实现保留在本地，等用户明确要求后再上传。

**GitHub 发布不附带原版素材。** 克隆后请先按 [素材导入说明](docs/ASSETS.md) 生成 `assets/`，再打开 Godot。固定还原版在 [pvz1-godot-restoration](https://github.com/Show-o4210/pvz1-godot-restoration)；本仓库开发根基、操作方式与扩展约束见 [MOD_FOUNDATION.md](docs/MOD_FOUNDATION.md)。

默认手动模式：豌豆射手和向日葵种下后不自动执行任务。**鼠标左键长按植物充能**，松开或移出原格取消未完成动作；持续按住可完成多轮。读条和植物放大提供反馈，充能完成后射击或产出可点击阳光。F 长按、Tab 切换为辅助输入，右键取消。

- 同一格再次种植同种植物升军衔，最高三阶，使用正常费用和种子冷却；不免费回血。星标显示军衔，顶部状态和卡片提示显示收益与满阶。
- 豌豆升级缩短充能并提高伤害；同一行积累完整充能轮次，2–3 株每两轮、4–6 株每三轮、7–9 株每四轮同步射击。每轮主株先射击，联动时不重复发射主株。
- 向日葵完成充能时影响周围八格内的向日葵，邻株 75% 产量，连锁不递归；二/三阶给予 6/12 秒补给窗口，每株共享 4 秒生产间隔，重叠不会重复发钱或无限累加窗口。
- 顶部按钮可切回自动对照模式。坚果仍为被动防线；原三波关卡和敌人参数保留，真人难度待试玩微调。

v0 用本地原版资源还原最小白天草坪战斗。当前 v1 保留该玩法，修正卡片尺寸、草坪坐标和角色落点，加入射击反馈、植物受伤、坚果裂纹、路障破损、僵尸断臂/掉头/倒地淡出、推车待机/启动以及原版风格菜单和进度条。阶段范围、来源和剩余差异见 [docs/VERSIONS.md](docs/VERSIONS.md)。

v1 已修复颜色变暗、豌豆头身联动、僵尸下巴、步态移动/停走过渡，以及啃咬后恢复行走的手部贴图残留。此前遇到的 UI、缩放、反馈、损伤和动画问题，现已统一整理为 [问题与解决方式文档](docs/ANIMATION_RENDERING.md)；更新后的全彩动画预览为 `build/v1-detail.mp4`。

关卡采用三波简短出怪，尚未照搬原版冒险关卡；不包含图鉴、存档、夜晚、泳池、屋顶和其他植物。已有原版角色动画与音效，背景音乐暂未接入。

## 启动

双击 `启动游戏.cmd`，或在 Godot 4.7.2 中导入 `project.godot` 后按 F5 运行 Mod。`scenes/game.tscn` 保留自动化基线，`scenes/mod_game.tscn` 为默认 Mod 主场景。

左键选择种子，再点击草坪种植；点击阳光收集。右键取消；1/2/3 选择豌豆射手/向日葵/坚果，4 选择铲子，空格/ESC 暂停，R 重开。右上角“菜单”可以暂停并重新开始。

## 社区调查与复用

调查日期：2026-10-05。实际下载并阅读了以下项目：

| 项目 | 实际检查结果 | 使用决定 |
| --- | --- | --- |
| [ZeroMarker/pvz-godot](https://github.com/ZeroMarker/pvz-godot) | 代码中实际只有三种基础植物，视觉使用 icon.svg 占位；发射时直接伤害目标，飞行豌豆只是装饰；没有有限关卡胜利流程 | 用来了解现有进度，没有复制游戏代码 |
| [NightsReimu/pvz-godot](https://github.com/NightsReimu/pvz-godot) | SVG 同人项目，加入大量融合、天气和东方内容；主 game.gd 约 1.6 MB，当前 v1.0.171 | 与本次最小原版还原范围差异较大，没有复制代码或素材 |
| [ec50n9/pvz2godot](https://github.com/ec50n9/pvz2godot) | 成功解包本地 main.pak，转换六个动画并通过仓库动画语义校验 | 复用资源转换工具，固定提交 ba9df9a5aaef7449dd7507d0d7d3993615fec239 |

`tools/pvz2godot/` 为上游 GPL-3.0 工具，保留原许可证。游戏逻辑由本项目编写。`assets/` 来自用户本地游戏安装目录，不属于这些社区工具的源码许可。原版安装目录未修改。

## 重新导入素材

本机已导入当前版本所需资源，公开仓库不包含这些资源。首次克隆或需要重新生成时，在本目录执行：

```powershell
python -m pip install -r requirements.txt
python tools/prepare_assets.py ..\Plants_Vs_Zombies_V1.0.0.1051_CN_V2
```

使用 Python 3.9+ 和 Pillow。原始解包缓存位于 `.source_assets/`；只有选用资源进入 `assets/`。

## 验证

```powershell
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --quit
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/gameplay_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/presentation_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/animation_detail_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/discrete_state_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/blink_alignment_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/sun_collection_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/manual_control_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/plant_network_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/mod_mouse_render_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/manual_playthrough.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --path . --script tests/color_render_test.gd
..\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/level_playthrough.gd
python tools/pvz2godot/verify.py --all .source_assets/compiled/reanim assets/actors
```

玩法检查覆盖资源扣除、重复种植、冷却、真实子弹飞行与首个目标命中、分行判定、护甲溢出、阳光点击优先级、暂停、铲除、啃食、推车和胜负。

本机 Godot 4.7.2 的 v1 当前验证结果（2026-10-06）：22 项玩法、24 项动画/UI、18 项动画联动/位移、36 项离散状态/动作切换、33 项眨眼绑定、12 项阳光收集、5 项 GPU 颜色检查，共 150 项通过。GPU 零效果颜色对照的 RGBA 误差为零；自动操作按正常经济和冷却规则完成三波关卡，约 188.2 秒击败 15/15 僵尸。v0 的六个动画已通过转换工具语义校验；v1 使用同一转换结果并保留步态元数据，在运行时绑定部件和管理播放，尚未逐像素对照整个原版画面。实际 GPU 截图和连续视频保存在 `build/`，已人工检查；`build/v1-detail.mp4` 保留手型修复后的 8 秒画面，新近景 `build/sunflower-blink.mp4` 展示三个不同摇摆相位的眨眼绑定。既有 `v1` 和 `mod-v0.1.0` 标签及完整归档保留原基线，本次修复提交在 `main`。

本地 Mod 初版额外通过 42 项长按/升级检查、28 项连锁检查、10 项实际鼠标/GPU 检查，加上 150 项基础回归，共 230 项通过。一次只充能一株、遵守正常经济和卡片冷却的通关程序击败 15/15 僵尸，约 226.6 秒，完成 162 次长按。此结果证明流程可用，不代表真人难度已平衡。当前截图与十秒全彩预览为本地 `build/mod-v0.2.png`、`build/mod-v0.2.mp4`。

`tests/manual_control_test.gd` 和 `tests/manual_playthrough.gd` 是当前长按检查/通关入口的兼容别名，原 mod-v0.1.0 测试在历史标签中保留。初版数值集中于 [scripts/mod_rules.gd](scripts/mod_rules.gd)，方便试玩微调。

按用户约定，后续 Mod 开发默认保留在本地；仅在用户明确要求上传、推送或发布时更新 GitHub。详见 [AGENTS.md](AGENTS.md)。

2026-10-06：阳光收集新增飞回槽位、缩小和计数强调的表现，保持点击入账一次，支持暂停、并发和结算清理。预览位于本地 `build/sun-collection.mp4`。
