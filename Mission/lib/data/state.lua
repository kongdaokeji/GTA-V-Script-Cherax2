-- Mission Assistant 基础状态

local State = {
    Name = "Data.State"
}

function State.Init(App)
    App.Data.State = {
        Ui = {
            Visible = true,
            SelectedPage = "perico",
            PreviousPage = nil,
            ToggleKey = 0x22, -- PgDn (PageDown)
            ToggleKeyWasDown = false,
            RebindingKey = false,
            RebindBaseline = nil,
            PositionInitialized = false,
            LayoutMode = "double",
            BlockGameMouse = true,
            DrawSoftwareCursor = true,
            -- 窗口关闭前记住鼠标位置，重新打开时恢复（默认启用）
            MousePosRestore = true,
            MousePosX = nil,
            MousePosY = nil,

                Window = {
                X = 120,
                Y = 80,
                Width = 1160,
                Height = 760,
                MinimumWidth = 620,
                MinimumHeight = 500,
                Resizing = false
            }
        }
    }

    App.Data.Navigation = {
        { Id = "perico",    Label = "佩里科岛", Marker = "P" },
        { Id = "casino",    Label = "赌场豪劫", Marker = "C" },
        { Id = "doomsday",  Label = "末日豪劫", Marker = "D" },
        { Id = "apartment", Label = "公寓抢劫", Marker = "A" },
        { Id = "kortz",     Label = "科兹中心", Marker = "K" },
        { Id = "other",     Label = "其他任务", Marker = "O" },
        { Id = "vehicles",  Label = "任务载具", Marker = "V" },
        { Id = "quick",     Label = "快捷功能", Marker = "Q" },
        { Id = "solo",      Label = "单人任务", Marker = "S" },
        { Id = "asset",     Label = "资产管理", Marker = "M" }
    }

    App.Data.GetNavigationItem = function(page_id)
        for _, item in ipairs(App.Data.Navigation) do
            if item.Id == page_id then
                return item
            end
        end

        return App.Data.Navigation[1]
    end

    return true
end

function State.Shutdown(App)
    App.Data.GetNavigationItem = nil
    App.Data.Navigation = nil
    App.Data.State = nil
end

return State
