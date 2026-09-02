# Mission Assistant

Cherax Lua 平台的 GTA Online 任务辅助菜单：模块化结构 + 自绘 UI，启动后直接进入主界面。

- 产品版本：1.3
- 应用模块：46 个
- 显示/隐藏热键：默认 PageDown，可在主题设置中重绑定

## 如何运行

在 Cherax 中只加载根目录的 `Mission_Loader.lua`；其余代码与资源都在同级 `Mission/` 文件夹内，由 Loader 按顺序 require 并调用 `Init(MissionApp)`。

## 项目结构

```text
Mission_Loader.lua                 # 唯一启动入口
Mission/
├── lib/
│   ├── probe.lua                  # require 与共享 MissionApp 校验
│   ├── runtime.lua                # 唯一 ON_PRESENT：热键、鼠标捕获、游戏输入屏蔽
│   ├── mainwindow.lua             # 自绘主窗口：导航、拖动/缩放、官方Q群入口
│   ├── data/                      # 业务数据、地址、UI 状态（11 个）
│   ├── actions/                   # 游戏数据读写与 Native 操作（11 个）
│   ├── gui/
│   │   ├── router.lua             # 页面 ID 路由
│   │   └── pages/                 # 页面布局（11 个）
│   └── widgets/                   # 自绘控件（core/layout/button/toggle/input/select/scroll/cursor）
└── theme/
    ├── default.lua                # 经典深紫基础主题
    ├── manager.lua                # 玻璃主题、背景扫描、鼠标规则
    └── assets/                    # cursor.png、cursor_glass.png、official_qq_group.png
docs/
└── api/                           # 开发辅助 API 类型/函数声明，不参与运行时加载
    ├── Cherax API.lua             # Cherax Lua API / 类型声明
    └── ImGui.lua                  # Cherax ImGui API / 类型声明
```

## 页面

十个任务页 + 主题设置：佩里科岛、赌场豪劫、末日豪劫、公寓抢劫、科兹中心、其他任务、任务载具、快捷功能、单人任务、资产管理。

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

这两个文件用于代码补全、类型提示和 API 查询，不属于 Mission Assistant 的运行时模块，也不需要由 `Mission_Loader.lua` 加载。更新 Cherax/ImGui API 定义时，可直接替换对应文件。

## 主题与资源

- 经典 / 玻璃两套界面，玻璃含浅色/深色遮罩与透明度控制。
- 显示/隐藏热键可在主题设置中重绑定，默认 PageDown。
- 自定义背景图可选放入 `Mission/theme/backgrounds/`，在主题设置中刷新。
- 主窗口底部有“官方Q群”入口，弹窗展示二维码，可复制链接与群号。
