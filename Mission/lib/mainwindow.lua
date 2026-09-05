-- Mission Assistant 自绘主窗口

local MainWindow = {
    Name = "Gui.MainWindow"
}

local App

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function initialize_window_position()
    local ui = App.Data.State.Ui
    if ui.PositionInitialized then
        return
    end

    local display_width, display_height = ImGui.GetDisplaySize()
    local window = ui.Window

    if display_width and display_width > 0 then
        window.Width = clamp(
            window.Width,
            math.min(window.MinimumWidth, display_width - 16),
            math.max(window.MinimumWidth, display_width - 36)
        )
        window.X = math.max(8, (display_width - window.Width) * 0.5)
    end

    if display_height and display_height > 0 then
        window.Height = clamp(
            window.Height,
            math.min(window.MinimumHeight, display_height - 16),
            math.max(window.MinimumHeight, display_height - 36)
        )
        window.Y = math.max(8, (display_height - window.Height) * 0.5)
    end

    ui.PositionInitialized = true
end

local function sidebar_width_for(window_width)
    local metrics = App.Theme.Current.Metrics
    return clamp(
        math.floor(window_width * metrics.SidebarWidthRatio),
        metrics.SidebarMinWidth,
        metrics.SidebarMaxWidth
    )
end

local function draw_outer_glow(x, y, width, height)
    local core = App.Widgets.Core
    local metrics = App.Theme.Current.Metrics
    local radius = metrics.WindowOuterRounding
    local layers = {
        {expand = 12, color = "GlowOuter", thickness = 8},
        {expand = 7, color = "GlowOuter", thickness = 6},
        {expand = 3, color = "GlowMiddle", thickness = 4}
    }

    for _, layer in ipairs(layers) do
        core.Rect(
            x - layer.expand,
            y - layer.expand,
            x + width + layer.expand,
            y + height + layer.expand,
            layer.color,
            radius + layer.expand,
            layer.thickness
        )
    end
end

local function draw_window_shell(x, y, width, height, sidebar_width)
    local core = App.Widgets.Core
    local theme = App.Theme.Current
    local metrics = theme.Metrics
    local outer = metrics.WindowOuterBorder
    local frame = metrics.WindowFrameInset
    local outer_radius = metrics.WindowOuterRounding
    local inner_radius = metrics.WindowRounding

    draw_outer_glow(x, y, width, height)

    core.RectFilled(
        x - outer,
        y - outer,
        x + width + outer,
        y + height + outer,
        "WindowBorder",
        outer_radius
    )
    core.RectFilled(
        x - outer + frame,
        y - outer + frame,
        x + width + outer - frame,
        y + height + outer - frame,
        "WindowFrame",
        math.max(0, outer_radius - frame)
    )
    -- 基础内容背景保留完整外轮廓圆角；拼接边由侧栏和标题栏单独收口。
    core.RectFilled(x, y, x + width, y + height, "Content", inner_radius)

    -- 分区不重叠，避免半透明颜色在拼接处重复混合。
    local sidebar_corner = math.min(inner_radius, sidebar_width, height * 0.5)
    if sidebar_corner > 0 then
        ImGui.PushClipRect(x, y, x + sidebar_corner, y + height, true)
        core.RectFilled(x, y, x + sidebar_width, y + height, "Sidebar", inner_radius)
        ImGui.PopClipRect()
    end
    core.RectFilled(
        x + sidebar_corner,
        y,
        x + sidebar_width,
        y + height,
        "Sidebar",
        0
    )

    -- 标题栏仅右上区域参与圆角，其余区域均为直角且互不重叠。
    local header_left = x + sidebar_width
    local header_right = x + width
    local header_bottom = y + metrics.HeaderHeight
    local header_corner = math.min(
        inner_radius,
        header_right - header_left,
        metrics.HeaderHeight
    )
    core.RectFilled(
        header_left,
        y,
        header_right - header_corner,
        header_bottom,
        "Header",
        0
    )
    core.RectFilled(
        header_right - header_corner,
        y + header_corner,
        header_right,
        header_bottom,
        "Header",
        0
    )
    if header_corner > 0 then
        ImGui.PushClipRect(
            header_right - header_corner,
            y,
            header_right,
            y + header_corner,
            true
        )
        core.RectFilled(
            header_left,
            y,
            header_right,
            header_bottom,
            "Header",
            inner_radius
        )
        ImGui.PopClipRect()
    end

    core.Line(
        x + sidebar_width,
        y + 1,
        x + sidebar_width,
        y + height - 1,
        "Divider",
        1
    )
end

local function handle_title_drag(x, y, width)
    local core = App.Widgets.Core
    local window = App.Data.State.Ui.Window
    local header_height = App.Theme.Current.Metrics.HeaderHeight

    local _, _, active = core.Hitbox(
        "##MissionWindowDrag",
        x + 8,
        y + 4,
        width - 112,
        header_height - 8
    )

    if active and ImGui.IsMouseDragging(ImGuiMouseButton.ImGuiMouseButton_Left, 0) then
        local delta_x, delta_y = ImGui.GetMouseDragDelta(
            ImGuiMouseButton.ImGuiMouseButton_Left,
            0
        )
        window.X = window.X + delta_x
        window.Y = window.Y + delta_y
        ImGui.ResetMouseDragDelta(ImGuiMouseButton.ImGuiMouseButton_Left)
    end
end

local function sidebar_geometry(y, height, sidebar_width)
    local metrics = App.Theme.Current.Metrics
    local short = height < 560
    local top = y + (short and 62 or 84)
    local gap = short and 2 or metrics.SidebarItemGap
    local bottom_padding = short and 12 or 16
    local count = math.max(1, #App.Data.Navigation)
    local available = math.max(1, y + height - bottom_padding - top)
    local row_height = clamp(
        math.floor((available - gap * (count - 1)) / count),
        20,
        metrics.SidebarItemHeight
    )

    return {
        Top = top,
        Gap = gap,
        RowHeight = row_height,
        ItemX = nil,
        ItemWidth = sidebar_width - 28
    }
end

local function process_sidebar_input(x, y, sidebar_width, height)
    local core = App.Widgets.Core
    local ui = App.Data.State.Ui
    local layout = sidebar_geometry(y, height, sidebar_width)
    layout.ItemX = x + 14
    local states = {}

    for index, item in ipairs(App.Data.Navigation) do
        local item_y = layout.Top + (index - 1) * (layout.RowHeight + layout.Gap)
        local item_height = layout.RowHeight
        local pressed, hovered, active = core.SidebarHitbox(
            item,
            layout.ItemX,
            item_y,
            layout.ItemWidth,
            item_height
        )

        if pressed then
            ui.SelectedPage = item.Id
            ui.PreviousPage = nil
        end
        states[index] = {Y=item_y, Height=item_height, Hovered=hovered, Active=active}
    end

    return layout, states
end

local function draw_title_icon(x, y, size)
    local core = App.Widgets.Core
    local unit = size / 28

    core.RectFilled(x, y, x + size, y + size, "TitleIconFill", 6 * unit)
    core.Rect(x, y, x + size, y + size, "Accent", 6 * unit, 1.6 * unit)
    core.Line(x + 7 * unit, y + 14 * unit, x + 11 * unit, y + 18 * unit,
        "Text", 2.4 * unit)
    core.Line(x + 11 * unit, y + 18 * unit, x + 21 * unit, y + 8.5 * unit,
        "Text", 2.4 * unit)
    core.Line(x + 8 * unit, y + 23 * unit, x + 20 * unit, y + 23 * unit,
        "TextMuted", 1.5 * unit)
end

local function draw_header(x, y, width, sidebar_width)
    local core = App.Widgets.Core
    local ui = App.Data.State.Ui
    local metrics = App.Theme.Current.Metrics
    local page = App.Gui.Router.GetCurrentPage()
    local icon_size = sidebar_width < 220 and 24 or 28
    local icon_x = x + (sidebar_width < 220 and 20 or 24)
    local icon_y = y + (sidebar_width < 220 and 16 or 14)

    draw_title_icon(icon_x, icon_y, icon_size)

    local title_x = icon_x + icon_size + (sidebar_width < 220 and 7 or 8)
    local title_y = y + (sidebar_width < 220 and 19 or 18)
    core.Text(title_x, title_y, "任务助手", "Text")
    core.RectFilled(icon_x, y + 54, icon_x + icon_size, y + 56, "Accent", 1)

    core.Text(x + sidebar_width + 32, y + 22, page.Label, "Text")
    core.Line(
        x + sidebar_width + 32,
        y + metrics.HeaderHeight,
        x + width - 32,
        y + metrics.HeaderHeight,
        "Divider",
        1
    )
    core.RectFilled(
        x + sidebar_width + 32,
        y + metrics.HeaderHeight - 1,
        x + sidebar_width + 74,
        y + metrics.HeaderHeight + 1,
        "Accent",
        1
    )

    -- 右上角齿轮：进入设置页（显示/隐藏热键）。
    local settings_size = 40
    local settings_x = x + width - 104
    local settings_y = y + 14
    local settings_pressed, settings_hovered, settings_active = core.Hitbox(
        "##MissionSettingsToggle",
        settings_x,
        settings_y,
        settings_size,
        settings_size
    )
    if settings_hovered then
        core.RectFilled(
            settings_x,
            settings_y,
            settings_x + settings_size,
            settings_y + settings_size,
            settings_active and "ClosePressed" or "CloseHover",
            6
        )
        core.Tooltip("设置")
    end
    local gear_color = settings_hovered and "Text" or "TextMuted"
    local gear_x = settings_x + 20
    local gear_y = settings_y + 20

    -- 传统齿轮：8 个梯形宽齿、连续齿根环和大中心孔。
    local tooth_count = 8
    local root_radius = 6.4
    local outer_radius = 8.8
    local base_half_angle = math.pi * 16 / 180
    local tip_half_angle = math.pi * 10 / 180
    for tooth = 0, tooth_count - 1 do
        local angle = tooth * math.pi * 2 / tooth_count
        local base_left = angle - base_half_angle
        local tip_left = angle - tip_half_angle
        local tip_right = angle + tip_half_angle
        local base_right = angle + base_half_angle
        local base_left_x = gear_x + math.cos(base_left) * root_radius
        local base_left_y = gear_y + math.sin(base_left) * root_radius
        local tip_left_x = gear_x + math.cos(tip_left) * outer_radius
        local tip_left_y = gear_y + math.sin(tip_left) * outer_radius
        local tip_right_x = gear_x + math.cos(tip_right) * outer_radius
        local tip_right_y = gear_y + math.sin(tip_right) * outer_radius
        local base_right_x = gear_x + math.cos(base_right) * root_radius
        local base_right_y = gear_y + math.sin(base_right) * root_radius
        core.Line(base_left_x, base_left_y, tip_left_x, tip_left_y,
            gear_color, 2.2)
        core.Line(tip_left_x, tip_left_y, tip_right_x, tip_right_y,
            gear_color, 2.2)
        core.Line(tip_right_x, tip_right_y, base_right_x, base_right_y,
            gear_color, 2.2)
    end
    core.Circle(gear_x, gear_y, root_radius, gear_color, 32, 2.4)
    core.Circle(gear_x, gear_y, 4.0, gear_color, 24, 2.3)
    if settings_pressed then
        local ui = App.Data.State.Ui
        if ui.SelectedPage == "settings" then
            ui.SelectedPage = ui.PreviousPage or "perico"
            ui.PreviousPage = nil
        else
            ui.PreviousPage = ui.SelectedPage
            ui.SelectedPage = "settings"
        end
    end

    local close_size = 40
    local close_x = x + width - 58
    local close_y = y + 14
    local _, hovered, active = core.Hitbox(
        "##MissionWindowClose",
        close_x,
        close_y,
        close_size,
        close_size
    )
    if hovered then
        core.RectFilled(
            close_x,
            close_y,
            close_x + close_size,
            close_y + close_size,
            active and "ClosePressed" or "CloseHover",
            6
        )
    end

    local inset = 13
    core.Line(
        close_x + inset,
        close_y + inset,
        close_x + close_size - inset,
        close_y + close_size - inset,
        hovered and "Text" or "TextMuted",
        2
    )
    core.Line(
        close_x + close_size - inset,
        close_y + inset,
        close_x + inset,
        close_y + close_size - inset,
        hovered and "Text" or "TextMuted",
        2
    )

    if hovered and ImGui.IsMouseClicked(ImGuiMouseButton.ImGuiMouseButton_Left, false) then
        ui.Visible = false
    end
end

local function draw_sidebar(layout, states)
    local core = App.Widgets.Core
    local ui = App.Data.State.Ui

    for index, item in ipairs(App.Data.Navigation) do
        local state = states[index]
        core.SidebarItem(
            item,
            item.Id == ui.SelectedPage,
            layout.ItemX,
            state.Y,
            layout.ItemWidth,
            state.Height,
            state.Hovered,
            state.Active,
            false
        )
    end
end

local function handle_window_resize(x, y, width, height)
    local core = App.Widgets.Core
    local window = App.Data.State.Ui.Window
    local metrics = App.Theme.Current.Metrics
    local handle_size = metrics.ResizeHandleSize
    local handle_x = x + width - handle_size
    local handle_y = y + height - handle_size

    local _, hovered, active = core.Hitbox(
        "##MissionWindowResize",
        handle_x,
        handle_y,
        handle_size,
        handle_size
    )
    window.Resizing = active

    if active and ImGui.IsMouseDragging(ImGuiMouseButton.ImGuiMouseButton_Left, 0) then
        local delta_x, delta_y = ImGui.GetMouseDragDelta(
            ImGuiMouseButton.ImGuiMouseButton_Left,
            0
        )
        local display_width, display_height = ImGui.GetDisplaySize()
        local maximum_width = math.max(
            window.MinimumWidth,
            (display_width or (window.X + window.Width)) - window.X - 8
        )
        local maximum_height = math.max(
            window.MinimumHeight,
            (display_height or (window.Y + window.Height)) - window.Y - 8
        )

        window.Width = clamp(window.Width + delta_x, window.MinimumWidth, maximum_width)
        window.Height = clamp(window.Height + delta_y, window.MinimumHeight, maximum_height)
        ImGui.ResetMouseDragDelta(ImGuiMouseButton.ImGuiMouseButton_Left)
    end

    local marker_color = hovered and "Accent" or "TextMuted"
    local right = x + width - 10
    local bottom = y + height - 10
    core.Line(right - 12, bottom, right, bottom - 12, marker_color, 1)
    core.Line(right - 6, bottom, right, bottom - 6, marker_color, 1)
end

function MainWindow.Init(app)
    App = app
    App.Gui.MainWindow = MainWindow
    return true
end

function MainWindow.Toggle()
    local ui = App.Data.State.Ui
    ui.Visible = not ui.Visible
end

function MainWindow.Draw()
    local ui = App.Data.State.Ui
    if not ui.Visible then
        return
    end

    initialize_window_position()

    local window = ui.Window
    local metrics = App.Theme.Current.Metrics
    local glow = metrics.WindowGlowPadding
    local flags =
        ImGuiWindowFlags.NoDecoration |
        ImGuiWindowFlags.NoBackground |
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.NoMove

    ImGui.SetNextWindowPos(window.X - glow, window.Y - glow, ImGuiCond.Always)
    ImGui.SetNextWindowSize(
        window.Width + glow * 2,
        window.Height + glow * 2,
        ImGuiCond.Always
    )
    ImGui.Begin("##MissionAssistantCustomWindow", true, flags)
    ImGui.SetWindowFontScale(metrics.FontScale)

    local host_x, host_y = ImGui.GetWindowPos()
    local host_width, host_height = ImGui.GetWindowSize()
    local x, y = host_x + glow, host_y + glow
    local width, height = host_width - glow * 2, host_height - glow * 2
    local sidebar_width = sidebar_width_for(width)

    handle_title_drag(x, y, width)
    local nav_layout, nav_states = process_sidebar_input(
        x,
        y,
        sidebar_width,
        height
    )

    draw_window_shell(x, y, width, height, sidebar_width)
    draw_header(x, y, width, sidebar_width)
    draw_sidebar(nav_layout, nav_states)

    local content_x = x + sidebar_width + metrics.ContentPadding
    local content_y = y + metrics.HeaderHeight + 24
    local content_width = width - sidebar_width - metrics.ContentPadding * 2
    local content_height = math.max(1, y + height - content_y - 12)

    ImGui.PushClipRect(
        content_x,
        content_y,
        content_x + content_width,
        content_y + content_height,
        true
    )
    App.Gui.Router.Draw(
        content_x,
        content_y,
        content_width,
        content_height
    )
    ImGui.PopClipRect()

    handle_window_resize(x, y, width, height)
    ImGui.End()
end

function MainWindow.Shutdown(app)
    if app.Gui.MainWindow == MainWindow then
        app.Gui.MainWindow = nil
    end
    App = nil
end

return MainWindow
