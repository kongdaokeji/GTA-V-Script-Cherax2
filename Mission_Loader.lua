-- Mission Assistant 模块化加载入口
-- 正式模块使用 require()，并通过 Init(MissionApp) 显式注入共享应用状态。

local LOADER_NAME = "Mission Assistant Loader"
local APP_VERSION = "1.3"
local ARCHITECTURE_VERSION = 14
local PROBE_MODULE = "Mission.lib.probe"

-- 最终阶段：九个任务页面完成，并接入主题设置。
local APPLICATION_MODULES = {
    { Path = "Mission.lib.data.state",       Name = "Data.State" },
    { Path = "Mission.lib.data.perico",      Name = "Data.Perico" },
    { Path = "Mission.lib.data.casino",      Name = "Data.Casino" },
    { Path = "Mission.lib.data.doomsday",    Name = "Data.Doomsday" },
    { Path = "Mission.lib.data.apartment",   Name = "Data.Apartment" },
    { Path = "Mission.lib.data.kortz",       Name = "Data.Kortz" },
    { Path = "Mission.lib.data.other",       Name = "Data.Other" },
    { Path = "Mission.lib.data.vehicles",    Name = "Data.Vehicles" },
    { Path = "Mission.lib.data.quick",       Name = "Data.Quick" },
    { Path = "Mission.lib.data.solo",        Name = "Data.Solo" },
    { Path = "Mission.lib.data.asset",       Name = "Data.Asset" },
    { Path = "Mission.theme.default",        Name = "Theme.Default" },
    { Path = "Mission.theme.manager",        Name = "Theme.Manager" },
    { Path = "Mission.lib.widgets.core",     Name = "Widgets.Core" },
    { Path = "Mission.lib.widgets.layout",   Name = "Widgets.Layout" },
    { Path = "Mission.lib.widgets.button",   Name = "Widgets.Button" },
    { Path = "Mission.lib.widgets.toggle",   Name = "Widgets.Toggle" },
    { Path = "Mission.lib.widgets.input",    Name = "Widgets.Input" },
    { Path = "Mission.lib.widgets.select",   Name = "Widgets.Select" },
    { Path = "Mission.lib.widgets.scroll",   Name = "Widgets.Scroll" },
    { Path = "Mission.lib.widgets.cursor",   Name = "Widgets.Cursor" },
    { Path = "Mission.lib.actions.common",   Name = "Actions.Common" },
    { Path = "Mission.lib.actions.perico",   Name = "Actions.Perico" },
    { Path = "Mission.lib.actions.casino",   Name = "Actions.Casino" },
    { Path = "Mission.lib.actions.doomsday", Name = "Actions.Doomsday" },
    { Path = "Mission.lib.actions.apartment", Name = "Actions.Apartment" },
    { Path = "Mission.lib.actions.kortz",    Name = "Actions.Kortz" },
    { Path = "Mission.lib.actions.other",    Name = "Actions.Other" },
    { Path = "Mission.lib.actions.vehicles", Name = "Actions.Vehicles" },
    { Path = "Mission.lib.actions.quick",    Name = "Actions.Quick" },
    { Path = "Mission.lib.actions.solo",     Name = "Actions.Solo" },
    { Path = "Mission.lib.actions.asset",    Name = "Actions.Asset" },
    { Path = "Mission.lib.gui.pages.perico", Name = "Gui.Pages.Perico" },
    { Path = "Mission.lib.gui.pages.casino", Name = "Gui.Pages.Casino" },
    { Path = "Mission.lib.gui.pages.doomsday", Name = "Gui.Pages.Doomsday" },
    { Path = "Mission.lib.gui.pages.apartment", Name = "Gui.Pages.Apartment" },
    { Path = "Mission.lib.gui.pages.kortz",  Name = "Gui.Pages.Kortz" },
    { Path = "Mission.lib.gui.pages.other",  Name = "Gui.Pages.Other" },
    { Path = "Mission.lib.gui.pages.vehicles", Name = "Gui.Pages.Vehicles" },
    { Path = "Mission.lib.gui.pages.quick",  Name = "Gui.Pages.Quick" },
    { Path = "Mission.lib.gui.pages.solo",   Name = "Gui.Pages.Solo" },
    { Path = "Mission.lib.gui.pages.asset",  Name = "Gui.Pages.Asset" },
    { Path = "Mission.lib.gui.pages.theme",  Name = "Gui.Pages.Theme" },
    { Path = "Mission.lib.gui.router",       Name = "Gui.Router" },
    { Path = "Mission.lib.mainwindow",       Name = "Gui.MainWindow" },
    { Path = "Mission.lib.runtime",          Name = "Runtime" }
}

local previous_generation = 0
if type(MissionApp) == "table" then
    previous_generation = tonumber(MissionApp.Generation) or 0
end

-- 所有后续模块只通过该命名空间共享数据和接口，避免增加零散全局变量。
MissionApp = {
    Name = "Mission Assistant",
    Version = APP_VERSION,
    ArchitectureVersion = ARCHITECTURE_VERSION,
    Generation = previous_generation + 1,

    Paths = {
        Root = "Mission",
        Lib = "Mission/lib",
        Data = "Mission/lib/data",
        Actions = "Mission/lib/actions",
        Gui = "Mission/lib/gui",
        Pages = "Mission/lib/gui/pages",
        Widgets = "Mission/lib/widgets",
        Theme = "Mission/theme",
        Assets = "Mission/theme/assets"
    },

    ModuleNames = {
        Probe = PROBE_MODULE
    },

    Data = {},
    Actions = {},
    Widgets = {},
    Gui = {
        Pages = {}
    },
    Theme = {},
    Modules = {},

    Runtime = {
        LoaderActive = true,
        StartedAt = os.time()
    },

    Loader = {
        ForceReload = true,
        ReleaseRequireCache = true,
        LoadedOrder = {},
        AddedPackagePatterns = {},
        MenuRoot = nil,
        LuaRoot = nil,
        ExpectedProbeFile = nil,
        Unloading = false,
        OriginalPackagePath = type(package) == "table" and package.path or nil
    }
}

local App = MissionApp

local function notify(message, is_error)
    local text = string.format("[%s] %s", LOADER_NAME, message)

    if is_error then
        Logger.LogError(text)
    else
        Logger.LogInfo(text)
    end

    -- Toast 失败不应阻止 Loader 的诊断日志。
    pcall(function()
        GUI.AddToast(
            "任务助手",
            message,
            6000,
            eToastPos.BOTTOM_RIGHT
        )
    end)
end

local function normalize_path(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
end

local function join_path(base, relative)
    local left = normalize_path(base):gsub("/$", "")
    local right = normalize_path(relative):gsub("^/", "")
    return left .. "/" .. right
end

local function file_exists(path)
    local exists_ok, exists = pcall(FileMgr.DoesFileExist, path)
    return exists_ok and exists == true
end

local function prepend_package_pattern(pattern)
    if type(package) ~= "table" or type(package.path) ~= "string" then
        return false
    end

    if not package.path:find(pattern, 1, true) then
        package.path = pattern .. ";" .. package.path
        App.Loader.AddedPackagePatterns[#App.Loader.AddedPackagePatterns + 1] = pattern
    end

    return true
end

local function remove_added_package_patterns()
    if type(package) ~= "table" or type(package.path) ~= "string" then
        return
    end

    local added = {}
    for _, pattern in ipairs(App.Loader.AddedPackagePatterns) do
        added[pattern] = true
    end

    local retained = {}
    for entry in package.path:gmatch("[^;]+") do
        if not added[entry] then
            retained[#retained + 1] = entry
        end
    end

    package.path = table.concat(retained, ";")
    App.Loader.AddedPackagePatterns = {}
end

-- require() 直接从 Cherax 菜单根目录下的 Lua 文件夹搜索模块。
local function configure_package_path()
    if type(package) ~= "table" or type(package.path) ~= "string" then
        return false, "当前 Lua 环境未提供有效的 package.path"
    end

    local root_ok, menu_root = pcall(FileMgr.GetMenuRootPath)
    if not root_ok or type(menu_root) ~= "string" or menu_root == "" then
        return false, "FileMgr.GetMenuRootPath() 未返回有效路径"
    end

    menu_root = normalize_path(menu_root)
    local lua_root = join_path(menu_root, "Lua")
    local expected_probe = join_path(lua_root, "Mission/lib/probe.lua")

    App.Loader.MenuRoot = menu_root
    App.Loader.LuaRoot = lua_root
    App.Loader.ExpectedProbeFile = expected_probe

    -- prepend 会把后调用的模式放到最前，因此先放 ?/init.lua 目录模式，再放 ?.lua 普通模块模式。
    prepend_package_pattern(lua_root .. "/?/init.lua")
    prepend_package_pattern(lua_root .. "/?.lua")

    App.Loader.PackagePath = package.path
    App.Loader.ProbeFileExists = file_exists(expected_probe)

    Logger.LogInfo(
        string.format(
            "[%s] Cherax Lua 根目录：%s",
            LOADER_NAME,
            lua_root
        )
    )
    Logger.LogInfo(
        string.format(
            "[%s] Probe 预期路径：%s（存在：%s）",
            LOADER_NAME,
            expected_probe,
            tostring(App.Loader.ProbeFileExists)
        )
    )

    return true
end

-- 加载标准 Lua 模块，并在模块提供 Init 时显式注入当前 MissionApp。
function App.Loader.RequireModule(module_path, module_name)
    if type(module_path) ~= "string" or module_path == "" then
        return false, "模块名为空"
    end
    if type(require) ~= "function" then
        return false, "当前 Lua 环境未提供 require()"
    end

    if
        App.Loader.ForceReload and
        type(package) == "table" and
        type(package.loaded) == "table"
    then
        package.loaded[module_path] = nil
    end

    local require_ok, module_or_error = pcall(require, module_path)
    if not require_ok then
        return false, string.format(
            "require('%s') 失败：%s",
            module_path,
            tostring(module_or_error)
        )
    end

    if type(module_or_error) ~= "table" then
        return false, string.format(
            "模块 %s 必须 return table，实际返回：%s",
            module_path,
            type(module_or_error)
        )
    end

    local module = module_or_error
    if type(module.Init) == "function" then
        local init_ok, init_result, init_error = pcall(module.Init, App)
        if not init_ok then
            if type(package) == "table" and type(package.loaded) == "table" then
                package.loaded[module_path] = nil
            end
            return false, string.format(
                "初始化模块 %s 失败：%s",
                module_path,
                tostring(init_result)
            )
        end
        if init_result == false then
            if type(package) == "table" and type(package.loaded) == "table" then
                package.loaded[module_path] = nil
            end
            return false, string.format(
                "初始化模块 %s 未通过：%s",
                module_path,
                tostring(init_error or "模块返回 false")
            )
        end
    end

    local name = module_name or module.Name or module_path
    module.Name = module.Name or name
    module.Loaded = true
    module.Generation = App.Generation
    module.LoadedAt = os.time()
    module.ModulePath = module_path

    App.Modules[name] = module
    App.Loader.LoadedOrder[#App.Loader.LoadedOrder + 1] = name

    -- MissionApp.Modules 已接管模块生命周期，无需让全局 require 缓存长期持有模块。
    if
        App.Loader.ReleaseRequireCache and
        type(package) == "table" and
        type(package.loaded) == "table"
    then
        package.loaded[module_path] = nil
    end

    return true, module
end

function App.Loader.RequireModuleList(module_definitions)
    if type(module_definitions) ~= "table" then
        return false, "模块清单无效"
    end

    local loaded_count = 0

    for _, definition in ipairs(module_definitions) do
        local module_path = definition.Path
        local module_name = definition.Name
        local load_ok, module_or_error = App.Loader.RequireModule(
            module_path,
            module_name
        )

        if not load_ok then
            return false, string.format(
                "加载 %s 失败：%s",
                tostring(module_name or module_path),
                tostring(module_or_error)
            )
        end

        loaded_count = loaded_count + 1
    end

    return true, loaded_count
end

-- 统一释放 require 模块、package.path 修改和运行状态。
-- 该函数可由 ShouldUnload 循环和 ON_UNLOAD 重复调用，因此必须保持幂等。
function App.Loader.Shutdown(reason)
    if App.Loader.Unloading then
        return true
    end

    App.Loader.Unloading = true
    local started_at = Time.GetEpocheMs()

    Logger.LogInfo(
        string.format(
            "[%s] 开始卸载清理（触发源：%s）",
            LOADER_NAME,
            tostring(reason or "unknown")
        )
    )

    for index = #App.Loader.LoadedOrder, 1, -1 do
        local module_name = App.Loader.LoadedOrder[index]
        local module = App.Modules[module_name]

        if type(module) == "table" then
            local shutdown = module.Shutdown or module.Unload
            if type(shutdown) == "function" then
                local shutdown_ok, shutdown_error = pcall(shutdown, App)
                if not shutdown_ok then
                    Logger.LogError(
                        string.format(
                            "[%s] 模块 %s 卸载失败：%s",
                            LOADER_NAME,
                            tostring(module_name),
                            tostring(shutdown_error)
                        )
                    )
                end
            end

            if
                type(package) == "table" and
                type(package.loaded) == "table" and
                type(module.ModulePath) == "string"
            then
                package.loaded[module.ModulePath] = nil
            end

            module.Loaded = false
            App.Modules[module_name] = nil
        end
    end

    App.Loader.LoadedOrder = {}
    remove_added_package_patterns()
    App.Runtime.LoaderActive = false

    if type(collectgarbage) == "function" then
        pcall(collectgarbage, "collect")
    end

    local elapsed = Time.GetEpocheMs() - started_at
    Logger.LogInfo(
        string.format(
            "[%s] 卸载清理完成（%d ms）",
            LOADER_NAME,
            elapsed
        )
    )

    return true
end

-- 使用表对象身份验证 Init() 收到的就是当前 Loader 创建的 MissionApp。
App.Runtime.Probe = {
    Token = {
        Generation = App.Generation,
        CreatedAt = App.Runtime.StartedAt
    },
    ExpectedGeneration = App.Generation,
    Executed = false,
    Shared = false
}

local path_ok, path_error = configure_package_path()
if not path_ok then
    notify("配置 require 搜索路径失败：" .. tostring(path_error), true)
else
    local load_ok, module_or_error = App.Loader.RequireModule(
        App.ModuleNames.Probe,
        "Probe"
    )

    if not load_ok then
        App.Runtime.Probe.LoadError = tostring(module_or_error)
        notify("共享模块加载验证失败：" .. tostring(module_or_error), true)
    else
        local probe = App.Runtime.Probe
        local module = module_or_error
        local success =
            probe.Executed == true and
            probe.Shared == true and
            probe.ReturnedToken == probe.Token and
            App.Modules.Probe == module and
            module.Loaded == true and
            module.Generation == App.Generation

        if success then
            notify(
                string.format(
                    "require 模块验证成功（Generation %d）",
                    App.Generation
                ),
                false
            )

            local app_ok, app_result = App.Loader.RequireModuleList(
                APPLICATION_MODULES
            )

            if app_ok then
                App.Runtime.ApplicationReady = true
                notify(
                    string.format(
                        "Mission Assistant 最终版已启动（已加载 %d 个模块，显示/隐藏热键可在主题设置中自定义）",
                        app_result
                    ),
                    false
                )
            else
                App.Runtime.ApplicationReady = false
                notify(
                    "Mission Assistant 启动失败：" .. tostring(app_result),
                    true
                )
            end
        else
            notify(
                "Probe 模块已加载，但共享 MissionApp 校验未通过",
                true
            )
        end
    end
end

-- 生命周期只由 Loader 统一注册。ShouldUnload 负责尽早响应停止请求，
-- ON_UNLOAD 作为兜底；Shutdown() 的幂等保护会避免重复清理。
App.Runtime.UnloadHandler = EventMgr.RegisterHandler(
    eLuaEvent.ON_UNLOAD,
    function()
        App.Loader.Shutdown("ON_UNLOAD")
    end
)

App.Runtime.UnloadLoop = Script.RegisterLooped(function()
    if ShouldUnload() then
        App.Loader.Shutdown("ShouldUnload")
        return false
    end

    Script.Yield(100)
end)
