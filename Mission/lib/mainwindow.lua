-- Mission Assistant 自绘主窗口

local MainWindow = {
    Name = "Gui.MainWindow",
    OfficialGroupVisible = false,
    OfficialGroupTexture = nil
}

local App

local OFFICIAL_GROUP = {
    Number = "524239892",
    Link = "https://qm.qq.com/q/xXcQuIr4pW",
    QrFile = "official_qq_group.png",
    QrWidth = 850,
    QrHeight = 820
}

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function join_path(base, relative)
    return tostring(base or ""):gsub("\\", "/"):gsub("/$", "")
        .. "/"
        .. tostring(relative or ""):gsub("\\", "/"):gsub("^/", "")
end

local function windows_path(path)
    return tostring(path or ""):gsub("/", "\\")
end

local function submit_official_group_texture()
    local path = join_path(
        App.Loader.LuaRoot,
        App.Paths.Assets .. "/" .. OFFICIAL_GROUP.QrFile
    )

    if not FileMgr.DoesFileExist(path) then
        return false, "官方群二维码不存在：" .. path
    end

    local ok, texture_id = pcall(Texture.LoadTextureAsync, windows_path(path))
    if not ok or type(texture_id) ~= "number" then
        return false, "提交官方群二维码失败：" .. tostring(texture_id)
    end

    MainWindow.OfficialGroupTexture = {
        Id = texture_id,
        Object = nil,
        Path = windows_path(path),
        StartedAt = Time.GetEpocheMs(),
        Logged = false
    }
    return true
end

local function resolve_official_group_texture()
    local item = MainWindow.OfficialGroupTexture
    if not item then
        return nil
    end
    if item.Object then
        return item.Object
    end
    local ok, valid = pcall(Texture.IsTextureValid, item.Id)
    if ok and valid then
        local got, object = pcall(Texture.GetTexture, item.Id)
        if got and object then
            item.Object = object
            return object
        end
    end
    if Time.GetEpocheMs() - item.StartedAt >= 5000 and not item.Logged then
        item.Logged = true
        Logger.LogError("[Mission Official Group] 二维码纹理未就绪：" .. item.Path)
    end
    return nil
end

local function copy_official_group_text(value, success_message)
    local ok, error_message = pcall(ImGui.SetClipboardText, value)
    if not ok then
        Logger.LogError(
            "[Mission Official Group] 写入剪贴板失败：" .. tostring(error_message)
        )
        App.Actions.Common.Toast("复制失败，请手动复制", 4000)
        return false
    end

    App.Actions.Common.Toast(success_message)
    return true
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
    if App.Theme.Manager and App.Theme.Manager.IsIconNavigation() then
        return 82
    end
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
    if App.Theme.Manager then
        App.Theme.Manager.DrawBackground(x, y, width, height, inner_radius)
    end

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
    local settings_height = short and 32 or 46
    local settings_y = y + height - 32 - settings_height - (short and 4 or 8)
    local count = 0
    for _, item in ipairs(App.Data.Navigation) do
        if not item.IsSettings then count = count + 1 end
    end
    count = math.max(1, count)
    local available = math.max(1, settings_y - top - (short and 8 or 14))
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
        ItemWidth = sidebar_width - 28,
        SettingsY = settings_y,
        SettingsHeight = settings_height
    }
end

local function process_sidebar_input(x, y, sidebar_width, height)
    local core = App.Widgets.Core
    local ui = App.Data.State.Ui
    local layout = sidebar_geometry(y, height, sidebar_width)
    layout.ItemX = x + 14
    local states = {}

    local task_index = 0
    for index, item in ipairs(App.Data.Navigation) do
        local item_y, item_height
        if item.IsSettings then
            item_y = layout.SettingsY
            item_height = layout.SettingsHeight
        else
            item_y = layout.Top + task_index * (layout.RowHeight + layout.Gap)
            item_height = layout.RowHeight
            task_index = task_index + 1
        end
        local pressed, hovered, active = core.SidebarHitbox(
            item,
            layout.ItemX,
            item_y,
            layout.ItemWidth,
            item_height
        )

        if pressed then ui.SelectedPage = item.Id end
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
    local icon_only = App.Theme.Manager and App.Theme.Manager.IsIconNavigation()
    local icon_size = icon_only and 28 or (sidebar_width < 220 and 24 or 28)
    local icon_x = icon_only
        and (x + math.floor((sidebar_width - icon_size) * 0.5))
        or (x + (sidebar_width < 220 and 20 or 24))
    local icon_y = y + (sidebar_width < 220 and 16 or 14)

    draw_title_icon(icon_x, icon_y, icon_size)

    if not icon_only then
        local title_x = icon_x + icon_size + (sidebar_width < 220 and 7 or 8)
        local title_y = y + (sidebar_width < 220 and 19 or 18)
        core.Text(title_x, title_y, "任务助手", "Text")
        local title_width = ImGui.CalcTextSize("任务助手")
        core.Text(title_x + title_width + 9, title_y + 3, "v" .. tostring(App.Version), "TextMuted")
    end
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

    -- 顶栏主题模式快捷切换。
    if App.Theme.Manager then
        local theme_size = 40
        local theme_x = x + width - 104
        local theme_y = y + 14
        local theme_pressed, theme_hovered, theme_active = core.Hitbox(
            "##MissionThemeModeToggle", theme_x, theme_y, theme_size, theme_size
        )
        if theme_hovered then
            core.RectFilled(theme_x, theme_y, theme_x + theme_size, theme_y + theme_size,
                theme_active and "ClosePressed" or "CloseHover", 6)
        end
        local cx, cy = theme_x + 20, theme_y + 20
        if App.Theme.Manager.IsGlass() then
            core.Circle(cx, cy, 7, theme_hovered and "Text" or "TextMuted", 16, 1.7)
            core.CircleFilled(cx + 3, cy - 2, 6, "Header", 16)
        else
            core.Circle(cx, cy, 5, theme_hovered and "Text" or "TextMuted", 16, 1.5)
            for ray = 0, 7 do
                local angle = ray * math.pi / 4
                core.Line(cx + math.cos(angle) * 8, cy + math.sin(angle) * 8,
                    cx + math.cos(angle) * 11, cy + math.sin(angle) * 11,
                    theme_hovered and "Text" or "TextMuted", 1.3)
            end
        end
        if theme_pressed then
            App.Theme.Manager.Set("UiMode",
                App.Theme.Manager.IsGlass() and "classic" or "glass", true)
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
        MainWindow.OfficialGroupVisible = false
    end
end

local function draw_sidebar(x, y, sidebar_width, height, layout, states)
    local core = App.Widgets.Core
    local ui = App.Data.State.Ui

    local icon_only = App.Theme.Manager and App.Theme.Manager.IsIconNavigation()
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
            icon_only
        )
    end

    if not icon_only then
        local hotkey = App.Theme.Manager and App.Theme.Manager.ToggleKeyName() or "PgDn"
        core.Text(x + 24, y + height - 28, hotkey .. " 显示 / 隐藏", "TextSecondary")
    end
end

local function draw_official_group_entry(x, y, width, height)
    local button_width = math.min(220, width)
    local button_x = x + math.max(0, (width - button_width) * 0.5)
    local pressed = App.Widgets.Button.Draw(
        "OfficialGroupEntry",
        "官方Q群",
        button_x,
        y,
        button_width,
        height,
        {Tooltip = "查看官方群二维码、群号和加群链接"}
    )

    if pressed then
        MainWindow.OfficialGroupVisible = true
    end
end

local function draw_official_group_window()
    if not MainWindow.OfficialGroupVisible then
        return
    end

    local display_width, display_height = ImGui.GetDisplaySize()
    display_width = tonumber(display_width) or 1280
    display_height = tonumber(display_height) or 720

    local popup_width = math.min(720, math.max(620, display_width - 32))
    local popup_height = math.min(700, math.max(540, display_height - 32))
    local popup_x = math.max(8, (display_width - popup_width) * 0.5)
    local popup_y = math.max(8, (display_height - popup_height) * 0.5)

    local metrics = App.Theme.Current.Metrics
    local core = App.Widgets.Core
    local glow = metrics.WindowGlowPadding
    local flags =
        ImGuiWindowFlags.NoDecoration |
        ImGuiWindowFlags.NoBackground |
        ImGuiWindowFlags.NoSavedSettings |
        ImGuiWindowFlags.NoScrollbar |
        ImGuiWindowFlags.NoMove

    ImGui.SetNextWindowPos(popup_x - glow, popup_y - glow, ImGuiCond.Always)
    ImGui.SetNextWindowSize(
        popup_width + glow * 2,
        popup_height + glow * 2,
        ImGuiCond.Always
    )
    -- 群信息窗口必须保持在主窗口前面，避免被主窗口覆盖。
    ImGui.SetNextWindowFocus()
    ImGui.Begin("##MissionOfficialGroupWindow", true, flags)
    if App.Theme.Manager then
        ImGui.SetWindowFontScale(App.Theme.Manager.TextMultiplier())
    end

    local host_x, host_y = ImGui.GetWindowPos()
    local x, y = host_x + glow, host_y + glow
    local width, height = popup_width, popup_height
    local radius = metrics.WindowRounding
    local outer = metrics.WindowOuterBorder

    draw_outer_glow(x, y, width, height)
    core.RectFilled(
        x - outer,
        y - outer,
        x + width + outer,
        y + height + outer,
        "WindowBorder",
        metrics.WindowOuterRounding
    )
    core.RectFilled(x, y, x + width, y + height, "Window", radius)
    if App.Theme.Manager then
        App.Theme.Manager.DrawBackground(x, y, width, height, radius)
    end
    core.RectFilled(x, y, x + width, y + 58, "Header", radius)
    core.RectFilled(x, y + 46, x + width, y + 58, "Header", 0)
    core.Line(x + 24, y + 58, x + width - 24, y + 58, "Divider", 1)
    core.Text(x + 24, y + 20, "官方Q群", "Text")

    local close_size = 38
    local close_x = x + width - close_size - 12
    local close_y = y + 10
    local close_pressed, close_hovered, close_active = core.Hitbox(
        "##MissionOfficialGroupClose",
        close_x,
        close_y,
        close_size,
        close_size
    )
    if close_hovered then
        core.RectFilled(
            close_x,
            close_y,
            close_x + close_size,
            close_y + close_size,
            close_active and "ClosePressed" or "CloseHover",
            6
        )
    end
    local close_inset = 12
    core.Line(
        close_x + close_inset,
        close_y + close_inset,
        close_x + close_size - close_inset,
        close_y + close_size - close_inset,
        close_hovered and "Text" or "TextMuted",
        2
    )
    core.Line(
        close_x + close_size - close_inset,
        close_y + close_inset,
        close_x + close_inset,
        close_y + close_size - close_inset,
        close_hovered and "Text" or "TextMuted",
        2
    )
    if close_pressed then
        MainWindow.OfficialGroupVisible = false
    end

    local text_x = x + 24
    local text_width = width - 48
    core.CenteredText(
        text_x,
        y + 72,
        text_width,
        24,
        "官方Q群：" .. OFFICIAL_GROUP.Number .. "（新群）",
        "Text"
    )
    core.CenteredText(
        text_x,
        y + 102,
        text_width,
        24,
        "请仔细核对加群二维码群号，祝大家使用愉快！",
        "TextMuted"
    )
    core.CenteredText(
        text_x,
        y + 132,
        text_width,
        24,
        "此脚本完全免费如果你是付费购买的那就说明你被骗了！",
        "TextAccent"
    )

    local buttons_height = 42
    local buttons_y = y + height - buttons_height - 20
    local qr_top = y + 174
    local qr_available_height = math.max(180, buttons_y - qr_top - 22)
    local qr_aspect = OFFICIAL_GROUP.QrWidth / OFFICIAL_GROUP.QrHeight
    local qr_width = math.min(width - 96, qr_available_height * qr_aspect, 440)
    local qr_height = qr_width / qr_aspect
    local qr_x = x + (width - qr_width) * 0.5
    local qr_y = qr_top + math.max(0, (qr_available_height - qr_height) * 0.5)
    local qr_padding = 8

    core.RectFilled(
        qr_x - qr_padding,
        qr_y - qr_padding,
        qr_x + qr_width + qr_padding,
        qr_y + qr_height + qr_padding,
        "Panel",
        metrics.PanelRounding
    )
    core.Rect(
        qr_x - qr_padding,
        qr_y - qr_padding,
        qr_x + qr_width + qr_padding,
        qr_y + qr_height + qr_padding,
        "PanelBorder",
        metrics.PanelRounding,
        1
    )

    local texture_object = resolve_official_group_texture()
    local texture = nil
    if texture_object then
        local ok, current = pcall(function()
            return texture_object:GetCurrent()
        end)
        if ok then
            texture = current
        end
    end

    if texture then
        ImGui.AddImage(
            texture,
            qr_x,
            qr_y,
            qr_x + qr_width,
            qr_y + qr_height,
            0,
            0,
            1,
            1,
            0xFFFFFFFF
        )
    else
        local texture_item = MainWindow.OfficialGroupTexture
        core.CenteredText(
            qr_x,
            qr_y,
            qr_width,
            qr_height,
            texture_item and texture_item.Logged and "二维码加载失败" or "二维码加载中...",
            "TextMuted"
        )
    end

    local button_gap = 14
    local buttons_x = x + 32
    local buttons_width = width - 64
    local button_width = (buttons_width - button_gap) * 0.5
    local copy_link = App.Widgets.Button.Draw(
        "OfficialGroupCopyLink",
        "复制链接",
        buttons_x,
        buttons_y,
        button_width,
        buttons_height
    )
    local copy_number = App.Widgets.Button.Draw(
        "OfficialGroupCopyNumber",
        "复制群号",
        buttons_x + button_width + button_gap,
        buttons_y,
        button_width,
        buttons_height
    )

    if copy_link then
        copy_official_group_text(OFFICIAL_GROUP.Link, "官方群链接已复制")
    end
    if copy_number then
        copy_official_group_text(OFFICIAL_GROUP.Number, "官方群号已复制")
    end

    ImGui.End()
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
    MainWindow.OfficialGroupVisible = false
    local texture_ok, texture_error = submit_official_group_texture()
    if not texture_ok then
        App = nil
        return false, texture_error
    end
    App.Gui.MainWindow = MainWindow
    return true
end

function MainWindow.Toggle()
    local ui = App.Data.State.Ui
    ui.Visible = not ui.Visible
    if not ui.Visible then
        MainWindow.OfficialGroupVisible = false
    end
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
    if App.Theme.Manager then
        ImGui.SetWindowFontScale(App.Theme.Manager.TextMultiplier())
    end

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
    draw_sidebar(x, y, sidebar_width, height, nav_layout, nav_states)

    local content_x = x + sidebar_width + metrics.ContentPadding
    local content_y = y + metrics.HeaderHeight + 24
    local content_width = width - sidebar_width - metrics.ContentPadding * 2
    local official_button_height = 36
    local official_button_y = y + height - official_button_height - 12
    local content_height = math.max(
        1,
        official_button_y - content_y - 12
    )

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

    draw_official_group_entry(
        content_x,
        official_button_y,
        content_width,
        official_button_height
    )

    handle_window_resize(x, y, width, height)
    ImGui.End()

    draw_official_group_window()
end

function MainWindow.Shutdown(app)
    if app.Gui.MainWindow == MainWindow then
        app.Gui.MainWindow = nil
    end
    MainWindow.OfficialGroupVisible = false
    MainWindow.OfficialGroupTexture = nil
    App = nil
end

return MainWindow
