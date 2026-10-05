# 素材版本与首次运行

本项目使用的资源版本是 **PVZ 汉化2版**，本机对应目录为 `Plants_Vs_Zombies_V1.0.0.1051_CN_V2`（PVZ1 1.0.0.1051 CN V2）。这里的“汉化2版”指素材来源版本；项目自身的还原阶段是 **v1**，两者不是同一个版本号。

GitHub 仓库只包含程序源码、社区转换工具、测试和文档。原版图片、声音、动画转换结果、粒子参考数据、游戏程序、`main.pak`、本地版本归档与预览均不上传。仓库刚克隆后，尚缺 `assets/`，因此需要先导入资源再打开 Godot 或运行游戏。

## 从自己的本地安装导入

工具要求：Godot **4.7.2**、Python **3.9+**、Pillow **9.x–12.x**；本机已验证 Python 3.14.6 + Pillow 12.2。按下面顺序，在项目根目录执行：

```powershell
python -m pip install -r requirements.txt
python tools/prepare_assets.py '你的安装路径\Plants_Vs_Zombies_V1.0.0.1051_CN_V2'
```

导入器读取该目录的 `main.pak`，再按汉化2版本地覆盖规则读取外部 `images/`、`reanim/`。它不会修改原版安装。其他资源版本尚未验证，文件名或动画结构可能不一致。

生成的 `assets/` 包含六个角色场景及所用纹理、UI、破损图、声音和步态数据；完整解包缓存位于 `.source_assets/`。二者都被 `.gitignore` 排除。之后用 Godot 4.7.2 导入 `project.godot`，运行主场景即可。

如果 Godot 已在缺素材时打开过，导入完成后重新扫描资源或重开项目。`启动游戏.cmd` 优先使用相邻目录中的既有 Godot，也支持 PATH 中的 `godot` / `godot4`；没有可用命令时，可直接使用 Godot 项目管理器导入。

## 资源与工具的来源

- 原版资源由用户本地安装提供，不随公开仓库分发。
- `tools/pvz2godot/` 来自 [ec50n9/pvz2godot](https://github.com/ec50n9/pvz2godot)，参考提交 `ba9df9a5aaef7449dd7507d0d7d3993615fec239`，保留其 GPL-3.0 许可证。
- 本项目资源导入脚本和运行时角色表现代码由本项目编写；社区资料的实际采用范围见 [VERSIONS.md](VERSIONS.md)。

归档资源清单与 SHA-256 保存在用户本地 `versions/`。公开仓库不包含可直接运行的原版资源包，也不提供原版游戏下载。
