local source = debug.getinfo(1, "S").source:gsub("^@", "")
local mission_root = assert(source:match("^(.*[/\\])tests[/\\]runtime_mouse_mock%.lua$"),
    "unable to resolve CheraxA Mission root")

local SET_USE_ADJUSTED_MOUSE_COORDS = 0x5B73C77D9EB66E24
local SET_CURSOR_POSITION = 0xFC695459D4D0E219

local current_mock
local active_harness
local next_generation = 1
local completed_cases = 0

local function pop(queue, fallback)
    if #queue == 0 then return fallback end
    return table.remove(queue, 1)
end

local function make_mock()
    return {
        display = { width = 1280, height = 720 },
        mouse = { x = 100, y = 100 },
        mouse_mode = nil,
        adjusted = false,
        adjusted_failures = 0,
        adjusted_reads = 0,
        writes_while_adjusted = 0,
        native_results = {},
        native_result = true,
        native_delay = 0,
        present_serial = 0,
        pending_warps = {},
        write_attempts = {},
        successful_writes = {},
        applied_warps = {},
        capture_events = {},
        capture_failures = 0,
        handlers = {},
        next_handler = 1,
        max_writes_in_present = 0,
    }
end

local function apply_warp(mock, warp)
    local x = warp.nx * mock.display.width
    local y = warp.ny * mock.display.height
    mock.mouse.x, mock.mouse.y = x, y
    mock.applied_warps[#mock.applied_warps + 1] = {
        present = mock.present_serial,
        x = x,
        y = y,
        nx = warp.nx,
        ny = warp.ny,
    }
end

local function apply_pending_warps(mock)
    local remaining = {}
    for _, warp in ipairs(mock.pending_warps) do
        if warp.due_present <= mock.present_serial then
            apply_warp(mock, warp)
        else
            remaining[#remaining + 1] = warp
        end
    end
    mock.pending_warps = remaining
end

eLuaEvent = { ON_PRESENT = 1 }

EventMgr = {
    RegisterHandler = function(event, callback)
        local mock = assert(current_mock, "EventMgr used without an active mock")
        local id = mock.next_handler
        mock.next_handler = id + 1
        mock.handlers[id] = { event = event, callback = callback }
        if event == eLuaEvent.ON_PRESENT then mock.present_callback = callback end
        return id
    end,
    RemoveHandler = function(id)
        local mock = current_mock
        if not mock then return end
        local handler = mock.handlers[id]
        if handler and handler.callback == mock.present_callback then
            mock.present_callback = nil
        end
        mock.handlers[id] = nil
    end,
}

ImGui = {
    GetDisplaySize = function()
        local mock = assert(current_mock, "GetDisplaySize used without an active mock")
        return mock.display.width, mock.display.height
    end,
    GetMousePos = function()
        local mock = assert(current_mock, "GetMousePos used without an active mock")
        if mock.adjusted then mock.adjusted_reads = mock.adjusted_reads + 1 end
        if mock.mouse_mode == "invalid" then return -1000, -1000 end
        if mock.mouse_mode == "nil" then return nil, nil end
        if mock.mouse_mode == "error" then error("mock mouse read failure") end
        if mock.mouse_mode == "nan" then return 0 / 0, 0 / 0 end
        if mock.mouse_mode == "infinite" then return math.huge, -math.huge end
        return mock.mouse.x, mock.mouse.y
    end,
    CaptureMouseFromApp = function(captured)
        local mock = assert(current_mock, "CaptureMouseFromApp used without an active mock")
        mock.capture_events[#mock.capture_events + 1] = {
            present = mock.present_serial,
            captured = captured == true,
        }
        if captured == true and mock.capture_failures > 0 then
            mock.capture_failures = mock.capture_failures - 1
            error("mock mouse-capture failure")
        end
        mock.capture_owned = captured == true
    end,
}

Natives = {
    InvokeVoid = function(hash, ...)
        local mock = assert(current_mock, "InvokeVoid used without an active mock")
        local args = { ... }
        if hash == SET_USE_ADJUSTED_MOUSE_COORDS then
            if mock.adjusted_failures > 0 then
                mock.adjusted_failures = mock.adjusted_failures - 1
                error("mock adjusted-coordinate failure")
            end
            mock.adjusted = args[1] == true
        end
    end,
    InvokeBool = function(hash, ...)
        local mock = assert(current_mock, "InvokeBool used without an active mock")
        assert(hash == SET_CURSOR_POSITION, "unexpected BOOL native: " .. tostring(hash))
        local args = { ... }
        local outcome = pop(mock.native_results, mock.native_result)
        local event = {
            present = mock.present_serial,
            nx = args[1],
            ny = args[2],
            outcome = outcome,
        }
        mock.write_attempts[#mock.write_attempts + 1] = event
        if mock.adjusted then
            mock.writes_while_adjusted = mock.writes_while_adjusted + 1
        end
        if outcome == "error" then error("mock cursor Native failure") end
        if outcome ~= true then return false end

        mock.successful_writes[#mock.successful_writes + 1] = event
        local warp = { nx = args[1], ny = args[2] }
        if mock.native_delay > 0 then
            warp.due_present = mock.present_serial + mock.native_delay
            mock.pending_warps[#mock.pending_warps + 1] = warp
        else
            apply_warp(mock, warp)
        end
        return true
    end,
}

Utils = { IsKeyDown = function() return false end }
GTA = { GetLocalPlayerId = function() return 0 end }

local Runtime = assert(dofile(mission_root .. "lib/runtime.lua"),
    "runtime.lua did not return a module")

local function new_harness()
    if active_harness then
        Runtime.Shutdown(active_harness.app)
        active_harness = nil
    end

    local mock = make_mock()
    current_mock = mock
    local ui = {
        Visible = true,
        ToggleKey = 0x22,
        ToggleKeyWasDown = false,
        RebindingKey = false,
        RebindBaseline = nil,
        BlockGameMouse = false,
        MousePositionState = {},
    }
    local app = {
        Generation = next_generation,
        Runtime = { LoaderActive = true },
        Data = { State = { Ui = ui } },
        Actions = { Common = { Toast = function() end } },
        Hotkey = {
            Get = function() return 0x22 end,
            Set = function() return true end,
            IsValidKey = function() return true end,
            ToggleKeyName = function() return "PgDn" end,
        },
        Gui = { MainWindow = {} },
        Widgets = { Cursor = { Draw = function() end } },
    }
    next_generation = next_generation + 1
    app.Gui.MainWindow.Draw = function() end
    app.Gui.MainWindow.Toggle = function()
        return app.Runtime.SetWindowVisible(not ui.Visible)
    end

    MissionApp = app
    assert(Runtime.Init(app), "Runtime.Init failed")

    local harness = { app = app, ui = ui, mock = mock }
    function harness:state()
        return self.ui.MousePositionState
    end
    function harness:set_mouse(x, y, mode)
        self.mock.mouse.x, self.mock.mouse.y = x, y
        self.mock.mouse_mode = mode
    end
    function harness:set_display(width, height)
        self.mock.display.width, self.mock.display.height = width, height
    end
    function harness:set_visible(visible)
        assert(self.app.Runtime.SetWindowVisible(visible) == true,
            "SetWindowVisible failed")
    end
    function harness:present()
        local callback = assert(self.mock.present_callback, "ON_PRESENT callback missing")
        self.mock.present_serial = self.mock.present_serial + 1
        apply_pending_warps(self.mock)
        local attempts_before = #self.mock.write_attempts
        callback()
        local writes = #self.mock.write_attempts - attempts_before
        if writes > self.mock.max_writes_in_present then
            self.mock.max_writes_in_present = writes
        end
        assert(writes <= 1,
            "one ON_PRESENT issued multiple SET_CURSOR_POSITION calls: " .. tostring(writes))
    end
    function harness:frames(count)
        for _ = 1, count do self:present() end
    end
    function harness:wait_for_writes(count, limit)
        for _ = 1, limit or 24 do
            if #self.mock.write_attempts >= count then return true end
            self:present()
        end
        return #self.mock.write_attempts >= count
    end
    function harness:wait_for_successes(count, limit)
        for _ = 1, limit or 24 do
            if #self.mock.successful_writes >= count then return true end
            self:present()
        end
        return #self.mock.successful_writes >= count
    end
    function harness:wait_until_idle(limit)
        for _ = 1, limit or 64 do
            if self:state().RestoreState == nil then return true end
            self:present()
        end
        return self:state().RestoreState == nil
    end
    active_harness = harness
    return harness
end

local function assert_mouse(harness, expected_x, expected_y, message)
    local epsilon = 0.01
    local mouse = harness.mock.mouse
    assert(math.abs(mouse.x - expected_x) <= epsilon
        and math.abs(mouse.y - expected_y) <= epsilon,
        string.format("%s: expected %.3f,%.3f, got %.3f,%.3f",
            message, expected_x, expected_y, mouse.x, mouse.y))
end

local function save_and_hide(harness, x, y)
    harness:set_mouse(x, y)
    harness:present()
    harness:set_visible(false)
end

local function run_case(name, callback)
    local harness = new_harness()
    local ok, err = pcall(callback, harness)
    Runtime.Shutdown(harness.app)
    active_harness = nil
    if not ok then error(name .. ": " .. tostring(err), 0) end
    completed_cases = completed_cases + 1
end

run_case("same-resolution exact pixels", function(h)
    h:set_display(1366, 768)
    save_and_hide(h, 517, 293)
    h:set_mouse(37, 41)
    h:set_visible(true)
    assert(h:wait_until_idle(24), "restore did not finish")
    assert_mouse(h, 517, 293, "same-resolution restore lost exact pixels")
    assert(#h.mock.successful_writes >= 1, "restore never wrote the cursor")
end)

run_case("invalid close sample falls back to current cycle", function(h)
    h:set_mouse(413, 287)
    h:present()
    h:set_mouse(-3.402823466e38, -3.402823466e38)
    h:set_visible(false)
    h:set_mouse(91, 63)
    h:set_visible(true)
    assert(h:wait_until_idle(24), "fallback restore did not finish")
    assert_mouse(h, 413, 287, "close-time sentinel replaced the valid cycle sample")
end)

run_case("cycle without a valid sample clears old snapshot", function(h)
    save_and_hide(h, 640, 360)
    h:set_mouse(80, 60, "invalid")
    h:set_visible(true)
    h:frames(4)
    assert(#h.mock.write_attempts == 0, "invalid reopen performed a blind write")
    h:set_visible(false)

    h:set_mouse(155, 99)
    local attempts_before = #h.mock.write_attempts
    h:set_visible(true)
    h:frames(12)
    assert(#h.mock.write_attempts == attempts_before,
        "a previous cycle's snapshot survived an all-invalid cycle")
    assert_mouse(h, 155, 99, "cleared old snapshot still moved the cursor")
end)

run_case("capture write and verify cross presents", function(h)
    save_and_hide(h, 700, 390)
    h:set_mouse(70, 50)
    local captures_before = #h.mock.capture_events
    h:set_visible(true)
    h:present()
    assert(#h.mock.write_attempts == 0,
        "cursor was written in the first capture present")
    local capture = h.mock.capture_events[captures_before + 1]
    assert(capture and capture.captured == true,
        "first open present did not acquire mouse capture")
    assert(h:wait_for_successes(1, 12), "cursor write never occurred")
    local write_present = h.mock.successful_writes[1].present
    assert(write_present >= capture.present + 1,
        "capture and cursor write occurred in the same present")
    assert(h:state().RestoreState ~= nil,
        "restore verified in its write present")
    h:present()
    assert(h:state().RestoreState ~= nil,
        "restore verified without a complete intervening present")
    assert(h:wait_until_idle(12), "restore verification did not finish")
    assert(h.mock.present_serial >= write_present + 2,
        "write and verification did not span presents")
end)

run_case("transient Native false retries", function(h)
    save_and_hide(h, 777, 333)
    h:set_mouse(80, 70)
    h.mock.native_results = { false, true }
    h:set_visible(true)
    assert(h:wait_until_idle(32), "restore did not finish after Native retry")
    assert(#h.mock.write_attempts >= 2, "false Native result was not retried")
    assert_mouse(h, 777, 333, "retry did not restore the saved position")
end)

for _, delay in ipairs({ 1, 3 }) do
    run_case("delayed Native does not overshoot (" .. delay .. ")", function(h)
        save_and_hide(h, 960, 540)
        h:set_mouse(128, 72)
        h.mock.native_delay = delay
        h:set_visible(true)
        h:frames(32)
        assert_mouse(h, 960, 540,
            "delayed Native did not converge to the saved position")
        assert(#h.mock.applied_warps >= 1, "delayed Native never applied")
        for _, warp in ipairs(h.mock.applied_warps) do
            assert(warp.x >= 128 - 0.01 and warp.x <= 960 + 0.01
                and warp.y >= 72 - 0.01 and warp.y <= 540 + 0.01,
                string.format("delayed restore overshot to %.3f,%.3f", warp.x, warp.y))
        end
    end)
end

run_case("continuous invalid input never blind-writes", function(h)
    save_and_hide(h, 690, 370)
    h:set_mouse(60, 50, "invalid")
    h:set_visible(true)
    h:frames(64)
    assert(#h.mock.write_attempts == 0,
        "continuous invalid input caused a blind cursor write")
    local attempts_after_deadline = #h.mock.write_attempts
    h:frames(8)
    assert(#h.mock.write_attempts == attempts_after_deadline,
        "restore kept writing after continuous invalid input")
    assert_mouse(h, 60, 50, "invalid-input restore changed the physical cursor")
end)

run_case("resolution change during verify remaps target", function(h)
    h:set_display(1920, 1080)
    save_and_hide(h, 1440, 810)
    h:set_display(1600, 900)
    h:set_mouse(100, 90)
    h:set_visible(true)
    assert(h:wait_for_successes(1, 16), "resolution-B write never occurred")
    assert_mouse(h, 1200, 675, "saved point was not mapped into resolution B")

    h:set_display(1280, 720)
    h:frames(24)
    assert_mouse(h, 960, 540, "verify-time resolution C was not remapped")
    assert(#h.mock.applied_warps >= 2,
        "resolution change did not issue a replacement write")
    local last = h.mock.applied_warps[#h.mock.applied_warps]
    assert(math.abs(last.x - 960) <= 0.01 and math.abs(last.y - 540) <= 0.01,
        "last resolution-change write did not target resolution C")
end)

run_case("movement during opening wait cancels restore", function(h)
    save_and_hide(h, 850, 430)
    h:set_mouse(90, 70)
    h:set_visible(true)
    h:present()
    assert(#h.mock.write_attempts == 0, "opening wait wrote too early")
    h:set_mouse(240, 180)
    h:frames(16)
    assert(#h.mock.write_attempts == 0,
        "opening-wait user movement was pulled back")
    assert_mouse(h, 240, 180, "opening-wait user movement did not remain in place")
end)

run_case("movement after first write cancels retry", function(h)
    save_and_hide(h, 850, 430)
    h:set_mouse(90, 70)
    h:set_visible(true)
    assert(h:wait_for_successes(1, 16), "initial cursor write never occurred")
    assert_mouse(h, 850, 430, "initial cursor write did not land")
    h:set_mouse(842, 422)
    local attempts_before_move = #h.mock.write_attempts
    h:frames(16)
    assert(#h.mock.write_attempts == attempts_before_move,
        "restore issued another write after user movement")
    assert_mouse(h, 842, 422, "restore pulled the cursor after user movement")
end)

run_case("close during write present saves the ImGui input sample", function(h)
    save_and_hide(h, 900, 500)
    h:set_mouse(300, 200)

    local closed = false
    h.app.Gui.MainWindow.Draw = function()
        if not closed and #h.mock.successful_writes > 0 then
            closed = true
            h:set_visible(false)
        end
    end

    h:set_visible(true)
    for _ = 1, 16 do
        if closed then break end
        h:present()
    end
    assert(closed and h.ui.Visible == false,
        "mock close button did not close in the Native-write present")

    h.app.Gui.MainWindow.Draw = function() end
    h:set_mouse(40, 30)
    h:set_visible(true)
    assert(h:wait_until_idle(24), "same-present close snapshot did not restore")
    assert_mouse(h, 300, 200,
        "same-present Native warp replaced the close-button input sample")
end)

for _, target_was_observed in ipairs({ false, true }) do
    local suffix = target_was_observed and "observed" or "unobserved"
    run_case("capture failure after first write preserves movement (" .. suffix .. ")", function(h)
        save_and_hide(h, 850, 430)
        h:set_mouse(90, 70)
        h:set_visible(true)
        assert(h:wait_for_successes(1, 16), "initial cursor write never occurred")

        if target_was_observed then
            -- The first post-write present observes the target, but is still
            -- before verify because runtime requires a complete present gap.
            h:present()
        end

        local moved_x = target_was_observed and 715 or 705
        local moved_y = target_was_observed and 305 or 295
        h:set_mouse(moved_x, moved_y)
        h.mock.capture_failures = 1
        local attempts_before_move = #h.mock.write_attempts
        h:frames(20)
        assert(#h.mock.write_attempts == attempts_before_move,
            "capture recovery rewrote the cursor after user movement")
        assert_mouse(h, moved_x, moved_y,
            "capture recovery pulled back user movement")
    end)
end

run_case("observed target is remapped if capture fails during resize", function(h)
    h:set_display(1920, 1080)
    save_and_hide(h, 1440, 810)
    h:set_display(1600, 900)
    h:set_mouse(100, 90)
    h:set_visible(true)
    assert(h:wait_for_successes(1, 16), "initial resized write never occurred")
    h:present() -- ordinary frame observes the first target before verification

    h:set_display(1280, 720)
    h.mock.capture_failures = 1
    h:frames(28)
    assert_mouse(h, 960, 540,
        "capture failure treated an old-viewport observation as final")
end)

run_case("adjusted-coordinate failure retries safely", function(h)
    save_and_hide(h, 615, 355)
    h:set_mouse(75, 65)
    h.mock.adjusted = true
    h.mock.adjusted_failures = 4
    local adjusted_reads_before = h.mock.adjusted_reads
    h:set_visible(true)
    h:frames(36)
    assert(h.mock.adjusted_reads == adjusted_reads_before,
        "mouse was read while adjusted-coordinate setup was failing")
    assert(h.mock.writes_while_adjusted == 0,
        "cursor was written while adjusted coordinates were active")
    assert(#h.mock.successful_writes >= 1,
        "restore did not resume after adjusted-coordinate recovery")
    assert_mouse(h, 615, 355,
        "adjusted-coordinate recovery did not restore the cursor")
end)

if active_harness then Runtime.Shutdown(active_harness.app) end
active_harness = nil
current_mock = nil
MissionApp = nil

print(string.format("runtime mouse mock ok: %d cases", completed_cases))
