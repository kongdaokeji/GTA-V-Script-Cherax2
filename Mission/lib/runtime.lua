-- Mission Assistant 统一运行时

local Runtime = {
    Name = "Runtime"
}

local App

local NATIVES = {
    DISABLE_CONTROL_ACTION = 0xFE99B66D079CF6BC,
    DISABLE_PLAYER_FIRING = 0x5E6CC07646BBEAB8
}

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

-- 可绑定热键的虚拟键码范围：排除鼠标键（1~7）与 0。
local REBIND_KEY_MIN = 8
local REBIND_KEY_MAX = 254
local REBIND_CANCEL_KEY = 0x1B -- Esc

-- toggle 键：GetAsyncKeyState 反映锁定状态（灯亮即判定为"按下"），
-- 不参与热键扫描，避免 NumLock 常亮导致监听永远无法就绪。
local REBIND_EXCLUDED = {
    [0x14] = true, -- CapsLock
    [0x90] = true, -- NumLock
    [0x91] = true, -- ScrollLock
}

local function scan_down_keys()
    local down = {}
    for vk = REBIND_KEY_MIN, REBIND_KEY_MAX do
        if not REBIND_EXCLUDED[vk] and Utils.IsKeyDown(vk) then
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

            if App.Theme.Manager then
                App.Theme.Manager.Set("ToggleKey", vk, true)
            end
            ui.ToggleKey = vk
            local key_name = App.Theme.Manager and App.Theme.Manager.ToggleKeyName(vk)
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
                local toggle_key = App.Theme.Manager
                    and App.Theme.Manager.Settings.ToggleKey or ui.ToggleKey
                local key_down = Utils.IsKeyDown(toggle_key)

                if key_down and not ui.ToggleKeyWasDown then
                    App.Gui.MainWindow.Toggle()
                end
                ui.ToggleKeyWasDown = key_down
            end

            if not ui.Visible then
                ImGui.CaptureMouseFromApp(false)
                return
            end

            capture_and_block_mouse(ui)
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
