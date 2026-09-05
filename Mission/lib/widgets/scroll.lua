-- Mission Assistant 滚动内容容器

local Scroll = {
    Name = "Widgets.Scroll"
}

local App

function Scroll.Init(app)
    App = app
    App.Widgets.Scroll = Scroll
    return true
end

function Scroll.Begin(id, x, y, width, height, options)
    options = options or {}

    local core = App.Widgets.Core
    local metrics = App.Theme.Current.Metrics
    local padding = options.Padding
    if padding == nil then
        padding = metrics.ScrollContentPadding
    end

    local rounding = options.Rounding
    if rounding == nil then
        rounding = metrics.PanelRounding
    end

    local scrollbar_size = options.ScrollbarSize or metrics.ScrollbarSize
    local background = options.BackgroundColor or "Panel"
    local scrollbar_background = options.ScrollbarBackgroundColor or background

    core.PushStyleColor(ImGuiCol.ChildBg, background)
    core.PushStyleColor(ImGuiCol.ScrollbarBg, scrollbar_background)
    core.PushStyleColor(ImGuiCol.ScrollbarGrab, options.ScrollbarColor or "Scrollbar")
    core.PushStyleColor(ImGuiCol.ScrollbarGrabHovered, options.ScrollbarHoverColor or "ScrollbarHover")
    core.PushStyleColor(ImGuiCol.ScrollbarGrabActive, options.ScrollbarActiveColor or "Accent")
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, padding, padding)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildRounding, rounding)
    ImGui.PushStyleVar(ImGuiStyleVar.ChildBorderSize, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, scrollbar_size)

    ImGui.SetCursorScreenPos(x, y)
    local should_draw = ImGui.BeginChild(
        core.Id("Scroll", id),
        width,
        height,
        false,
        ImGuiWindowFlags.NoSavedSettings
    )
    local origin_x, origin_y = ImGui.GetCursorScreenPos()

    return {
        ShouldDraw = should_draw,
        OriginX = origin_x,
        OriginY = origin_y,
        Width = math.max(1, width - padding * 2 - scrollbar_size),
        Height = height,
        Padding = padding,
        StyleColorCount = 5,
        StyleVarCount = 4
    }
end

function Scroll.End(context, content_height)
    content_height = math.max(content_height or 0, context.Height)

    ImGui.SetCursorScreenPos(
        context.OriginX,
        context.OriginY + content_height
    )
    ImGui.Dummy(math.max(1, context.Width), 1)
    ImGui.EndChild()
    ImGui.PopStyleVar(context.StyleVarCount)
    ImGui.PopStyleColor(context.StyleColorCount)
end

function Scroll.Shutdown(app)
    if app.Widgets.Scroll == Scroll then
        app.Widgets.Scroll = nil
    end
    App = nil
end

return Scroll
