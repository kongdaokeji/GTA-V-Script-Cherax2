-- Mission Assistant 自绘控件基础层

local Core = {
    Name = "Widgets.Core"
}

local App

local function get_theme()
    return App.Theme.Current
end

local function color(name)
    local theme = get_theme()
    return theme.Colors[name] or {255, 255, 255, 255}
end

function Core.Init(app)
    App = app
    App.Widgets.Core = Core
    return true
end

function Core.GetColor(name)
    return color(name)
end

function Core.GetColorFloats(name)
    local value = color(name)
    return value[1] / 255, value[2] / 255, value[3] / 255, value[4] / 255
end

function Core.PushStyleColor(index, color_name)
    local r, g, b, a = Core.GetColorFloats(color_name)
    ImGui.PushStyleColor(index, r, g, b, a)
end

function Core.Id(...)
    local parts = {"##Mission"}

    for index = 1, select("#", ...) do
        local value = tostring(select(index, ...))
        value = value:gsub("[^%w_]", "_")
        parts[#parts + 1] = value
    end

    return table.concat(parts, "_")
end

function Core.RectFilled(x1, y1, x2, y2, color_name, rounding)
    local value = color(color_name)
    ImGui.AddRectFilled(
        x1, y1, x2, y2,
        value[1], value[2], value[3], value[4],
        rounding or 0,
        0
    )
end

function Core.Rect(x1, y1, x2, y2, color_name, rounding, thickness)
    local value = color(color_name)
    ImGui.AddRect(
        x1, y1, x2, y2,
        value[1], value[2], value[3], value[4],
        rounding or 0,
        0,
        thickness or 1
    )
end

function Core.Line(x1, y1, x2, y2, color_name, thickness)
    local value = color(color_name)
    ImGui.AddLine(
        x1, y1, x2, y2,
        value[1], value[2], value[3], value[4],
        thickness or 1
    )
end

function Core.Circle(x, y, radius, color_name, segments, thickness)
    local value = color(color_name)
    ImGui.AddCircle(
        x,
        y,
        radius,
        value[1], value[2], value[3], value[4],
        segments or 20,
        thickness or 1
    )
end

function Core.CircleFilled(x, y, radius, color_name, segments)
    local value = color(color_name)
    ImGui.AddCircleFilled(
        x,
        y,
        radius,
        value[1], value[2], value[3], value[4],
        segments or 20
    )
end

function Core.TriangleFilled(x1, y1, x2, y2, x3, y3, color_name)
    local value = color(color_name)
    ImGui.AddTriangleFilled(
        x1, y1,
        x2, y2,
        x3, y3,
        value[1], value[2], value[3], value[4]
    )
end

function Core.Text(x, y, text, color_name)
    local value = color(color_name or "Text")
    ImGui.AddText(
        x,
        y,
        tostring(text or ""),
        value[1], value[2], value[3], value[4]
    )
end

function Core.CenteredText(x, y, width, height, text, color_name)
    local text_width, text_height = ImGui.CalcTextSize(tostring(text or ""))
    Core.Text(
        x + math.max(0, (width - text_width) * 0.5),
        y + math.max(0, (height - text_height) * 0.5),
        text,
        color_name
    )
end

function Core.Hitbox(id, x, y, width, height)
    ImGui.SetCursorScreenPos(x, y)
    ImGui.InvisibleButton(id, width, height)

    local hovered = ImGui.IsItemHovered()
    local active = ImGui.IsItemActive()
    local pressed = hovered and ImGui.IsMouseClicked(
        ImGuiMouseButton.ImGuiMouseButton_Left,
        false
    )

    -- 第一返回值统一为“按下沿”，不等待鼠标松开。
    return pressed, hovered, active
end

function Core.Tooltip(text)
    if text == nil or text == "" then
        return
    end

    Core.PushStyleColor(ImGuiCol.Text, "TooltipText")
    Core.PushStyleColor(ImGuiCol.PopupBg, "Tooltip")
    Core.PushStyleColor(ImGuiCol.Border, "TooltipBorder")
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 10, 8)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, 6)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupBorderSize, 1)

    ImGui.BeginTooltip()
    ImGui.TextUnformatted(tostring(text))
    ImGui.EndTooltip()

    ImGui.PopStyleVar(3)
    ImGui.PopStyleColor(3)
end

function Core.SidebarHitbox(item, x, y, width, height)
    local id = Core.Id("Sidebar", item.Id)
    ImGui.SetCursorScreenPos(x, y)
    ImGui.InvisibleButton(id, width, height)

    local hovered = ImGui.IsItemHovered()
    local active = ImGui.IsItemActive()
    local pressed = hovered and ImGui.IsMouseClicked(
        ImGuiMouseButton.ImGuiMouseButton_Left,
        false
    )

    return pressed, hovered, active
end

function Core.NavigationIcon(id, x, y, size, color_name, accent_name)
    local unit = size / 18
    local function px(value) return x + value * unit end
    local function py(value) return y + value * unit end
    local function line(x1, y1, x2, y2, name, thickness)
        Core.Line(px(x1), py(y1), px(x2), py(y2), name or color_name,
            (thickness or 1.25) * unit)
    end
    local function rect(rx, ry, rw, rh, name, radius)
        Core.RectFilled(px(rx), py(ry), px(rx + rw), py(ry + rh),
            name or color_name, (radius or 1) * unit)
    end
    local function ring(cx, cy, radius, name, thickness, segments)
        Core.Circle(px(cx), py(cy), radius * unit, name or color_name,
            segments or 12, (thickness or 1.25) * unit)
    end

    if id == "perico" then
        line(2, 14, 5, 12); line(5, 12, 9, 12); line(9, 12, 13, 13)
        line(13, 13, 16, 14); line(4, 16, 14, 16, accent_name, 1.15)
        line(9, 12, 10, 6, nil, 1.4); line(10, 6, 7, 3); line(7, 3, 4, 4)
        line(10, 6, 10, 2); line(10, 2, 12, 4); line(10, 6, 14, 3)
        line(14, 3, 16, 5); ring(4.5, 10.5, 1.45, accent_name, 1, 8)
    elseif id == "casino" then
        line(1.5, 5, 4.5, 2); line(4.5, 2, 10.5, 2); line(10.5, 2, 13, 5)
        line(13, 5, 7.5, 13); line(7.5, 13, 1.5, 5); line(1.8, 5, 12.7, 5)
        line(4.5, 2, 7.5, 13, nil, 1); line(10.5, 2, 7.5, 13, nil, 1)
        ring(13.2, 12.2, 3.1, nil, 1.2, 10); line(14.8, 9.5, 16, 10.4, accent_name, 1.4)
    elseif id == "doomsday" then
        line(9, 1.5, 6, 5.5); line(6, 5.5, 6, 13); line(6, 13, 4, 15)
        line(4, 15, 7.2, 14); line(7.2, 14, 10.8, 14); line(10.8, 14, 14, 15)
        line(14, 15, 12, 13); line(12, 13, 12, 5.5); line(12, 5.5, 9, 1.5)
        line(6.5, 6.2, 11.5, 6.2, accent_name, 1.15); line(9, 8, 9, 10.5, accent_name, 1.35)
        ring(9, 12, 0.7, accent_name, 1, 8); line(7, 16.2, 11, 16.2, accent_name, 1.2)
    elseif id == "apartment" then
        line(4, 16, 4, 4); line(4, 4, 14, 4); line(14, 4, 14, 16)
        line(2, 16, 16, 16); line(6, 4, 6, 2); line(6, 2, 12, 2); line(12, 2, 12, 4)
        rect(6, 7, 1.7, 1.7, accent_name, 0.4); rect(10.3, 7, 1.7, 1.7, accent_name, 0.4)
        rect(6, 10.5, 1.7, 1.7, accent_name, 0.4); rect(10.3, 10.5, 1.7, 1.7, accent_name, 0.4)
        line(8, 16, 8, 13); line(8, 13, 10, 13); line(10, 13, 10, 16)
    elseif id == "kortz" then
        line(2, 6, 9, 2); line(9, 2, 16, 6); line(3, 7, 15, 7, accent_name, 1.2)
        line(4.2, 8, 4.2, 14); line(9, 8, 9, 14); line(13.8, 8, 13.8, 14)
        line(3, 15, 15, 15); line(2, 17, 16, 17); ring(9, 4.8, 1.05, accent_name, 1, 8)
    elseif id == "other" then
        local boxes = {{2, 2}, {11, 2}, {2, 11}, {11, 11}}
        for index, box in ipairs(boxes) do
            local bx, by = box[1], box[2]
            rect(bx, by, 5, 5, index == 2 and accent_name or color_name, 1)
        end
    elseif id == "vehicles" then
        line(2, 12, 3.5, 7.5); line(3.5, 7.5, 6.5, 5); line(6.5, 5, 11.5, 5)
        line(11.5, 5, 14.5, 7.5); line(14.5, 7.5, 16, 12); line(16, 12, 15, 15)
        line(15, 15, 3, 15); line(3, 15, 2, 12); line(4, 8, 14, 8)
        rect(3.8, 10.5, 3, 1.5, accent_name, 0.6); rect(11.2, 10.5, 3, 1.5, accent_name, 0.6)
    elseif id == "quick" then
        line(11, 1, 4, 10, nil, 1.4); line(4, 10, 8, 10, nil, 1.4)
        line(8, 10, 6, 17, accent_name, 1.5); line(6, 17, 14, 8, nil, 1.4)
        line(14, 8, 10, 8, nil, 1.4); line(10, 8, 11, 1, nil, 1.4)
    elseif id == "solo" then
        ring(9, 5, 3, nil, 1.3, 12); line(4, 16, 4, 13)
        line(4, 13, 6.2, 10); line(6.2, 10, 11.8, 10); line(11.8, 10, 14, 13)
        line(14, 13, 14, 16); line(5, 16, 13, 16); line(7, 14.7, 11, 14.7, accent_name, 1.15)
    elseif id == "asset" then
        line(2, 6, 9, 2); line(9, 2, 16, 6)
        line(2, 6, 2, 16); line(16, 6, 16, 16); line(2, 16, 16, 16)
        rect(7.5, 9, 3, 7, accent_name, 0.6)
        line(4.5, 8, 4.5, 14); line(13.5, 8, 13.5, 14)
    else
        ring(9, 9, 5.5, nil, 1.3, 12); ring(9, 9, 1.2, accent_name, 1, 8)
    end
end

function Core.SidebarItem(item, selected, x, y, width, height, hovered, active, icon_only)
    local pressed_offset = active and 1 or 0

    if selected then
        Core.RectFilled(x, y, x + width, y + height, "SidebarActive", 6)
        Core.RectFilled(x, y + 7, x + 3, y + height - 7, "Accent", 2)
    elseif hovered then
        Core.RectFilled(x, y + pressed_offset, x + width, y + height + pressed_offset,
            "SidebarHover", 6)
    end

    local text_color = selected and "NavActiveText"
        or hovered and "NavHoverText"
        or "NavText"
    local icon_accent = selected and "NavIconActive"
        or hovered and "NavIconHover"
        or "NavIconAccent"
    local icon_size = height < 30 and 14 or (icon_only and 20 or 18)
    local row_center = y + height * 0.5 + pressed_offset
    local icon_x = icon_only and (x + math.floor((width - icon_size) * 0.5)) or (x + 15)
    local icon_y = math.floor(row_center - icon_size * 0.5)

    Core.NavigationIcon(item.Id, icon_x, icon_y, icon_size, text_color, icon_accent)
    if not icon_only then
        Core.Text(x + 50, math.floor(row_center - ImGui.GetTextLineHeight() * 0.5),
            item.Label, text_color)
    elseif hovered then
        Core.Tooltip(item.Label)
    end
end

function Core.Panel(x, y, width, height, title)
    local metrics = get_theme().Metrics
    Core.RectFilled(x, y, x + width, y + height, "Panel", metrics.PanelRounding)
    Core.Rect(x, y, x + width, y + height, "PanelBorder", metrics.PanelRounding, 1)
    Core.RectFilled(x + 16, y + 16, x + 19, y + 37, "Accent", 1)
    Core.Text(x + 28, y + 17, title, "PanelTitle")
end

function Core.Shutdown(app)
    if app.Widgets.Core == Core then
        app.Widgets.Core = nil
    end
    App = nil
end

return Core
