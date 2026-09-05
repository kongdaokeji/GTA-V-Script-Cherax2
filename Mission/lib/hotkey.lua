-- Mission Assistant 显示/隐藏热键配置
-- 原主题管理模块已移除；此处只保留热键的读取、保存与键名显示。

local Hotkey = {
    Name = "Hotkey"
}

local App

local DEFAULT_KEY = 0x22 -- PgDn (PageDown)

-- 使用常见 Windows 英文缩写显示虚拟键码名称。
local KEY_NAMES = {
    [0x08] = "Bksp", [0x09] = "Tab", [0x0D] = "Enter", [0x13] = "Pause",
    [0x14] = "Caps", [0x1B] = "Esc", [0x20] = "Space",
    [0x21] = "PgUp", [0x22] = "PgDn", [0x23] = "End", [0x24] = "Home",
    [0x25] = "←", [0x26] = "↑", [0x27] = "→", [0x28] = "↓",
    [0x2D] = "Ins", [0x2E] = "Del",
    [0x6A] = "Num*", [0x6B] = "Num+", [0x6C] = "NumEnter",
    [0x6D] = "Num-", [0x6E] = "Num.", [0x6F] = "Num/",
    [0x90] = "NumLock", [0x91] = "ScrLk",
    [0xBA] = ";", [0xBB] = "=", [0xBC] = ",", [0xBD] = "-",
    [0xBE] = ".", [0xBF] = "/", [0xC0] = "`",
    [0xDB] = "[", [0xDC] = "\\", [0xDD] = "]", [0xDE] = "'"
}
for i = 0x30, 0x39 do KEY_NAMES[i] = string.char(i) end
for i = 0x41, 0x5A do KEY_NAMES[i] = string.char(i) end
for i = 0x60, 0x69 do KEY_NAMES[i] = "Num" .. string.char(i - 0x60 + 0x30) end
for i = 0x70, 0x7B do KEY_NAMES[i] = "F" .. (i - 0x70 + 1) end

-- 与 Lexis 同步：鼠标键、修饰键、锁定键、Esc 和 Windows 键不可绑定。
local INVALID_HOTKEYS = {
    [0x01] = true, -- 鼠标左键
    [0x02] = true, -- 鼠标右键
    [0x04] = true, -- 鼠标中键
    [0x05] = true, -- 鼠标 X1
    [0x06] = true, -- 鼠标 X2
    [0x10] = true, -- Shift
    [0x11] = true, -- Ctrl
    [0x12] = true, -- Alt
    [0x14] = true, -- CapsLock
    [0x1B] = true, -- Esc（保留为取消捕获）
    [0x5B] = true, -- 左 Win
    [0x5C] = true, -- 右 Win
    [0x90] = true, -- NumLock
    [0x91] = true, -- ScrollLock
}

local CONFIG_KEY = "ToggleKey"

local function join(a, b)
    return tostring(a):gsub("\\", "/"):gsub("/$", "") .. "/"
        .. tostring(b):gsub("\\", "/"):gsub("^/", "")
end

local function win(p)
    return tostring(p):gsub("/", "\\")
end

local function valid_key(vk)
    vk = tonumber(vk)
    if not vk then return false end
    vk = math.floor(vk)
    if vk < 0x08 or vk > 0xFF then return false end
    return not INVALID_HOTKEYS[vk]
end

function Hotkey.ToggleKeyName(vk)
    vk = tonumber(vk) or Hotkey.Key
    vk = math.floor(vk)
    return KEY_NAMES[vk] or ("VK_0x" .. string.format("%02X", vk))
end

function Hotkey.Get()
    return Hotkey.Key
end

function Hotkey.IsValidKey(vk)
    return valid_key(vk)
end

function Hotkey.Save()
    return FileMgr.WriteFileContent(
        Hotkey.ConfigPath,
        CONFIG_KEY .. "=" .. tostring(Hotkey.Key) .. "\n",
        false
    ) == true
end

function Hotkey.Set(vk, save)
    if not valid_key(vk) then return false end
    Hotkey.Key = math.floor(tonumber(vk))
    if save then return Hotkey.Save() end
    return true
end

local function read_config_file(path)
    if not FileMgr.DoesFileExist(path) then return nil end
    local ok, text = pcall(FileMgr.ReadFileContent, path)
    if not ok or type(text) ~= "string" then return nil end
    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match("^([%w_]+)=(.*)$")
        if key == CONFIG_KEY then
            local vk = tonumber(value)
            if valid_key(vk) then return math.floor(vk) end
        end
    end
    return nil
end

local function load_key()
    local key = read_config_file(Hotkey.ConfigPath)
    if key then return key end
    -- 兼容旧版主题配置：只迁移 ToggleKey 一项。
    local legacy = join(App.Loader.LuaRoot, "Mission/theme/theme.cfg")
    return read_config_file(legacy) or DEFAULT_KEY
end

function Hotkey.Init(app)
    App = app
    Hotkey.ConfigPath = win(join(App.Loader.LuaRoot, "Mission/hotkey.cfg"))
    Hotkey.Key = load_key()
    App.Hotkey = Hotkey
    return true
end

function Hotkey.Shutdown(app)
    if app.Hotkey == Hotkey then app.Hotkey = nil end
    Hotkey.ConfigPath = nil
    Hotkey.Key = nil
    App = nil
end

return Hotkey
