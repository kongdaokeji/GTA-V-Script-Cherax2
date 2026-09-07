-- Mission Assistant 统一运行时

local Runtime = {
    Name = "Runtime"
}

local App

local NATIVES = {
    DISABLE_CONTROL_ACTION = 0xFE99B66D079CF6BC,
    DISABLE_PLAYER_FIRING = 0x5E6CC07646BBEAB8,
    SET_USE_ADJUSTED_MOUSE_COORDS = 0x5B73C77D9EB66E24,
    SET_CURSOR_POSITION = 0xFC695459D4D0E219
}

local MOUSE_RESTORE_PASSES = 4

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

-- 游戏重启或其他 UI 可能改变该全局输入状态。Cherax 的 ImGui 在读取
-- 鼠标之前统一切回未调整坐标，避免首次打开时使用不同的坐标映射。
local function force_unadjusted_mouse_coords()
    if not Natives or type(Natives.InvokeVoid) ~= "function" then return false end
    return pcall(
        Natives.InvokeVoid,
        NATIVES.SET_USE_ADJUSTED_MOUSE_COORDS,
        false
    )
end

local function clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function clamp_mouse_axis(value)
    if type(value) ~= "number" or value ~= value then return nil end
    return clamp(value, 0, 1)
end

local function mouse_state(ui)
    if type(ui.MousePositionState) ~= "table" then
        ui.MousePositionState = {
            RestorePending = false,
            RestorePasses = 0
        }
    end
    return ui.MousePositionState
end

local function mouse_resolution()
    if not ImGui or type(ImGui.GetDisplaySize) ~= "function" then return nil, nil end
    local ok, width, height = pcall(ImGui.GetDisplaySize)
    if not ok then return nil, nil end
    width, height = tonumber(width), tonumber(height)
    if not width or not height or width <= 0 or height <= 0 then return nil, nil end
    return width, height
end

local function read_mouse_pos()
    force_unadjusted_mouse_coords()
    if not ImGui or type(ImGui.GetMousePos) ~= "function" then return nil, nil end
    local ok, x, y = pcall(ImGui.GetMousePos)
    if not ok then return nil, nil end
    x, y = tonumber(x), tonumber(y)
    if not x or not y or x ~= x or y ~= y then return nil, nil end
    return x, y
end

local function set_native_cursor_normalized(x, y)
    x, y = clamp_mouse_axis(x), clamp_mouse_axis(y)
    if x == nil or y == nil then return false end
    if not Natives or type(Natives.InvokeBool) ~= "function" then return false end

    force_unadjusted_mouse_coords()
    local ok, result = pcall(
        Natives.InvokeBool,
        NATIVES.SET_CURSOR_POSITION,
        x,
        y
    )

    return ok and result == true
end

local function save_mouse_pos(ui)
    local x, y = read_mouse_pos()
    local width, height = mouse_resolution()
    if x == nil or y == nil or width == nil or height == nil then return false end

    x = clamp(x, 0, width)
    y = clamp(y, 0, height)

    local state = mouse_state(ui)
    state.SavedPixelX = x
    state.SavedPixelY = y
    state.SavedNormalizedX = clamp_mouse_axis(x / width)
    state.SavedNormalizedY = clamp_mouse_axis(y / height)
    state.SavedDisplayWidth = width
    state.SavedDisplayHeight = height
    return true
end

local function queue_mouse_restore(ui)
    local state = mouse_state(ui)
    local has_pixels = tonumber(state.SavedPixelX) ~= nil
        and tonumber(state.SavedPixelY) ~= nil
    local has_normalized = clamp_mouse_axis(state.SavedNormalizedX) ~= nil
        and clamp_mouse_axis(state.SavedNormalizedY) ~= nil

    state.RestorePending = has_pixels or has_normalized
    state.RestorePasses = 0
    return state.RestorePending
end

local function restore_mouse_pos(ui)
    local state = mouse_state(ui)
    local width, height = mouse_resolution()
    if width == nil or height == nil then
        state.RestorePending = false
        state.RestorePasses = 0
        return false
    end

    local saved_x = tonumber(state.SavedPixelX)
    local saved_y = tonumber(state.SavedPixelY)
    local saved_nx = clamp_mouse_axis(state.SavedNormalizedX)
    local saved_ny = clamp_mouse_axis(state.SavedNormalizedY)
    local saved_width = tonumber(state.SavedDisplayWidth)
    local saved_height = tonumber(state.SavedDisplayHeight)
    local x, y, nx, ny

    local same_resolution = saved_width ~= nil and saved_height ~= nil
        and math.abs(saved_width - width) < 0.5
        and math.abs(saved_height - height) < 0.5

    if same_resolution and saved_x ~= nil and saved_y ~= nil then
        x = clamp(saved_x, 0, width)
        y = clamp(saved_y, 0, height)
        nx = clamp_mouse_axis(x / width)
        ny = clamp_mouse_axis(y / height)
    elseif saved_nx ~= nil and saved_ny ~= nil then
        nx, ny = saved_nx, saved_ny
        x, y = nx * width, ny * height
    elseif saved_x ~= nil and saved_y ~= nil then
        x = clamp(saved_x, 0, width)
        y = clamp(saved_y, 0, height)
        nx = clamp_mouse_axis(x / width)
        ny = clamp_mouse_axis(y / height)
    end

    state.RestorePending = false
    if x == nil or y == nil or nx == nil or ny == nil then
        state.RestorePasses = 0
        return false
    end

    state.RestoreTargetX = x
    state.RestoreTargetY = y
    state.RestoreNormalizedX = nx
    state.RestoreNormalizedY = ny

    if set_native_cursor_normalized(nx, ny) then
        state.RestorePasses = MOUSE_RESTORE_PASSES
        return true
    end

    state.RestorePasses = 0
    return false
end

local function correct_restored_mouse_pos(ui)
    local state = mouse_state(ui)
    local passes = tonumber(state.RestorePasses) or 0
    if passes <= 0 then return end

    local target_x = tonumber(state.RestoreTargetX)
    local target_y = tonumber(state.RestoreTargetY)
    local current_x, current_y = read_mouse_pos()
    local width, height = mouse_resolution()
    if target_x == nil or target_y == nil or current_x == nil or current_y == nil
        or width == nil or height == nil then
        state.RestorePasses = 0
        return
    end

    local error_x = target_x - current_x
    local error_y = target_y - current_y
    if math.abs(error_x) <= 1 and math.abs(error_y) <= 1 then
        state.RestorePasses = 0
        return
    end

    local nx = clamp_mouse_axis(
        (tonumber(state.RestoreNormalizedX) or (target_x / width))
        + error_x / width
    )
    local ny = clamp_mouse_axis(
        (tonumber(state.RestoreNormalizedY) or (target_y / height))
        + error_y / height
    )
    if nx == nil or ny == nil then
        state.RestorePasses = 0
        return
    end

    state.RestoreNormalizedX = nx
    state.RestoreNormalizedY = ny
    if not set_native_cursor_normalized(nx, ny) then
        state.RestorePasses = 0
        return
    end
    state.RestorePasses = passes - 1
end

local function update_mouse_restore(ui)
    local state = mouse_state(ui)
    if state.RestorePending then
        -- 该调用位于 CaptureMouseFromApp(true) 之后，确保 Cherax 已先建立鼠标捕获。
        restore_mouse_pos(ui)
        return
    end
    correct_restored_mouse_pos(ui)
end

local function set_window_visible(visible)
    if not App or not App.Data or not App.Data.State then return false end
    local ui = App.Data.State.Ui
    local next_visible = visible == true
    local was_visible = ui.Visible == true
    if next_visible == was_visible then return true end

    local state = mouse_state(ui)
    if was_visible and not next_visible then
        save_mouse_pos(ui)
        state.RestorePending = false
        state.RestorePasses = 0
    end

    ui.Visible = next_visible
    if next_visible then
        force_unadjusted_mouse_coords()
        queue_mouse_restore(ui)
    end
    return true
end

local function capture_and_block_mouse(ui)
    if not ui.Visible then
        return
    end

    force_unadjusted_mouse_coords()
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

            local saved = App.Hotkey and App.Hotkey.Set(vk, true) == true
            if not saved then
                App.Actions.Common.Toast("热键修改失败：无法保存 Mission/hotkey.cfg", 5000)
                return
            end

            ui.ToggleKey = vk
            local key_name = App.Hotkey.ToggleKeyName(vk)
            App.Actions.Common.Toast("显示/隐藏热键已设为 " .. key_name, 3000)
            return
        end
    end
end

function Runtime.Init(app)
    App = app

    -- 必须早于第一次 ImGui 鼠标读取，不能等到窗口重新打开时才设置。
    force_unadjusted_mouse_coords()
    App.Runtime.SetWindowVisible = set_window_visible

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
                -- 兜底：窗口不可见时绝不能继续处于热键捕获状态。
                ui.RebindingKey = false
                ui.RebindBaseline = nil
                ImGui.CaptureMouseFromApp(false)
                return
            end

            capture_and_block_mouse(ui)
            update_mouse_restore(ui)
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
    app.Runtime.SetWindowVisible = nil
    App = nil
end

return Runtime
