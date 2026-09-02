-- Mission Assistant 自绘开关

local Toggle = {
    Name = "Widgets.Toggle"
}

local App

function Toggle.Init(app)
    App = app
    App.Widgets.Toggle = Toggle
    return true
end

function Toggle.Draw(id, label, value, x, y, width, options)
    options = options or {}

    local core = App.Widgets.Core
    local metrics = App.Theme.Current.Metrics
    local enabled = options.Enabled ~= false
    local row_height = options.Height or 42
    local pressed, hovered, active = core.Hitbox(
        core.Id("Toggle", id),
        x,
        y,
        width,
        row_height
    )
    local changed = false

    if pressed and enabled then
        value = not value
        changed = true
    end

    local row_fill = not enabled and "ControlDisabled"
        or active and "ControlPressed"
        or hovered and "ToggleHover"
        or "Control"
    local row_border = not enabled and "ControlDisabledBorder"
        or (hovered or active) and "ControlBorderHover"
        or "ControlBorder"

    core.RectFilled(
        x,
        y,
        x + width,
        y + row_height,
        row_fill,
        metrics.ControlRounding
    )
    core.Rect(
        x,
        y,
        x + width,
        y + row_height,
        row_border,
        metrics.ControlRounding,
        1
    )

    local track_width = 52
    local track_height = 28
    local track_x = x + width - track_width - 8
    local track_y = y + math.floor((row_height - track_height) * 0.5)
    local label_color = not enabled and "TextDisabled"
        or value and "ToggleLabelOn"
        or "ControlLabel"

    core.Text(
        x + 12,
        y + (row_height - ImGui.GetTextLineHeight()) * 0.5,
        label,
        label_color
    )

    local track_color = not enabled and "ToggleTrackDisabled"
        or value and (hovered and "ToggleTrackOnHover" or "ToggleTrackOn")
        or "ToggleTrackOff"
    local track_border = not enabled and "ControlDisabledBorder"
        or value and "ToggleBorderOn"
        or "ToggleBorderOff"

    core.RectFilled(
        track_x,
        track_y,
        track_x + track_width,
        track_y + track_height,
        track_border,
        track_height * 0.5
    )
    core.RectFilled(
        track_x + 1,
        track_y + 1,
        track_x + track_width - 1,
        track_y + track_height - 1,
        track_color,
        (track_height - 2) * 0.5
    )

    local knob_x = value and (track_x + track_width - 14) or (track_x + 14)
    local knob_color = not enabled and "ToggleKnobDisabled"
        or value and "ToggleKnobOn"
        or "ToggleKnobOff"
    core.CircleFilled(
        knob_x,
        track_y + 14,
        9,
        knob_color,
        20
    )

    if hovered and options.Tooltip then
        core.Tooltip(options.Tooltip)
    end

    return value, changed
end

function Toggle.Shutdown(app)
    if app.Widgets.Toggle == Toggle then
        app.Widgets.Toggle = nil
    end
    App = nil
end

return Toggle
