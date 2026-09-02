-- Mission Assistant 公寓抢劫页面

local ApartmentPage = {Name = "Gui.Pages.Apartment"}
local App

local PANEL_HEADER, CONTROL_HEIGHT, BUTTON_HEIGHT = 46, 42, 38
local STACK_GAP, GROUP_GAP, PANEL_GAP, PANEL_BOTTOM = 10, 14, 14, 18

local function stack_height(count, height)
    return count <= 0 and 0 or count * height + (count - 1) * STACK_GAP
end

local function panel(x, y, width, height, title)
    App.Widgets.Core.Panel(x, y, width, height, title)
end

local function draw_buttons(actions, x, y, width)
    local cursor = y
    for index, action in ipairs(actions) do
        if App.Widgets.Button.Draw(action.Id, action.Label, x, cursor, width, BUTTON_HEIGHT) then
            action.Run()
        end
        cursor = cursor + BUTTON_HEIGHT
        if index < #actions then cursor = cursor + STACK_GAP end
    end
end

local function draw_preps(data, actions, x, y, width)
    local action_list = {
        {Id="AptStart", Label="开启终章", Run=actions.ApplySetup},
        {Id="AptReady", Label="强制准备", Run=actions.ForceReady},
        {Id="AptSkipPreps", Label="跳过前置", Run=actions.SkipPreps}
    }
    local height = PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP
        + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "公寓前置")
    local inner_x, inner_width = x + 18, width - 36
    data.State.HeistIndex = select(1, App.Widgets.Select.Draw(
        "ApartmentHeist", "任务类型", data.State.HeistIndex,
        data.Lists.Heists, inner_x, y + PANEL_HEADER, inner_width
    ))
    draw_buttons(action_list, inner_x,
        y + PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP, inner_width)
    return height
end

local function draw_payouts(data, actions, x, y, width)
    local height = PANEL_HEADER
        + stack_height(4, CONTROL_HEIGHT) + GROUP_GAP
        + stack_height(2, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "分红设置")
    local inner_x, inner_width = x + 18, width - 36
    local cursor = y + PANEL_HEADER
    for index = 1, 4 do
        data.State.Payouts[index] = select(1, App.Widgets.Input.Integer(
            "AptPayout" .. index, "玩家 " .. index, data.State.Payouts[index],
            inner_x, cursor, inner_width,
            {Minimum=-10000, Maximum=10000, Height=CONTROL_HEIGHT}
        ))
        cursor = cursor + CONTROL_HEIGHT
        if index < 4 then cursor = cursor + STACK_GAP end
    end
    cursor = cursor + GROUP_GAP
    draw_buttons({
        {Id="AptApplyPayout", Label="应用所有分红", Run=actions.ApplyPayouts},
        {Id="AptAutoPayout", Label="自动设置分红", Run=actions.AutoPayout}
    }, inner_x, cursor, inner_width)
    return height
end

local function draw_teleports(data, actions, x, y, width)
    local height = PANEL_HEADER + CONTROL_HEIGHT + STACK_GAP + BUTTON_HEIGHT + PANEL_BOTTOM
    panel(x, y, width, height, "传送点位")
    local inner_x, inner_width = x + 18, width - 36
    data.State.TeleportIndex = select(1, App.Widgets.Select.Draw(
        "AptTeleport", "地点", data.State.TeleportIndex,
        data.Lists.Teleports, inner_x, y + PANEL_HEADER, inner_width,
        {MaxVisibleItems=8}
    ))
    if App.Widgets.Button.Draw(
        "AptTeleportGo", "传送", inner_x,
        y + PANEL_HEADER + CONTROL_HEIGHT + STACK_GAP,
        inner_width, BUTTON_HEIGHT
    ) then
        actions.TeleportSelected()
    end
    return height
end

local function draw_other(actions, x, y, width)
    local action_list = {
        {Id="AptSnake", Label="跳过贪吃蛇", Run=actions.SkipSnake},
        {Id="AptDrill", Label="跳过钻孔", Run=actions.SkipDrill},
        {Id="AptHack", Label="跳过太平洋破解", Run=actions.SkipPacificHack},
        {Id="AptUnlock", Label="解锁计划板", Run=actions.UnlockBoard},
        {Id="AptFinish", Label="一键完成", Run=actions.Finish},
        {Id="AptLives", Label="无限生命数", Run=actions.InfiniteLives},
        {Id="AptMastermind", Label="犯罪之神", Run=actions.CriminalMastermind}
    }
    local height = PANEL_HEADER + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "其他功能")
    draw_buttons(action_list, x + 18, y + PANEL_HEADER, width - 36)
    return height
end

local function draw_content(data, actions, x, y, width)
    if width < 620 then
        local cursor = y
        cursor = cursor + draw_preps(data, actions, x, cursor, width) + PANEL_GAP
        cursor = cursor + draw_payouts(data, actions, x, cursor, width) + PANEL_GAP
        cursor = cursor + draw_teleports(data, actions, x, cursor, width) + PANEL_GAP
        cursor = cursor + draw_other(actions, x, cursor, width)
        return cursor - y
    end
    local column_width = math.floor((width - PANEL_GAP) * 0.5)
    local right_x = x + column_width + PANEL_GAP
    local left_y, right_y = y, y
    left_y = left_y + draw_preps(data, actions, x, left_y, column_width) + PANEL_GAP
    left_y = left_y + draw_teleports(data, actions, x, left_y, column_width)
    right_y = right_y + draw_payouts(data, actions, right_x, right_y, column_width) + PANEL_GAP
    right_y = right_y + draw_other(actions, right_x, right_y, column_width)
    return math.max(left_y, right_y) - y
end

function ApartmentPage.Init(app)
    App = app
    App.Gui.Pages.Apartment = ApartmentPage
    return true
end

function ApartmentPage.Draw(_, x, y, width, height)
    local context = App.Widgets.Scroll.Begin(
        "ApartmentPage", x, y, width, height,
        {BackgroundColor="Content", ScrollbarBackgroundColor="Content", Padding=0, Rounding=0}
    )
    local content_height = 0
    if context.ShouldDraw then
        content_height = draw_content(
            App.Data.Apartment, App.Actions.Apartment,
            context.OriginX, context.OriginY, context.Width
        )
    end
    App.Widgets.Scroll.End(context, content_height)
end

function ApartmentPage.Shutdown(app)
    if app.Gui.Pages.Apartment == ApartmentPage then app.Gui.Pages.Apartment = nil end
    App = nil
end

return ApartmentPage
