-- Mission Assistant 统一运行时

local Runtime = {
    Name = "Runtime"
}

local App

-- 记录上一帧窗口是否可见；从隐藏切到可见的第一帧恢复保存的鼠标位置。
local mouse_was_visible = false

local NATIVES = {
    DISABLE_CONTROL_ACTION = 0xFE99B66D079CF6BC,
    DISABLE_PLAYER_FIRING = 0x5E6CC07646BBEAB8,
    GET_DISABLED_CONTROL_NORMAL = 0x11E65974A982637C, -- PAD::GET_DISABLED_CONTROL_NORMAL(int control, int action) -> float
    SET_CURSOR_POSITION = 0xFC695459D4D0E219          -- PAD::SET_CURSOR_POSITION(float x, float y) -> BOOL
}

local MOUSE_CURSOR_CONTROL_X = 239
local MOUSE_CURSOR_CONTROL_Y = 240

-- 任务助手打开时屏蔽鼠标视角、全部开火方式和滚轮武器切换。
local MOUSE_GAME_ACTIONS = {
    1,   -- INPUT_LOOK_LR
    2,   -- INPUT_LOOK_UD
    14,  -- INPUT_WEAPON_WHEEL_NEXT
    15,  -- INPUT_WEAPON_WHEEL_PREV
    16,  -- INPUT_SELECT_NEXT_WEAPON
    17,  -- INPUT_SELECT_PREV_WEAPON
    24,  -- INPUT_ATTACK
    25,  -- INPUT_AIM
    68,  -- INPUT_VEH_AIM
    69,  -- INPUT_VEH_ATTACK
    70,  -- INPUT_VEH_ATTACK2
    91,  -- INPUT_VEH_PASSENGER_AIM
    92,  -- INPUT_VEH_PASSENGER_ATTACK
    106, -- INPUT_VEH_MOUSE_CONTROL_OVERRIDE
    257  -- INPUT_ATTACK2
}

local function capture_and_block_mouse(ui)
    if not ui.Visible then
        return
    end

    ImGui.CaptureMouseFromApp(true)

    if not ui.BlockGameMouse then
        return
    end

    Natives.InvokeVoid(
        NATIVES.DISABLE_PLAYER_FIRING,
        GTA.GetLocalPlayerId(),
        true
    )

    for _, action in ipairs(MOUSE_GAME_ACTIONS) do
        Natives.InvokeVoid(
            NATIVES.DISABLE_CONTROL_ACTION,
            0,
            action,
            true
        )
    end
end

-- 窗口关闭前记住鼠标位置，重新打开时恢复（坐标均为归一化 0~1）。
local function clamp_mouse_axis(value)
    if type(value) ~= "number" then return nil end
    if value ~= value then return nil end -- NaN
    if value < 0 then return 0 end
    if value > 1 then return 1 end
    return value
end

local function read_mouse_pos()
    local ok_x, x = pcall(Natives.InvokeFloat, NATIVES.GET_DISABLED_CONTROL_NORMAL, 0, MOUSE_CURSOR_CONTROL_X)
    local ok_y, y = pcall(Natives.InvokeFloat, NATIVES.GET_DISABLED_CONTROL_NORMAL, 0, MOUSE_CURSOR_CONTROL_Y)
    if not ok_x or not ok_y then return nil, nil end
    return clamp_mouse_axis(x), clamp_mouse_axis(y)
end

local function save_mouse_pos(ui)
    local x, y = read_mouse_pos()
    if x ~= nil and y ~= nil then
        ui.MousePosX, ui.MousePosY = x, y
    end
end

local function restore_mouse_pos(ui)
    if ui.MousePosRestore ~= true then return end
    local x, y = clamp_mouse_axis(ui.MousePosX), clamp_mouse_axis(ui.MousePosY)
    if x == nil or y == nil then return end
    pcall(Natives.InvokeBool, NATIVES.SET_CURSOR_POSITION, x, y)
end

-- 与 Lexis 同步可绑定范围与过滤规则；Esc 仅用于取消捕获。
local REBIND_KEY_MIN = 0x08
local REBIND_KEY_MAX = 0xFF
local REBIND_CANCEL_KEY = 0x1B -- Esc

local function can_capture_key(vk)
    if vk == REBIND_CANCEL_KEY then return true end
    return App.Hotkey and App.Hotkey.IsValidKey(vk) == true
end

local function scan_down_keys()
    local down = {}
    for vk = REBIND_KEY_MIN, REBIND_KEY_MAX do
        if can_capture_key(vk) and Utils.IsKeyDown(vk) then
            down[vk] = true
        end
    end
    return down
end

local function update_rebinding(ui)
    -- 进入监听后的第一帧：记录当前已按下的键作为基线，后续只识别"新按下沿"。
    if ui.RebindBaseline == nil then
        ui.RebindBaseline = scan_down_keys()
        return
    end

    local down = scan_down_keys()
    for vk = REBIND_KEY_MIN, REBIND_KEY_MAX do
        if down[vk] and not ui.RebindBaseline[vk] then
            -- 捕获到一个新按下的键，退出监听并吞掉本次按键。
            ui.RebindingKey = false
            ui.RebindBaseline = nil
            ui.ToggleKeyWasDown = true

            if vk == REBIND_CANCEL_KEY then
                App.Actions.Common.Toast("已取消热键设置", 3000)
                return
            end

            if App.Hotkey then
                App.Hotkey.Set(vk, true)
            end
            ui.ToggleKey = vk
            local key_name = App.Hotkey and App.Hotkey.ToggleKeyName(vk)
                or tostring(vk)
            App.Actions.Common.Toast("显示/隐藏热键已设为 " .. key_name, 3000)
            return
        end
    end
end

function Runtime.Init(app)
    App = app

    App.Runtime.PresentHandler = EventMgr.RegisterHandler(
        eLuaEvent.ON_PRESENT,
        function()
            local ui = App.Data.State.Ui

            if ui.RebindingKey then
                update_rebinding(ui)
            else
                local toggle_key = App.Hotkey
                    and App.Hotkey.Get() or ui.ToggleKey
                local key_down = Utils.IsKeyDown(toggle_key)

                if key_down and not ui.ToggleKeyWasDown then
                    App.Gui.MainWindow.Toggle()
                end
                ui.ToggleKeyWasDown = key_down
            end

            if not ui.Visible then
                if mouse_was_visible then
                    -- 关闭瞬间读一次并保存；此后窗口隐藏期间不再读取，
                    -- 转视角产生的新坐标不会覆盖保存值。
                    save_mouse_pos(ui)
                end
                mouse_was_visible = false
                ImGui.CaptureMouseFromApp(false)
                return
            end

            capture_and_block_mouse(ui)

            if not mouse_was_visible then
                restore_mouse_pos(ui)
            end
            mouse_was_visible = true

            App.Gui.MainWindow.Draw()

            -- 最后绘制统一自定义鼠标；不读取 ImGui 光标类型。
            App.Widgets.Cursor.Draw()
        end
    )

    return true
end

function Runtime.Shutdown(app)
    local handler = app.Runtime.PresentHandler
    if handler then
        EventMgr.RemoveHandler(handler)
        app.Runtime.PresentHandler = nil
    end

    ImGui.CaptureMouseFromApp(false)
    App = nil
end

return Runtime
