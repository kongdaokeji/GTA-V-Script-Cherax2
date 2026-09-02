-- Mission Assistant 布局辅助

local Layout = {
    Name = "Widgets.Layout"
}

local App

function Layout.Init(app)
    App = app
    App.Widgets.Layout = Layout
    return true
end

function Layout.ResolveResponsiveMode(width, previous_mode)
    local metrics = App.Theme.Current.Metrics
    local breakpoint = metrics.ResponsiveTwoColumnWidth
    local hysteresis = metrics.ResponsiveHysteresis

    if previous_mode == "double" then
        if width < breakpoint - hysteresis then
            return "single"
        end
        return "double"
    end

    if previous_mode == "single" then
        if width > breakpoint + hysteresis then
            return "double"
        end
        return "single"
    end

    return width >= breakpoint and "double" or "single"
end

function Layout.TwoColumns(x, width, gap, left_ratio)
    gap = gap or App.Theme.Current.Metrics.PanelGap
    left_ratio = left_ratio or 0.58

    local available = math.max(0, width - gap)
    local left_width = math.floor(available * left_ratio)
    local right_width = available - left_width
    local right_x = x + left_width + gap

    return x, left_width, right_x, right_width
end

function Layout.PanelBody(x, y, width, height)
    local padding = App.Theme.Current.Metrics.PanelPadding
    return
        x + padding,
        y + 50,
        math.max(0, width - padding * 2),
        math.max(0, height - 50 - padding)
end

function Layout.FormRow(x, y, width, label_width)
    label_width = label_width or math.floor(width * 0.4)
    label_width = math.max(80, math.min(label_width, width - 80))

    return x, x + label_width, width - label_width
end

function Layout.Stack(x, y, width, gap)
    local stack = {
        X = x,
        Y = y,
        Width = width,
        Gap = gap or App.Theme.Current.Metrics.WidgetGap,
        Offset = 0
    }

    function stack:Next(height)
        local item_y = self.Y + self.Offset
        self.Offset = self.Offset + height + self.Gap
        return self.X, item_y, self.Width, height
    end

    function stack:Space(amount)
        self.Offset = self.Offset + (amount or self.Gap)
    end

    function stack:GetHeight()
        return math.max(0, self.Offset - self.Gap)
    end

    return stack
end

function Layout.Shutdown(app)
    if app.Widgets.Layout == Layout then
        app.Widgets.Layout = nil
    end
    App = nil
end

return Layout
