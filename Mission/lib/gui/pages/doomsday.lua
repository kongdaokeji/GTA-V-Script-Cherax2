-- Mission Assistant 末日豪劫页面

local DoomsdayPage = {
    Name = "Gui.Pages.Doomsday"
}

local App

local PANEL_HEADER = 46
local CONTROL_HEIGHT = 42
local BUTTON_HEIGHT = 38
local STACK_GAP = 10
local GROUP_GAP = 14
local PANEL_GAP = 14
local PANEL_BOTTOM = 18

local function stack_height(count, height)
    if count <= 0 then return 0 end
    return count * height + (count - 1) * STACK_GAP
end

local function panel(x, y, width, height, title)
    App.Widgets.Core.Panel(x, y, width, height, title)
end

local function draw_buttons(actions, x, y, width)
    local cursor = y
    for index, action in ipairs(actions) do
        if App.Widgets.Button.Draw(
            action.Id,
            action.Label,
            x,
            cursor,
            width,
            BUTTON_HEIGHT
        ) then
            action.Run()
        end
        cursor = cursor + BUTTON_HEIGHT
        if index < #actions then cursor = cursor + STACK_GAP end
    end
    return cursor
end

local function draw_preps(data, actions, x, y, width)
    local action_list = {
        {Id="DoomStart", Label="开启终章", Run=actions.ApplySetup},
        {Id="DoomReady", Label="强制准备", Run=actions.ForceReady},
        {Id="DoomRefresh", Label="刷新计划板", Run=actions.RefreshBoard},
        {Id="DoomReset", Label="重置末日豪劫", Run=actions.Reset}
    }
    local height = PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP
        + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "末日前置")

    local inner_x, inner_width = x + 18, width - 36
    data.State.SetupIndex = select(1, App.Widgets.Select.Draw(
        "DoomSetup",
        "任务类型",
        data.State.SetupIndex,
        data.Lists.Setups,
        inner_x,
        y + PANEL_HEADER,
        inner_width
    ))
    draw_buttons(
        action_list,
        inner_x,
        y + PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP,
        inner_width
    )
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
            "DoomPayout" .. index,
            "玩家 " .. index,
            data.State.Payouts[index],
            inner_x,
            cursor,
            inner_width,
            {Height=CONTROL_HEIGHT}
        ))
        cursor = cursor + CONTROL_HEIGHT
        if index < 4 then cursor = cursor + STACK_GAP end
    end
    cursor = cursor + GROUP_GAP
    draw_buttons({
        {Id="DoomApplyPayout", Label="应用所有分红", Run=actions.ApplyPayouts},
        {Id="DoomAutoPayout", Label="自动设置分红", Run=actions.AutoPayout}
    }, inner_x, cursor, inner_width)
    return height
end

local function draw_teleports(data, actions, x, y, width)
    local height = PANEL_HEADER + CONTROL_HEIGHT + STACK_GAP
        + BUTTON_HEIGHT + PANEL_BOTTOM
    panel(x, y, width, height, "传送点位")

    local inner_x, inner_width = x + 18, width - 36
    data.State.TeleportIndex = select(1, App.Widgets.Select.Draw(
        "DoomTeleport",
        "地点",
        data.State.TeleportIndex,
        data.Lists.Teleports,
        inner_x,
        y + PANEL_HEADER,
        inner_width
    ))
    if App.Widgets.Button.Draw(
        "DoomTeleportGo",
        "传送",
        inner_x,
        y + PANEL_HEADER + CONTROL_HEIGHT + STACK_GAP,
        inner_width,
        BUTTON_HEIGHT
    ) then
        actions.TeleportSelected()
    end
    return height
end

local function draw_other(actions, x, y, width)
    local action_list = {
        {Id="DoomFinish", Label="一键完成", Run=actions.Finish},
        {Id="DoomFinishAct3", Label="一键完成末日将至", Run=actions.FinishActThree},
        {Id="DoomSkipTerminal", Label="跳过终端解密", Run=actions.SkipTerminal},
        {Id="DoomLives", Label="无限生命数", Run=actions.InfiniteLives}
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

function DoomsdayPage.Init(app)
    App = app
    App.Gui.Pages.Doomsday = DoomsdayPage
    return true
end

function DoomsdayPage.Draw(_, x, y, width, height)
    local context = App.Widgets.Scroll.Begin(
        "DoomsdayPage",
        x,
        y,
        width,
        height,
        {BackgroundColor="Content", ScrollbarBackgroundColor="Content", Padding=0, Rounding=0}
    )

    local content_height = 0
    if context.ShouldDraw then
        content_height = draw_content(
            App.Data.Doomsday,
            App.Actions.Doomsday,
            context.OriginX,
            context.OriginY,
            context.Width
        )
    end
    App.Widgets.Scroll.End(context, content_height)
end

function DoomsdayPage.Shutdown(app)
    if app.Gui.Pages.Doomsday == DoomsdayPage then
        app.Gui.Pages.Doomsday = nil
    end
    App = nil
end

return DoomsdayPage
