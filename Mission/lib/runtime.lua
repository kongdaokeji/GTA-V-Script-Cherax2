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

-- Cherax owns ImGui capture while GTA owns SET_CURSOR_POSITION.  Neither the
-- local Cherax documentation nor the Native return value guarantees that a
-- write is observable by ImGui in the same present, so restoration is driven
-- as a bounded, cross-present state machine.
local MOUSE_RESTORE_MAX_FAILURES = 8
local MOUSE_RESTORE_MAX_WRITES = 2
local MOUSE_RESTORE_MAX_TOTAL_WRITES = 4
local MOUSE_RESTORE_MAX_FRAMES = 48
local MOUSE_RESTORE_TOLERANCE = 1.0
local MOUSE_RESTORE_WAIT_OFFSET = 2 -- leave one complete intervening present

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

local function finite_number(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return nil
    end
    return value
end

local function clamp_mouse_axis(value)
    value = finite_number(value)
    if value == nil then return nil end
    return clamp(value, 0, 1)
end

local function saved_mouse_axis(value)
    value = finite_number(value)
    if value == nil or value < 0 or value >= 1 then return nil end
    return value
end

local function mouse_state(ui)
    if type(ui.MousePositionState) ~= "table" then
        ui.MousePositionState = {}
    end
    local state = ui.MousePositionState
    state.FrameSerial = math.max(0, math.floor(finite_number(state.FrameSerial) or 0))
    state.Epoch = math.max(0, math.floor(finite_number(state.Epoch) or 0))
    if state.RestorePending ~= true then state.RestorePending = false end
    state.RestorePasses = math.max(0, math.floor(finite_number(state.RestorePasses) or 0))
    return state
end

local function mouse_resolution()
    if not ImGui or type(ImGui.GetDisplaySize) ~= "function" then return nil, nil end
    local ok, width, height = pcall(ImGui.GetDisplaySize)
    if not ok then return nil, nil end
    width, height = finite_number(width), finite_number(height)
    if not width or not height or width <= 0 or height <= 0 then return nil, nil end
    return width, height
end

local function read_mouse_pos()
    -- A failed coordinate-mode switch makes the ImGui sample unavailable for
    -- this present.  Mixing an adjusted read with an unadjusted write is worse
    -- than waiting and retrying on a later present.
    if not force_unadjusted_mouse_coords() then return nil, nil end
    if not ImGui or type(ImGui.GetMousePos) ~= "function" then return nil, nil end
    local ok, x, y = pcall(ImGui.GetMousePos)
    if not ok then return nil, nil end
    x, y = finite_number(x), finite_number(y)
    if x == nil or y == nil then return nil, nil end
    return x, y
end

local function mouse_pixels_in_viewport(x, y, width, height)
    x, y = finite_number(x), finite_number(y)
    width, height = finite_number(width), finite_number(height)
    if x == nil or y == nil or width == nil or height == nil
        or width <= 0 or height <= 0 then
        return false
    end

    -- ImGui can expose an off-screen sentinel while focus/capture is changing.
    -- It is an unavailable sample, not a position to clamp onto an edge.
    return x >= 0 and y >= 0 and x < width and y < height
end

local function set_native_cursor_normalized(x, y)
    x, y = clamp_mouse_axis(x), clamp_mouse_axis(y)
    if x == nil or y == nil then return false end
    if not Natives or type(Natives.InvokeBool) ~= "function" then return false end

    if not force_unadjusted_mouse_coords() then return false end
    local ok, result = pcall(
        Natives.InvokeBool,
        NATIVES.SET_CURSOR_POSITION,
        x,
        y
    )

    return ok and result == true
end

local function clear_saved_mouse_pos(state)
    state.SavedPixelX = nil
    state.SavedPixelY = nil
    state.SavedNormalizedX = nil
    state.SavedNormalizedY = nil
    state.SavedDisplayWidth = nil
    state.SavedDisplayHeight = nil
end

local function clear_open_cycle_mouse(state)
    state.CycleLastX = nil
    state.CycleLastY = nil
    state.CycleLastDisplayWidth = nil
    state.CycleLastDisplayHeight = nil
end

local function restore_target_matches(restore, x, y, width, height)
    local target_x = finite_number(restore and restore.WriteTargetX)
    local target_y = finite_number(restore and restore.WriteTargetY)
    local target_width = finite_number(restore and restore.WriteDisplayWidth)
    local target_height = finite_number(restore and restore.WriteDisplayHeight)
    x, y = finite_number(x), finite_number(y)
    width, height = finite_number(width), finite_number(height)
    return target_x ~= nil and target_y ~= nil
        and target_width ~= nil and target_height ~= nil
        and x ~= nil and y ~= nil and width ~= nil and height ~= nil
        and math.abs(target_width - width) < 0.5
        and math.abs(target_height - height) < 0.5
        and math.abs(target_x - x) <= MOUSE_RESTORE_TOLERANCE
        and math.abs(target_y - y) <= MOUSE_RESTORE_TOLERANCE
end

local function mouse_points_match(x1, y1, x2, y2)
    x1, y1 = finite_number(x1), finite_number(y1)
    x2, y2 = finite_number(x2), finite_number(y2)
    return x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil
        and math.abs(x1 - x2) <= MOUSE_RESTORE_TOLERANCE
        and math.abs(y1 - y2) <= MOUSE_RESTORE_TOLERANCE
end

local function record_open_cycle_mouse(ui, x, y, width, height)
    local state = mouse_state(ui)
    if ui.Visible ~= true or state.CycleActive ~= true
        or not mouse_pixels_in_viewport(x, y, width, height) then
        return false
    end

    state.CycleLastX = x
    state.CycleLastY = y
    state.CycleLastDisplayWidth = width
    state.CycleLastDisplayHeight = height

    local restore = state.RestoreState
    if restore and restore.Phase == "verify_wait"
        and restore_target_matches(restore, x, y, width, height) then
        restore.TargetObserved = true
    end

    -- Remember the pointer seen during the capture settling period.  If it is
    -- deliberately moved before the first write, relinquish ownership instead
    -- of snapping it back when the delayed restore starts.
    if restore and (restore.Writes or 0) == 0
        and restore.Phase == "write_wait"
        and restore.SettleX == nil then
        restore.SettleX = x
        restore.SettleY = y
        restore.SettleDisplayWidth = width
        restore.SettleDisplayHeight = height
        restore.SettleFrame = state.FrameSerial
    end
    return true
end

local function sample_open_cycle_mouse(ui)
    local state = mouse_state(ui)
    local width, height = mouse_resolution()
    local x, y
    if width ~= nil and height ~= nil then
        x, y = read_mouse_pos()
    end

    state.FrameSampleFrame = state.FrameSerial
    if mouse_pixels_in_viewport(x, y, width, height) then
        state.FrameSampleX = x
        state.FrameSampleY = y
        state.FrameSampleDisplayWidth = width
        state.FrameSampleDisplayHeight = height
        return record_open_cycle_mouse(ui, x, y, width, height)
    end

    state.FrameSampleX = nil
    state.FrameSampleY = nil
    state.FrameSampleDisplayWidth = nil
    state.FrameSampleDisplayHeight = nil
    return false
end

local function save_mouse_pos(ui)
    local state = mouse_state(ui)
    local x, y, width, height

    -- The close button runs after the restore driver in the same present.  Its
    -- ImGui click belongs to the input snapshot sampled before any Native write,
    -- so preserve that sample instead of accidentally saving a same-present warp.
    if state.CloseSampleArmed == true
        and state.FrameSampleFrame == state.FrameSerial then
        x = state.FrameSampleX
        y = state.FrameSampleY
        width = state.FrameSampleDisplayWidth
        height = state.FrameSampleDisplayHeight
    else
        width, height = mouse_resolution()
        if width ~= nil and height ~= nil then
            x, y = read_mouse_pos()
        end
    end

    -- Prefer the close-time sample, but only fall back to a sample collected
    -- during this same visible cycle.  Never revive a previous cycle's target.
    if mouse_pixels_in_viewport(x, y, width, height) then
        record_open_cycle_mouse(ui, x, y, width, height)
    else
        x = state.CycleLastX
        y = state.CycleLastY
        width = state.CycleLastDisplayWidth
        height = state.CycleLastDisplayHeight
    end

    if not mouse_pixels_in_viewport(x, y, width, height) then
        clear_saved_mouse_pos(state)
        return false
    end

    state.SavedPixelX = x
    state.SavedPixelY = y
    state.SavedNormalizedX = clamp_mouse_axis(x / width)
    state.SavedNormalizedY = clamp_mouse_axis(y / height)
    state.SavedDisplayWidth = width
    state.SavedDisplayHeight = height
    return state.SavedNormalizedX ~= nil and state.SavedNormalizedY ~= nil
end

local function resolve_mouse_restore_target(state)
    local width, height = mouse_resolution()
    if width == nil or height == nil then return nil end

    local saved_x = finite_number(state.SavedPixelX)
    local saved_y = finite_number(state.SavedPixelY)
    local saved_nx = saved_mouse_axis(state.SavedNormalizedX)
    local saved_ny = saved_mouse_axis(state.SavedNormalizedY)
    local saved_width = finite_number(state.SavedDisplayWidth)
    local saved_height = finite_number(state.SavedDisplayHeight)
    local x, y, nx, ny

    local same_resolution = saved_width ~= nil and saved_height ~= nil
        and math.abs(saved_width - width) < 0.5
        and math.abs(saved_height - height) < 0.5

    if same_resolution
        and mouse_pixels_in_viewport(saved_x, saved_y, saved_width, saved_height) then
        x, y = saved_x, saved_y
        nx, ny = clamp_mouse_axis(x / width), clamp_mouse_axis(y / height)
    elseif saved_nx ~= nil and saved_ny ~= nil then
        nx, ny = saved_nx, saved_ny
        x, y = nx * width, ny * height
    elseif mouse_pixels_in_viewport(saved_x, saved_y, width, height) then
        x, y = saved_x, saved_y
        nx, ny = clamp_mouse_axis(x / width), clamp_mouse_axis(y / height)
    end

    if nx == nil or ny == nil
        or not mouse_pixels_in_viewport(x, y, width, height) then
        return nil
    end

    state.RestoreTargetX = x
    state.RestoreTargetY = y
    state.RestoreNormalizedX = nx
    state.RestoreNormalizedY = ny
    return {
        X = x,
        Y = y,
        NormalizedX = nx,
        NormalizedY = ny,
        DisplayWidth = width,
        DisplayHeight = height
    }
end

local function has_saved_mouse_pos(state)
    local has_normalized = saved_mouse_axis(state.SavedNormalizedX) ~= nil
        and saved_mouse_axis(state.SavedNormalizedY) ~= nil
    local has_pixels = finite_number(state.SavedPixelX) ~= nil
        and finite_number(state.SavedPixelY) ~= nil
    return has_normalized or has_pixels
end

local function finish_mouse_restore(state)
    state.RestoreState = nil
    state.RestorePending = false
    state.RestorePasses = 0
end

local function clear_written_restore_target(restore)
    restore.WriteTargetX = nil
    restore.WriteTargetY = nil
    restore.WriteDisplayWidth = nil
    restore.WriteDisplayHeight = nil
    restore.PreWriteX = nil
    restore.PreWriteY = nil
    restore.PreWriteDisplayWidth = nil
    restore.PreWriteDisplayHeight = nil
    restore.SettleX = nil
    restore.SettleY = nil
    restore.SettleDisplayWidth = nil
    restore.SettleDisplayHeight = nil
    restore.SettleFrame = nil
end

local function consume_mouse_restore_failure(state, restore)
    restore.Failures = (restore.Failures or 0) + 1
    if restore.Failures >= MOUSE_RESTORE_MAX_FAILURES then
        finish_mouse_restore(state)
        return false
    end
    return true
end

local function enter_capture_wait(state, restore, resume_phase)
    restore.ResumePhase = resume_phase or restore.ResumePhase
        or ((restore.Writes or 0) > 0 and "verify_wait" or "write_wait")
    restore.Phase = "capture_wait"
    restore.ReadyFrame = state.FrameSerial + 1
end

local function queue_mouse_restore(ui)
    local state = mouse_state(ui)
    state.Epoch = state.Epoch + 1
    finish_mouse_restore(state)
    if not has_saved_mouse_pos(state) then return false end

    state.RestorePending = true
    state.RestorePasses = MOUSE_RESTORE_MAX_WRITES + 1
    state.RestoreState = {
        Epoch = state.Epoch,
        Phase = "capture_wait",
        ResumePhase = "write_wait",
        ReadyFrame = state.FrameSerial,
        DeadlineFrame = state.FrameSerial + MOUSE_RESTORE_MAX_FRAMES,
        Failures = 0,
        Writes = 0,
        TotalWrites = 0,
        TargetObserved = false,
        RetryRequiresUnchanged = false
    }
    return true
end

local function write_mouse_restore_target(ui, state, restore)
    local target = resolve_mouse_restore_target(state)
    if not target then
        if consume_mouse_restore_failure(state, restore) then
            restore.Phase = "write_wait"
            restore.ReadyFrame = state.FrameSerial + 1
        end
        return
    end

    local had_written_target = finite_number(restore.WriteDisplayWidth) ~= nil
        and finite_number(restore.WriteDisplayHeight) ~= nil
    if had_written_target and not restore_target_matches(
        restore, target.X, target.Y, target.DisplayWidth, target.DisplayHeight) then
        restore.Writes = 0
        restore.TargetObserved = false
        restore.RetryRequiresUnchanged = false
        clear_written_restore_target(restore)
    end

    local before_x, before_y = read_mouse_pos()
    if not mouse_pixels_in_viewport(
        before_x, before_y, target.DisplayWidth, target.DisplayHeight) then
        if consume_mouse_restore_failure(state, restore) then
            enter_capture_wait(state, restore, "write_wait")
        end
        return
    end

    if math.abs(target.X - before_x) <= MOUSE_RESTORE_TOLERANCE
        and math.abs(target.Y - before_y) <= MOUSE_RESTORE_TOLERANCE then
        finish_mouse_restore(state)
        return
    end

    if (restore.Writes or 0) == 0 then
        local settle_same_viewport = finite_number(restore.SettleDisplayWidth) ~= nil
            and finite_number(restore.SettleDisplayHeight) ~= nil
            and math.abs(restore.SettleDisplayWidth - target.DisplayWidth) < 0.5
            and math.abs(restore.SettleDisplayHeight - target.DisplayHeight) < 0.5

        if not settle_same_viewport then
            restore.SettleX = before_x
            restore.SettleY = before_y
            restore.SettleDisplayWidth = target.DisplayWidth
            restore.SettleDisplayHeight = target.DisplayHeight
            restore.SettleFrame = state.FrameSerial
            restore.Phase = "write_wait"
            restore.ReadyFrame = state.FrameSerial + 1
            return
        end

        if restore.SettleFrame == state.FrameSerial then
            restore.Phase = "write_wait"
            restore.ReadyFrame = state.FrameSerial + 1
            return
        end

        if not mouse_points_match(
            before_x, before_y, restore.SettleX, restore.SettleY) then
            finish_mouse_restore(state)
            return
        end
    elseif restore.RetryRequiresUnchanged then
        local prewrite_same_viewport = finite_number(restore.PreWriteDisplayWidth) ~= nil
            and finite_number(restore.PreWriteDisplayHeight) ~= nil
            and math.abs(restore.PreWriteDisplayWidth - target.DisplayWidth) < 0.5
            and math.abs(restore.PreWriteDisplayHeight - target.DisplayHeight) < 0.5
        if not prewrite_same_viewport or not mouse_points_match(
            before_x, before_y, restore.PreWriteX, restore.PreWriteY) then
            finish_mouse_restore(state)
            return
        end
    end

    if (restore.Writes or 0) >= MOUSE_RESTORE_MAX_WRITES
        or (restore.TotalWrites or 0) >= MOUSE_RESTORE_MAX_TOTAL_WRITES then
        finish_mouse_restore(state)
        return
    end

    if not set_native_cursor_normalized(target.NormalizedX, target.NormalizedY) then
        if consume_mouse_restore_failure(state, restore) then
            enter_capture_wait(state, restore, "write_wait")
        end
        return
    end

    restore.Writes = (restore.Writes or 0) + 1
    restore.TotalWrites = (restore.TotalWrites or 0) + 1
    restore.WriteTargetX = target.X
    restore.WriteTargetY = target.Y
    restore.WriteDisplayWidth = target.DisplayWidth
    restore.WriteDisplayHeight = target.DisplayHeight
    restore.PreWriteX = before_x
    restore.PreWriteY = before_y
    restore.PreWriteDisplayWidth = target.DisplayWidth
    restore.PreWriteDisplayHeight = target.DisplayHeight
    restore.TargetObserved = false
    restore.RetryRequiresUnchanged = false
    state.RestorePending = false
    state.RestorePasses = math.max(0, MOUSE_RESTORE_MAX_WRITES - restore.Writes + 1)
    restore.Phase = "verify_wait"
    restore.ReadyFrame = state.FrameSerial + MOUSE_RESTORE_WAIT_OFFSET
end

local function update_mouse_restore(ui, capture_ready)
    local state = mouse_state(ui)
    local restore = state.RestoreState
    if not restore then return end

    if restore.Epoch ~= state.Epoch
        or state.FrameSerial > (restore.DeadlineFrame or state.FrameSerial) then
        finish_mouse_restore(state)
        return
    end

    if capture_ready ~= true then
        if restore.TargetObserved then
            local observed_target = resolve_mouse_restore_target(state)
            if observed_target and restore_target_matches(
                restore,
                observed_target.X,
                observed_target.Y,
                observed_target.DisplayWidth,
                observed_target.DisplayHeight
            ) then
                finish_mouse_restore(state)
                return
            end
            if observed_target then
                restore.Writes = 0
                restore.TargetObserved = false
                restore.RetryRequiresUnchanged = false
                clear_written_restore_target(restore)
            end
        end
        local resume_phase = restore.Phase == "capture_wait"
            and restore.ResumePhase or restore.Phase
        if restore.WriteDisplayWidth == nil then resume_phase = "write_wait" end
        if consume_mouse_restore_failure(state, restore) then
            enter_capture_wait(state, restore, resume_phase)
        end
        return
    end

    if state.FrameSerial < (restore.ReadyFrame or 0) then return end

    if restore.Phase == "capture_wait" then
        -- CaptureMouseFromApp has no readiness result.  A successful Lua call
        -- starts a fresh settling interval; never write in this same present.
        if (restore.Writes or 0) == 0 and restore.SettleX == nil
            and state.FrameSampleFrame == state.FrameSerial
            and mouse_pixels_in_viewport(
                state.FrameSampleX,
                state.FrameSampleY,
                state.FrameSampleDisplayWidth,
                state.FrameSampleDisplayHeight
            ) then
            -- Capture does not expose mouse-delta provenance.  Conservatively
            -- use the first captured sample as the opening baseline so an
            -- intentional move during the settling interval is never pulled back.
            restore.SettleX = state.FrameSampleX
            restore.SettleY = state.FrameSampleY
            restore.SettleDisplayWidth = state.FrameSampleDisplayWidth
            restore.SettleDisplayHeight = state.FrameSampleDisplayHeight
            restore.SettleFrame = state.FrameSerial
        end
        restore.Phase = restore.ResumePhase
            or ((restore.Writes or 0) > 0 and "verify_wait" or "write_wait")
        restore.ResumePhase = nil
        restore.ReadyFrame = state.FrameSerial + MOUSE_RESTORE_WAIT_OFFSET
        return
    end

    if restore.Phase == "write_wait" then
        write_mouse_restore_target(ui, state, restore)
        return
    end

    if restore.Phase ~= "verify_wait" then
        finish_mouse_restore(state)
        return
    end

    -- Resolve again at verification time.  A changed display maps the saved
    -- normalized point into the new viewport instead of chasing stale pixels.
    local target = resolve_mouse_restore_target(state)
    if not target then
        if consume_mouse_restore_failure(state, restore) then
            restore.ReadyFrame = state.FrameSerial + 1
        end
        return
    end

    if not restore_target_matches(
        restore, target.X, target.Y, target.DisplayWidth, target.DisplayHeight) then
        restore.Writes = 0
        restore.TargetObserved = false
        restore.RetryRequiresUnchanged = false
        clear_written_restore_target(restore)
        restore.Phase = "write_wait"
        restore.ReadyFrame = state.FrameSerial + 1
        return
    end

    local current_x, current_y = read_mouse_pos()
    if not mouse_pixels_in_viewport(
        current_x, current_y, target.DisplayWidth, target.DisplayHeight) then
        if restore.TargetObserved
            or (restore.Writes or 0) >= MOUSE_RESTORE_MAX_WRITES
            or (restore.TotalWrites or 0) >= MOUSE_RESTORE_MAX_TOTAL_WRITES then
            finish_mouse_restore(state)
            return
        end
        if consume_mouse_restore_failure(state, restore) then
            enter_capture_wait(state, restore, "verify_wait")
        end
        return
    end

    if math.abs(target.X - current_x) <= MOUSE_RESTORE_TOLERANCE
        and math.abs(target.Y - current_y) <= MOUSE_RESTORE_TOLERANCE then
        finish_mouse_restore(state)
        return
    end

    if restore.TargetObserved or (restore.Writes or 0) >= MOUSE_RESTORE_MAX_WRITES then
        finish_mouse_restore(state)
        return
    end

    -- Retry only if the cursor remains at the pre-write point.  A different
    -- mismatch is user/overlay movement, not calibration error to integrate.
    restore.RetryRequiresUnchanged = true
    restore.Phase = "write_wait"
    restore.ReadyFrame = state.FrameSerial + 1
end

local function set_mouse_capture(captured)
    if not ImGui or type(ImGui.CaptureMouseFromApp) ~= "function" then return false end
    return pcall(ImGui.CaptureMouseFromApp, captured == true)
end

local function restore_host_cursor_shape()
    if not ImGui or type(ImGui.SetMouseCursor) ~= "function"
        or type(ImGuiMouseCursor) ~= "table"
        or type(ImGuiMouseCursor.Arrow) ~= "number" then
        return false
    end
    return pcall(ImGui.SetMouseCursor, ImGuiMouseCursor.Arrow)
end

local function release_mouse_capture(ui)
    local state = mouse_state(ui)
    if state.CaptureOwned ~= true then return true end
    local released = set_mouse_capture(false)
    if released then state.CaptureOwned = false end
    return released
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
        state.Epoch = state.Epoch + 1
        finish_mouse_restore(state)
        state.CycleActive = false
    end

    ui.Visible = next_visible
    if next_visible then
        clear_open_cycle_mouse(state)
        state.CycleActive = true
        force_unadjusted_mouse_coords()
        queue_mouse_restore(ui)
    else
        release_mouse_capture(ui)
        restore_host_cursor_shape()
    end
    return true
end

local function capture_and_block_mouse(ui)
    if not ui.Visible then
        return
    end

    local coordinates_ready = force_unadjusted_mouse_coords()
    local capture_ready = set_mouse_capture(true)
    if capture_ready then
        mouse_state(ui).CaptureOwned = true
    end

    if not ui.BlockGameMouse then
        return coordinates_ready and capture_ready
    end

    local invoke_void = Natives and Natives.InvokeVoid
    local get_player_id = GTA and GTA.GetLocalPlayerId
    local player_ok, player_id = false, nil
    if type(get_player_id) == "function" then
        player_ok, player_id = pcall(get_player_id)
    end
    if player_ok and type(invoke_void) == "function" then
        pcall(
            invoke_void,
            NATIVES.DISABLE_PLAYER_FIRING,
            player_id,
            true
        )
    end

    if type(invoke_void) == "function" then
        for _, action in ipairs(MOUSE_GAME_ACTIONS) do
            pcall(
                invoke_void,
                NATIVES.DISABLE_CONTROL_ACTION,
                0,
                action,
                true
            )
        end
    end
    return coordinates_ready and capture_ready
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

    local ui = App.Data.State.Ui
    local state = mouse_state(ui)
    state.Epoch = state.Epoch + 1
    finish_mouse_restore(state)
    clear_open_cycle_mouse(state)
    state.CycleActive = ui.Visible == true
    state.CaptureOwned = false

    -- 必须早于第一次 ImGui 鼠标读取，不能等到窗口重新打开时才设置。
    force_unadjusted_mouse_coords()
    App.Runtime.SetWindowVisible = set_window_visible

    local runtime_app = app
    local runtime_generation = app.Generation

    App.Runtime.PresentHandler = EventMgr.RegisterHandler(
        eLuaEvent.ON_PRESENT,
        function()
            if App ~= runtime_app
                or runtime_app.Runtime.LoaderActive == false
                or runtime_app.Generation ~= runtime_generation
                or (type(MissionApp) == "table" and MissionApp ~= runtime_app) then
                return
            end

            local ui = runtime_app.Data.State.Ui
            local state = mouse_state(ui)
            state.FrameSerial = state.FrameSerial + 1

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
                release_mouse_capture(ui)
                return
            end

            local capture_ready = capture_and_block_mouse(ui)
            sample_open_cycle_mouse(ui)
            update_mouse_restore(ui, capture_ready)
            state.CloseSampleArmed = true
            local draw_ok, draw_error = pcall(App.Gui.MainWindow.Draw)
            state.CloseSampleArmed = false
            if not draw_ok then error(draw_error, 0) end

            -- 最后绘制统一自定义鼠标；不读取 ImGui 光标类型。
            App.Widgets.Cursor.Draw()
        end
    )

    return true
end

function Runtime.Shutdown(app)
    local ui = app and app.Data and app.Data.State and app.Data.State.Ui
    if ui then
        local state = mouse_state(ui)
        state.Epoch = state.Epoch + 1
        finish_mouse_restore(state)
        state.CycleActive = false
    end

    local handler = app.Runtime.PresentHandler
    if handler then
        pcall(EventMgr.RemoveHandler, handler)
        app.Runtime.PresentHandler = nil
    end

    set_mouse_capture(false)
    restore_host_cursor_shape()
    if ui then mouse_state(ui).CaptureOwned = false end
    app.Runtime.SetWindowVisible = nil
    if App == app then App = nil end
end

return Runtime
