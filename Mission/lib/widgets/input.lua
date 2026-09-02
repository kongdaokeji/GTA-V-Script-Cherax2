-- Mission Assistant 自绘数值输入
-- 键盘编辑由 Cherax ImGui 提供，视觉和布局采用统一自绘控件。

local Input = {
    Name = "Widgets.Input"
}

local App

local function clamp(value, minimum, maximum)
    if minimum ~= nil then value = math.max(minimum, value) end
    if maximum ~= nil then value = math.min(maximum, value) end
    return value
end

function Input.Init(app)
    App = app
    App.Widgets.Input = Input
    return true
end

function Input.Integer(id, label, value, x, y, width, options)
    options = options or {}

    local core = App.Widgets.Core
    local metrics = App.Theme.Current.Metrics
    local enabled = options.Enabled ~= false
    local row_height = options.Height or 42
    local box_width = math.min(
        190,
        math.max(116, math.floor(width * 0.42))
    )
    local box_x = x + width - box_width
    local box_y = y + 3
    local box_height = row_height - 6
    local old_value = math.floor(tonumber(value) or 0)
    local flags = ImGuiInputTextFlags.CharsDecimal

    if not enabled or options.ReadOnly then
        flags = flags | ImGuiInputTextFlags.ReadOnly
    end

    core.Text(
        x,
        y + (row_height - ImGui.GetTextLineHeight()) * 0.5,
        label,
        enabled and "ControlLabel" or "TextDisabled"
    )

    core.PushStyleColor(ImGuiCol.Text, enabled and "ControlText" or "TextDisabled")
    core.PushStyleColor(ImGuiCol.FrameBg, enabled and "Control" or "ControlDisabled")
    core.PushStyleColor(ImGuiCol.FrameBgHovered, enabled and "ControlHover" or "ControlDisabled")
    core.PushStyleColor(ImGuiCol.FrameBgActive, enabled and "ControlActive" or "ControlDisabled")
    core.PushStyleColor(ImGuiCol.Border, enabled and "ControlBorder" or "ControlDisabledBorder")
    ImGui.PushStyleVar(ImGuiStyleVar.FrameRounding, metrics.ControlRounding)
    ImGui.PushStyleVar(ImGuiStyleVar.FrameBorderSize, 1)
    ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, 10, metrics.InputVerticalPadding)

    ImGui.SetCursorScreenPos(box_x, box_y)
    ImGui.SetNextItemWidth(box_width)

    local new_value, used = ImGui.InputInt(
        core.Id("InputInt", id),
        old_value,
        0,
        0,
        flags
    )
    local hovered = ImGui.IsItemHovered()
    local active = ImGui.IsItemActive()
    local item_min_x, item_min_y = ImGui.GetItemRectMin()
    local item_max_x, item_max_y = ImGui.GetItemRectMax()

    ImGui.PopStyleVar(3)
    ImGui.PopStyleColor(5)

    -- 使用 ImGui 实际 Item 边界，不再用预估的 box 高度绘制二次轮廓。
    if active then
        core.Rect(
            item_min_x - 1,
            item_min_y - 1,
            item_max_x + 1,
            item_max_y + 1,
            "ControlActiveGlow",
            metrics.ControlRounding + 1,
            2
        )
        core.Rect(
            item_min_x,
            item_min_y,
            item_max_x,
            item_max_y,
            "ControlBorderActive",
            metrics.ControlRounding,
            1
        )
    elseif hovered and enabled then
        core.Rect(
            item_min_x,
            item_min_y,
            item_max_x,
            item_max_y,
            "ControlBorderHover",
            metrics.ControlRounding,
            1
        )
    end

    if hovered and options.Tooltip then
        core.Tooltip(options.Tooltip)
    end

    new_value = math.floor(tonumber(new_value) or old_value)
    new_value = clamp(new_value, options.Minimum, options.Maximum)

    if not enabled or options.ReadOnly then
        return old_value, false
    end

    return new_value, used or new_value ~= old_value
end

function Input.Shutdown(app)
    if app.Widgets.Input == Input then
        app.Widgets.Input = nil
    end
    App = nil
end

return Input
