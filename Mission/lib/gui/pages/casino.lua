-- Mission Assistant 赌场豪劫页面

local CasinoPage = {
    Name = "Gui.Pages.Casino"
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
    local state, lists = data.State, data.Lists
    local fields = {
        {Id="Approach", Label="入侵方式", State="ApproachIndex", List="Approaches"},
        {Id="Target", Label="抢劫目标", State="TargetIndex", List="Targets"},
        {Id="Gunman", Label="枪手等级", State="GunmanIndex", List="Gunmen"},
        {Id="WeaponVariant", Label="武器等级", State="WeaponVariantIndex", List="WeaponVariants"},
        {Id="Driver", Label="车手等级", State="DriverIndex", List="Drivers"},
        {Id="VehicleVariant", Label="载具等级", State="VehicleVariantIndex", List="VehicleVariants"},
        {Id="Hacker", Label="黑客等级", State="HackerIndex", List="Hackers"},
        {Id="Mask", Label="面具主题", State="MaskIndex", List="Masks", Visible=8},
        {Id="KeyLevel", Label="门禁等级", State="KeyLevelIndex", List="KeyLevels"},
        {Id="Guard", Label="安保等级", State="GuardStrengthIndex", List="GuardStrengths"}
    }
    local action_list = {
        {Id="CasinoStart", Label="开启终章", Run=actions.ApplySetup},
        {Id="CasinoReady", Label="强制准备", Run=actions.ForceReady},
        {Id="CasinoRefresh", Label="刷新计划板", Run=actions.RefreshBoard},
        {Id="CasinoPoi", Label="侦查兴趣点", Run=actions.ScopePoints},
        {Id="CasinoAccess", Label="侦查出入口", Run=actions.ScopeAccess},
        {Id="CasinoReset", Label="重置赌场", Run=actions.Reset}
    }
    local height = PANEL_HEADER + stack_height(#fields, CONTROL_HEIGHT)
        + GROUP_GAP + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "赌场前置")

    local inner_x, inner_width = x + 18, width - 36
    local cursor = y + PANEL_HEADER
    for index, field in ipairs(fields) do
        state[field.State] = select(1, App.Widgets.Select.Draw(
            "Casino" .. field.Id,
            field.Label,
            state[field.State],
            lists[field.List],
            inner_x,
            cursor,
            inner_width,
            {MaxVisibleItems=field.Visible or 6}
        ))
        cursor = cursor + CONTROL_HEIGHT
        if index < #fields then cursor = cursor + STACK_GAP end
    end
    cursor = cursor + GROUP_GAP
    draw_buttons(action_list, inner_x, cursor, inner_width)
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
            "CasinoPayout" .. index,
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
        {Id="CasinoApplyPayout", Label="应用所有分红", Run=actions.ApplyPayouts},
        {Id="CasinoAutoPayout", Label="自动设置分红", Run=actions.AutoPayout}
    }, inner_x, cursor, inner_width)
    return height
end

local function draw_teleports(data, actions, x, y, width)
    local height = PANEL_HEADER + CONTROL_HEIGHT + STACK_GAP
        + BUTTON_HEIGHT + PANEL_BOTTOM
    panel(x, y, width, height, "传送点位")

    local inner_x, inner_width = x + 18, width - 36
    data.State.TeleportIndex = select(1, App.Widgets.Select.Draw(
        "CasinoTeleport",
        "地点",
        data.State.TeleportIndex,
        data.Lists.Teleports,
        inner_x,
        y + PANEL_HEADER,
        inner_width,
        {MaxVisibleItems=8}
    ))
    if App.Widgets.Button.Draw(
        "CasinoTeleportGo",
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

local function draw_other(data, actions, x, y, width)
    local action_list = {
        {Id="CasinoHack", Label="破解门禁", Run=actions.HackKeypad},
        {Id="CasinoDual", Label="破解双人门禁", Run=actions.HackDualKeypad},
        {Id="CasinoDrill", Label="跳过金库门钻孔", Run=actions.SkipVaultDrill},
        {Id="CasinoFinish", Label="一键完成", Run=actions.Finish},
        {Id="CasinoTake", Label="一键拿取", Run=actions.TakeTarget},
        {Id="CasinoLives", Label="无限生命数", Run=actions.InfiniteLives},
        {Id="CasinoTimer", Label="无限金库倒计时", Run=actions.InfiniteVaultTimer}
    }
    local height = PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP
        + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "其他功能")

    local inner_x, inner_width = x + 18, width - 36
    local auto_loot, changed = App.Widgets.Toggle.Draw(
        "CasinoAutoLoot",
        "赌场豪劫自动拾取",
        data.State.AutoLootEnabled,
        inner_x,
        y + PANEL_HEADER,
        inner_width,
        {Height=CONTROL_HEIGHT}
    )
    if changed and not actions.SetAutoLootEnabled(auto_loot) then
        data.State.AutoLootEnabled = not auto_loot
    end

    draw_buttons(
        action_list,
        inner_x,
        y + PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP,
        inner_width
    )
    return height
end

local function draw_content(data, actions, x, y, width)
    if width < 620 then
        local cursor = y
        cursor = cursor + draw_preps(data, actions, x, cursor, width) + PANEL_GAP
        cursor = cursor + draw_payouts(data, actions, x, cursor, width) + PANEL_GAP
        cursor = cursor + draw_teleports(data, actions, x, cursor, width) + PANEL_GAP
        cursor = cursor + draw_other(data, actions, x, cursor, width)
        return cursor - y
    end

    local column_width = math.floor((width - PANEL_GAP) * 0.5)
    local right_x = x + column_width + PANEL_GAP
    local left_y, right_y = y, y
    left_y = left_y + draw_preps(data, actions, x, left_y, column_width)
    right_y = right_y + draw_payouts(data, actions, right_x, right_y, column_width) + PANEL_GAP
    right_y = right_y + draw_teleports(data, actions, right_x, right_y, column_width) + PANEL_GAP
    right_y = right_y + draw_other(data, actions, right_x, right_y, column_width)
    return math.max(left_y, right_y) - y
end

function CasinoPage.Init(app)
    App = app
    App.Gui.Pages.Casino = CasinoPage
    return true
end

function CasinoPage.Draw(_, x, y, width, height)
    local context = App.Widgets.Scroll.Begin(
        "CasinoPage",
        x,
        y,
        width,
        height,
        {BackgroundColor="Content", ScrollbarBackgroundColor="Content", Padding=0, Rounding=0}
    )

    local content_height = 0
    if context.ShouldDraw then
        content_height = draw_content(
            App.Data.Casino,
            App.Actions.Casino,
            context.OriginX,
            context.OriginY,
            context.Width
        )
    end
    App.Widgets.Scroll.End(context, content_height)
end

function CasinoPage.Shutdown(app)
    if app.Gui.Pages.Casino == CasinoPage then
        app.Gui.Pages.Casino = nil
    end
    App = nil
end

return CasinoPage
