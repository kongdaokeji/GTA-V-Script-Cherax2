-- Mission Assistant 自绘下拉选择
-- 字段与选项均使用鼠标按下沿执行。

local Select = {
    Name = "Widgets.Select"
}

local App

local function clamp_index(index, count)
    index = math.floor(tonumber(index) or 0)
    return math.max(0, math.min(index, math.max(0, count - 1)))
end

local function draw_field(core, metrics, text, x, y, width, height, state)
    local fill = not state.Enabled and "ControlDisabled"
        or state.Open and "ControlActive"
        or state.Active and "ControlPressed"
        or state.Hovered and "ControlHover"
        or "Control"
    local border = not state.Enabled and "ControlDisabledBorder"
        or state.Open and "ControlBorderActive"
        or (state.Hovered or state.Active) and "ControlBorderHover"
        or "ControlBorder"
    local text_color = state.Enabled and "ControlText" or "TextDisabled"

    if state.Open then
        core.Rect(
            x - 1,
            y - 1,
            x + width + 1,
            y + height + 1,
            "ControlActiveGlow",
            metrics.ControlRounding + 1,
            2
        )
    end

    core.RectFilled(x, y, x + width, y + height, fill, metrics.ControlRounding)
    core.Rect(x, y, x + width, y + height, border, metrics.ControlRounding, 1)
    core.Text(
        x + 12,
        y + (height - ImGui.GetTextLineHeight()) * 0.5,
        text,
        text_color
    )

    local arrow_x = x + width - 18
    local arrow_y = y + height * 0.5
    if state.Open then
        core.TriangleFilled(
            arrow_x - 5, arrow_y + 3,
            arrow_x + 5, arrow_y + 3,
            arrow_x, arrow_y - 4,
            "ControlIcon"
        )
    else
        core.TriangleFilled(
            arrow_x - 5, arrow_y - 3,
            arrow_x + 5, arrow_y - 3,
            arrow_x, arrow_y + 4,
            state.Enabled and "ControlIcon" or "TextDisabled"
        )
    end
end

function Select.Init(app)
    App = app
    App.Widgets.Select = Select
    return true
end

function Select.Draw(id, label, index, items, x, y, width, options)
    options = options or {}
    items = items or {}

    local core = App.Widgets.Core
    local metrics = App.Theme.Current.Metrics
    local enabled = options.Enabled ~= false and #items > 0
    local row_height = options.Height or 42
    local box_width = math.min(
        width,
        230,
        math.max(116, math.floor(width * 0.58))
    )
    local box_x = x + width - box_width
    local box_y = y + 3
    local box_height = row_height - 6

    index = clamp_index(index, #items)
    local selected_text = items[index + 1] or "无可用选项"
    local field_id = core.Id("SelectField", id)
    local popup_id = core.Id("SelectPopup", id)
    local pressed, hovered, active = core.Hitbox(
        field_id,
        box_x,
        box_y,
        box_width,
        box_height
    )
    local was_open = ImGui.IsPopupOpen(popup_id, ImGuiPopupFlags.None)
    local requested_open = pressed and enabled and not was_open

    if requested_open then
        ImGui.OpenPopup(popup_id, ImGuiPopupFlags.None)
    end

    local popup_active = requested_open
        or was_open
        or ImGui.IsPopupOpen(popup_id, ImGuiPopupFlags.None)

    core.Text(
        x,
        y + (row_height - ImGui.GetTextLineHeight()) * 0.5,
        label,
        enabled and "ControlLabel" or "TextDisabled"
    )
    draw_field(
        core,
        metrics,
        selected_text,
        box_x,
        box_y,
        box_width,
        box_height,
        {
            Enabled = enabled,
            Hovered = hovered,
            Active = active,
            Open = popup_active
        }
    )

    if hovered and options.Tooltip then
        core.Tooltip(options.Tooltip)
    end

    if not enabled or not popup_active then
        return index, false
    end

    local visible_rows = math.max(
        1,
        math.min(
            #items,
            options.MaxVisibleItems or 8
        )
    )
    local item_gap = metrics.SelectItemGap
    local popup_height = visible_rows * metrics.SelectItemHeight
        + math.max(0, visible_rows - 1) * item_gap
        + 8

    ImGui.SetNextWindowPos(
        box_x,
        box_y + box_height + metrics.SelectPopupGap,
        ImGuiCond.Always
    )
    ImGui.SetNextWindowSize(box_width, popup_height, ImGuiCond.Always)

    core.PushStyleColor(ImGuiCol.PopupBg, "Popup")
    core.PushStyleColor(ImGuiCol.Border, "PopupBorder")
    core.PushStyleColor(ImGuiCol.ScrollbarBg, "Popup")
    core.PushStyleColor(ImGuiCol.ScrollbarGrab, "PopupScrollbar")
    core.PushStyleColor(ImGuiCol.ScrollbarGrabHovered, "PopupScrollbarHover")
    core.PushStyleColor(ImGuiCol.ScrollbarGrabActive, "PopupScrollbarActive")
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 4, 4)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupRounding, metrics.ControlRounding)
    ImGui.PushStyleVar(ImGuiStyleVar.PopupBorderSize, 1)
    ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, metrics.ScrollbarSize)

    local changed = false
    if ImGui.BeginPopup(
        popup_id,
        ImGuiWindowFlags.NoTitleBar |
        ImGuiWindowFlags.NoMove |
        ImGuiWindowFlags.NoResize |
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoCollapse
    ) then
        local start_x, start_y = ImGui.GetCursorScreenPos()
        local row_width = select(1, ImGui.GetContentRegionAvail())
        if #items > visible_rows then
            row_width = math.max(1, row_width - metrics.ScrollbarSize - 4)
        end

        for item_index, item in ipairs(items) do
            local item_selected = (item_index - 1) == index
            local row_y = start_y + (item_index - 1)
                * (metrics.SelectItemHeight + item_gap)
            local item_pressed, item_hovered, item_active = core.Hitbox(
                core.Id("SelectItem", id, item_index),
                start_x,
                row_y,
                row_width,
                metrics.SelectItemHeight
            )

            local fill = nil
            if item_selected then
                fill = "DropdownSelected"
            elseif item_active then
                fill = "PopupPressed"
            elseif item_hovered then
                fill = "DropdownHover"
            end

            if fill then
                core.RectFilled(
                    start_x,
                    row_y,
                    start_x + row_width,
                    row_y + metrics.SelectItemHeight,
                    fill,
                    math.max(0, metrics.ControlRounding - 1)
                )
            end

            if item_selected then
                core.RectFilled(
                    start_x + 2,
                    row_y + 7,
                    start_x + 4,
                    row_y + metrics.SelectItemHeight - 7,
                    "PopupAccent",
                    1
                )
            end

            local item_text = tostring(item)
            local _, text_height = ImGui.CalcTextSize(item_text)
            core.Text(
                start_x + 12,
                row_y + (metrics.SelectItemHeight - text_height) * 0.5,
                item_text,
                item_selected and "DropdownSelectedText" or "DropdownText"
            )

            if item_pressed then
                index = item_index - 1
                changed = true
                ImGui.CloseCurrentPopup()
                break
            end

            if item_selected then
                ImGui.SetItemDefaultFocus()
            end
        end

        -- 确保 Popup 的滚动范围包含行间距和最后一项。
        ImGui.SetCursorScreenPos(
            start_x,
            start_y + #items * (metrics.SelectItemHeight + item_gap)
        )
        ImGui.Dummy(math.max(1, row_width), 1)
        ImGui.EndPopup()
    end

    ImGui.PopStyleVar(4)
    ImGui.PopStyleColor(6)

    return index, changed
end

function Select.Shutdown(app)
    if app.Widgets.Select == Select then
        app.Widgets.Select = nil
    end
    App = nil
end

return Select
