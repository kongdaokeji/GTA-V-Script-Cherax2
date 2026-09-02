-- Mission Assistant 自绘按钮

local Button = {
    Name = "Widgets.Button"
}

local App

function Button.Init(app)
    App = app
    App.Widgets.Button = Button
    return true
end

function Button.Draw(id, label, x, y, width, height, options)
    options = options or {}

    local core = App.Widgets.Core
    local metrics = App.Theme.Current.Metrics
    local enabled = options.Enabled ~= false
    local actual_height = height or metrics.ControlHeight
    local pressed, hovered, active = core.Hitbox(
        core.Id("Button", id),
        x,
        y,
        width,
        actual_height
    )
    local tooltip_hovered = hovered

    if not enabled then
        pressed = false
        hovered = false
        active = false
    end

    local offset = active and 1 or 0
    local fill = not enabled and "ControlDisabled"
        or active and (options.ActiveColor or "ButtonPressed")
        or hovered and (options.HoverColor or "ControlHover")
        or (options.Color or "Control")
    local border = not enabled and "ControlDisabledBorder"
        or (hovered or active) and "ControlBorderHover"
        or "ControlBorder"

    core.RectFilled(
        x,
        y + offset,
        x + width,
        y + offset + actual_height,
        fill,
        metrics.ControlRounding
    )
    core.Rect(
        x,
        y + offset,
        x + width,
        y + offset + actual_height,
        border,
        metrics.ControlRounding,
        1
    )
    core.CenteredText(
        x,
        y + offset,
        width,
        actual_height,
        label,
        enabled and "ControlText" or "TextDisabled"
    )

    if tooltip_hovered and options.Tooltip then
        core.Tooltip(options.Tooltip)
    end

    return pressed, hovered, active
end

function Button.Shutdown(app)
    if app.Widgets.Button == Button then
        app.Widgets.Button = nil
    end
    App = nil
end

return Button
