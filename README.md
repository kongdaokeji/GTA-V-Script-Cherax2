# Mission Assistant

Cherax Lua 平台的 GTA Online 任务辅助菜单：模块化结构 + 自绘 UI，启动后直接进入主界面。

- 应用模块：46 个
- 显示/隐藏热键：默认 PgDn，可在右上角齿轮进入的设置中重绑定

## 如何运行

在 Cherax 中只加载根目录的 `Mission_Loader.lua`；其余代码与资源都在同级 `Mission/` 文件夹内，由 Loader 按顺序 require 并调用 `Init(MissionApp)`。

## 项目结构

```text
Mission_Loader.lua                 # 唯一启动入口
Mission/
├── lib/
│   ├── probe.lua                  # require 与共享 MissionApp 校验
│   ├── runtime.lua                # 唯一 ON_PRESENT：热键、鼠标捕获、游戏输入屏蔽
│   ├── hotkey.lua                 # 显示/隐藏热键配置（Mission/hotkey.cfg）
│   ├── mainwindow.lua             # 自绘主窗口：导航、右上角齿轮设置、拖动/缩放
│   ├── data/                      # 业务数据、地址、UI 状态（11 个）
│   ├── actions/                   # 游戏数据读写与 Native 操作（11 个）
│   ├── gui/
│   │   ├── router.lua             # 页面 ID 路由
│   │   └── pages/                 # 页面布局（11 个）
│   └── widgets/                   # 自绘控件（core/layout/button/toggle/input/select/scroll/cursor）
└── theme/
    ├── default.lua                # 经典深紫基础配色
    └── assets/                    # cursor.png
docs/
├── api/                           # 开发辅助 API 类型/函数声明，不参与运行时加载
│   ├── Cherax API.lua             # Cherax Lua API / 类型声明
│   └── ImGui.lua                  # Cherax ImGui API / 类型声明
└── examples/
    └── example.lua                # Cherax Lua 示例脚本（FeatureMgr / 回调 / 玩家功能）
```

## 页面

十个任务页：佩里科岛、赌场豪劫、末日豪劫、公寓抢劫、科兹中心、其他任务、任务载具、快捷功能、单人任务、资产管理。

## 分层约定（概要）

- Data 只保存数据与地址，不画 UI、不写游戏。
- Actions 拥有全部 Stat/Global/Local/Native 写入。
- Gui.Pages 只组织布局并调用 Actions，不直接写游戏数据。
- Widgets 是通用控件，不感知任务业务。
- Runtime 是唯一每帧入口，不包含任务逻辑。

## 开发 API 参考

`docs/api/` 中提供 Cherax 开发时使用的 Lua 类型与函数声明：

- `Cherax API.lua`：Cherax 平台 API、类、枚举及相关 LuaLS 注解。
- `ImGui.lua`：Cherax ImGui 绘制接口、控件、Flags 与相关 LuaLS 注解。
- `docs/examples/example.lua`：Cherax Lua 完整示例脚本（FeatureMgr 功能注册、回调触发器、玩家功能），演示平台 API 用法，独立加载运行，不属于 Mission Assistant 的运行时模块。

这两个文件用于代码补全、类型提示和 API 查询，不属于 Mission Assistant 的运行时模块，也不需要由 `Mission_Loader.lua` 加载。更新 Cherax/ImGui API 定义时，可直接替换对应文件。

## 设置与资源

- 右上角齿轮进入「设置」页，可重绑定显示/隐藏热键（默认 PgDn，保存于 `Mission/hotkey.cfg`；旧版 `Mission/theme/theme.cfg` 中的热键会自动迁移）。
- 经典界面基础配色定义在 `Mission/theme/default.lua`；`Mission/theme/assets/cursor.png` 为自定义鼠标纹理。
