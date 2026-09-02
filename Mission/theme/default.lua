-- Mission Assistant 默认主题

local DefaultTheme = {
    Name = "Theme.Default"
}

function DefaultTheme.Init(App)
    App.Theme.Current = {
        Colors = {
            GlowOuter       = {92, 50, 220, 24},
            GlowMiddle      = {138, 87, 255, 72},
            WindowBorder    = {135, 88, 255, 210},
            WindowFrame     = {58, 45, 96, 252},
            Window          = {23, 21, 34, 252},
            Content         = {43, 41, 71, 250},
            Header          = {34, 32, 56, 252},
            Sidebar         = {29, 28, 49, 252},
            Divider         = {170, 160, 220, 26},
            Border          = {170, 160, 220, 26},

            NavText         = {169, 164, 189, 235},
            NavHoverText    = {212, 208, 226, 240},
            NavActiveText   = {244, 241, 255, 250},
            NavIconAccent   = {139, 124, 255, 145},
            NavIconHover    = {139, 124, 255, 205},
            NavIconActive   = {139, 124, 255, 245},
            SidebarHover    = {110, 100, 170, 31},
            SidebarActive   = {64, 60, 105, 250},

            Panel           = {41, 39, 66, 248},
            PanelBorder     = {170, 160, 220, 26},
            PanelTitle      = {216, 212, 234, 240},

            Control         = {48, 46, 80, 248},
            ControlHover    = {58, 55, 95, 248},
            ControlPressed  = {69, 64, 109, 250},
            ControlActive   = {69, 65, 110, 250},
            ControlActiveGlow = {129, 120, 240, 36},
            ControlDisabled = {48, 46, 80, 205},
            ControlBorder   = {170, 160, 220, 41},
            ControlBorderHover = {180, 170, 230, 56},
            ControlBorderActive = {129, 120, 240, 255},
            ControlDisabledBorder = {170, 160, 220, 26},
            ControlText     = {228, 224, 238, 245},
            ControlLabel    = {212, 208, 226, 235},
            ControlIcon     = {169, 164, 189, 230},
            ButtonPressed   = {69, 64, 107, 250},
            ToggleHover     = {58, 55, 95, 246},
            ToggleLabelOn   = {242, 240, 248, 245},
            ToggleTrackOn   = {116, 107, 224, 235},
            ToggleTrackOnHover = {129, 118, 234, 245},
            ToggleTrackOff  = {73, 70, 96, 225},
            ToggleTrackDisabled = {73, 70, 96, 145},
            ToggleBorderOn  = {123, 114, 232, 180},
            ToggleBorderOff = {170, 160, 220, 41},
            ToggleKnobOn    = {238, 234, 248, 250},
            ToggleKnobOff   = {157, 152, 172, 240},
            ToggleKnobDisabled = {113, 109, 132, 190},
            Accent          = {139, 124, 255, 245},
            AccentHover     = {156, 139, 255, 255},
            AccentSoft      = {116, 107, 224, 235},
            ToggleOff       = {73, 70, 96, 225},
            ToggleKnob      = {238, 234, 248, 250},
            Popup           = {41, 39, 66, 254},
            PopupBorder     = {170, 160, 220, 41},
            PopupPressed    = {69, 64, 109, 250},
            PopupAccent     = {139, 124, 255, 245},
            PopupScrollbar  = {85, 81, 111, 220},
            PopupScrollbarHover = {105, 100, 133, 235},
            PopupScrollbarActive = {139, 124, 255, 245},
            DropdownHover   = {56, 53, 91, 250},
            DropdownSelected = {72, 67, 113, 250},
            DropdownSelectedText = {245, 243, 255, 250},
            DropdownText    = {201, 197, 216, 240},
            Scrollbar       = {85, 81, 111, 220},
            ScrollbarHover  = {105, 100, 133, 235},
            Tooltip         = {24, 22, 36, 248},
            TooltipBorder   = {170, 160, 220, 56},
            TooltipText     = {245, 243, 255, 250},

            TitleIconFill   = {139, 124, 255, 28},
            CloseHover      = {58, 55, 95, 248},
            ClosePressed    = {69, 64, 109, 250},
            Text            = {245, 243, 255, 250},
            TextAccent      = {139, 124, 255, 245},
            TextMuted       = {195, 190, 216, 230},
            TextSecondary   = {145, 139, 170, 225},
            TextDisabled    = {113, 109, 132, 225},
            Danger          = {230, 92, 112, 255}
        },

        Metrics = {
            HeaderHeight = 70,
            SidebarWidth = 220,
            SidebarMinWidth = 200,
            SidebarMaxWidth = 242,
            SidebarWidthRatio = 0.225,
            SidebarItemHeight = 48,
            SidebarItemGap = 5,
            ContentPadding = 32,
            PanelGap = 16,
            PanelPadding = 18,
            WindowGlowPadding = 18,
            WindowOuterBorder = 4,
            WindowFrameInset = 2,
            WindowOuterRounding = 20,
            WindowRounding = 16,
            PanelRounding = 6,
            ControlRounding = 6,
            ControlHeight = 38,
            WidgetGap = 12,
            ToggleWidth = 46,
            ToggleHeight = 24,
            InputVerticalPadding = 9,
            SelectVisibleItems = 6,
            SelectItemHeight = 34,
            SelectItemGap = 4,
            SelectPopupGap = 8,
            ScrollbarSize = 8,
            ScrollContentPadding = 12,
            ResizeHandleSize = 30,
            ResizeHandleInset = 0,
            ResponsiveTwoColumnWidth = 620,
            ResponsiveHysteresis = 20,
            SingleColumnControlsHeight = 470,
            CursorTextureWidth = 363,
            CursorTextureHeight = 512,
            CursorHotspotX = 21,
            CursorHotspotY = 0,
            CursorHeight = 26,
            AccentLineWidth = 3
        }
    }

    return true
end

function DefaultTheme.Shutdown(App)
    App.Theme.Current = nil
end

return DefaultTheme
