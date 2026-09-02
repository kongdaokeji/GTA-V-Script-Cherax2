-- Mission Assistant 佩里科岛页面

local PericoPage = {
    Name = "Gui.Pages.Perico"
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
            BUTTON_HEIGHT,
            action.Options
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
    local action_list = {
        {Id="PericoStart", Label="开启终章", Run=actions.ApplySetup},
        {Id="PericoReady", Label="强制准备", Run=actions.ForceReady},
        {Id="PericoRefresh", Label="刷新计划板", Run=actions.RefreshBoard},
        {Id="PericoEntry", Label="解锁入侵点", Run=actions.UnlockEntry},
        {Id="PericoEscape", Label="解锁逃离点", Run=actions.UnlockEscape},
        {Id="PericoInterest", Label="解锁兴趣点", Run=actions.UnlockInterest},
        {Id="PericoReset", Label="重置佩里科岛", Run=actions.Reset}
    }
    local height = PANEL_HEADER + stack_height(4, CONTROL_HEIGHT)
        + GROUP_GAP + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "佩岛前置")

    local inner_x, inner_width = x + 18, width - 36
    local cursor = y + PANEL_HEADER
    state.DifficultyIndex = select(1, App.Widgets.Select.Draw(
        "PericoDifficulty", "任务难度", state.DifficultyIndex,
        lists.Difficulties, inner_x, cursor, inner_width
    ))
    cursor = cursor + CONTROL_HEIGHT + STACK_GAP
    state.TargetIndex = select(1, App.Widgets.Select.Draw(
        "PericoTarget", "主要目标", state.TargetIndex,
        lists.Targets, inner_x, cursor, inner_width, {MaxVisibleItems=6}
    ))
    cursor = cursor + CONTROL_HEIGHT + STACK_GAP
    state.WeaponIndex = select(1, App.Widgets.Select.Draw(
        "PericoWeapon", "武器套装", state.WeaponIndex,
        lists.Weapons, inner_x, cursor, inner_width
    ))
    cursor = cursor + CONTROL_HEIGHT + STACK_GAP
    state.PaintingIndex = select(1, App.Widgets.Select.Draw(
        "PericoPaintings", "名画数量", state.PaintingIndex,
        lists.Paintings, inner_x, cursor, inner_width
    ))
    cursor = cursor + CONTROL_HEIGHT + GROUP_GAP
    draw_buttons(action_list, inner_x, cursor, inner_width)
    return height
end

local function draw_loot_panel(data, actions, options)
    local state, lists = data.State, data.Lists
    local height = PANEL_HEADER + stack_height(2, CONTROL_HEIGHT)
        + GROUP_GAP + stack_height(2, BUTTON_HEIGHT)
        + GROUP_GAP + CONTROL_HEIGHT + PANEL_BOTTOM
    panel(options.X, options.Y, options.Width, height, options.Title)

    local inner_x = options.X + 18
    local inner_width = options.Width - 36
    local cursor = options.Y + PANEL_HEADER
    local location_index = state[options.LocationIndex]
    local targets = state[options.Targets]

    state[options.LocationIndex] = select(1, App.Widgets.Select.Draw(
        options.Id .. "Location",
        options.LocationLabel,
        location_index,
        lists[options.Locations],
        inner_x,
        cursor,
        inner_width,
        {MaxVisibleItems=8}
    ))
    location_index = state[options.LocationIndex]
    cursor = cursor + CONTROL_HEIGHT + STACK_GAP

    targets[location_index + 1] = select(1, App.Widgets.Select.Draw(
        options.Id .. "Material",
        "物资点配置",
        targets[location_index + 1],
        lists.Materials,
        inner_x,
        cursor,
        inner_width
    ))
    cursor = cursor + CONTROL_HEIGHT + GROUP_GAP

    if App.Widgets.Button.Draw(
        options.Id .. "Clear", "清空配置",
        inner_x, cursor, inner_width, BUTTON_HEIGHT
    ) then
        actions[options.SetAll](1)
    end
    cursor = cursor + BUTTON_HEIGHT + STACK_GAP
    if App.Widgets.Button.Draw(
        options.Id .. "Gold", "满黄金配置",
        inner_x, cursor, inner_width, BUTTON_HEIGHT
    ) then
        actions[options.SetAll](5)
    end
    cursor = cursor + BUTTON_HEIGHT + GROUP_GAP

    local value = state[options.RandomFill]
    state[options.RandomFill] = select(1, App.Widgets.Toggle.Draw(
        options.Id .. "Fill",
        options.FillLabel,
        value,
        inner_x,
        cursor,
        inner_width,
        {Height=CONTROL_HEIGHT}
    ))
    return height
end

local function draw_payouts(data, actions, x, y, width)
    local height = PANEL_HEADER + stack_height(4, CONTROL_HEIGHT)
        + GROUP_GAP + stack_height(2, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "分红设置")

    local inner_x, inner_width = x + 18, width - 36
    local cursor = y + PANEL_HEADER
    for index = 1, 4 do
        data.State.Payouts[index] = select(1, App.Widgets.Input.Integer(
            "PericoPayout" .. index,
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
        {Id="PericoApplyPayout", Label="应用所有分红", Run=actions.ApplyPayouts},
        {Id="PericoAutoPayout", Label="自动设置分红", Run=actions.AutoPayout}
    }, inner_x, cursor, inner_width)
    return height
end

local function draw_teleports(data, actions, x, y, width)
    local height = PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP
        + stack_height(2, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "传送点位")

    local inner_x, inner_width = x + 18, width - 36
    local cursor = y + PANEL_HEADER
    data.State.TeleportIndex = select(1, App.Widgets.Select.Draw(
        "PericoTeleport", "地点", data.State.TeleportIndex,
        data.Lists.Teleports, inner_x, cursor, inner_width, {MaxVisibleItems=8}
    ))
    cursor = cursor + CONTROL_HEIGHT + GROUP_GAP
    draw_buttons({
        {Id="PericoTeleportGo", Label="传送", Run=actions.TeleportSelected},
        {Id="PericoKosatka", Label="呼叫虎鲸", Run=actions.RequestKosatka}
    }, inner_x, cursor, inner_width)
    return height
end

local function draw_other(data, actions, x, y, width)
    local action_list = {
        {Id="PericoDrainage", Label="切割排水管道栅栏", Run=actions.CutDrainage},
        {Id="PericoFingerprint", Label="破解指纹门禁", Run=actions.HackFingerprint},
        {Id="PericoDualDoor", Label="破解双人门禁", Run=actions.UnlockDualDoor},
        {Id="PericoGlass", Label="切割主要目标玻璃柜", Run=actions.CutGlass},
        {Id="PericoPrimary", Label="获取主要目标", Run=actions.TakePrimary},
        {Id="PericoClearSecondary", Label="清除次要目标价值", Run=actions.ClearSecondary},
        {Id="PericoFinish", Label="一键完成", Run=actions.Finish},
        {Id="PericoNpcCut", Label="移除NPC分红", Run=actions.RemoveNpcCut},
        {Id="PericoLives", Label="无限生命数", Run=actions.InfiniteLives},
        {Id="PericoBag", Label="无限背包", Run=actions.InfiniteBag},
        {Id="PericoKeycard", Label="传送到门禁卡", Run=actions.TeleportKeycard},
        {Id="PericoKey", Label="传送到钥匙", Run=actions.TeleportKey},
        {Id="PericoBagTeleport", Label="传送到背包", Run=actions.TeleportBag}
    }
    local height = PANEL_HEADER + CONTROL_HEIGHT + GROUP_GAP
        + stack_height(#action_list, BUTTON_HEIGHT) + PANEL_BOTTOM
    panel(x, y, width, height, "其他功能")

    local inner_x, inner_width = x + 18, width - 36
    local auto_loot, changed = App.Widgets.Toggle.Draw(
        "PericoAutoLoot",
        "佩里科岛自动拾取",
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
    local gap = PANEL_GAP
    if width < 620 then
        local cursor = y
        cursor = cursor + draw_preps(data, actions, x, cursor, width) + gap
        cursor = cursor + draw_loot_panel(data, actions, {
            Id="Compound", Title="豪宅物资点", LocationLabel="豪宅物资点",
            X=x, Y=cursor, Width=width, LocationIndex="CompoundLocationIndex",
            Targets="CompoundTargets", RandomFill="CompoundRandomFill",
            Locations="CompoundLocations", SetAll="SetCompoundAll", FillLabel="豪宅空位填充"
        }) + gap
        cursor = cursor + draw_loot_panel(data, actions, {
            Id="Island", Title="岛屿物资点", LocationLabel="岛屿物资点",
            X=x, Y=cursor, Width=width, LocationIndex="IslandLocationIndex",
            Targets="IslandTargets", RandomFill="IslandRandomFill",
            Locations="IslandLocations", SetAll="SetIslandAll", FillLabel="岛屿空位填充"
        }) + gap
        cursor = cursor + draw_payouts(data, actions, x, cursor, width) + gap
        cursor = cursor + draw_teleports(data, actions, x, cursor, width) + gap
        cursor = cursor + draw_other(data, actions, x, cursor, width)
        return cursor - y
    end

    local column_width = math.floor((width - gap) * 0.5)
    local right_x = x + column_width + gap
    local left_y, right_y = y, y

    left_y = left_y + draw_preps(data, actions, x, left_y, column_width) + gap
    left_y = left_y + draw_loot_panel(data, actions, {
        Id="Compound", Title="豪宅物资点", LocationLabel="豪宅物资点",
        X=x, Y=left_y, Width=column_width, LocationIndex="CompoundLocationIndex",
        Targets="CompoundTargets", RandomFill="CompoundRandomFill",
        Locations="CompoundLocations", SetAll="SetCompoundAll", FillLabel="豪宅空位填充"
    }) + gap
    left_y = left_y + draw_loot_panel(data, actions, {
        Id="Island", Title="岛屿物资点", LocationLabel="岛屿物资点",
        X=x, Y=left_y, Width=column_width, LocationIndex="IslandLocationIndex",
        Targets="IslandTargets", RandomFill="IslandRandomFill",
        Locations="IslandLocations", SetAll="SetIslandAll", FillLabel="岛屿空位填充"
    })

    right_y = right_y + draw_payouts(data, actions, right_x, right_y, column_width) + gap
    right_y = right_y + draw_teleports(data, actions, right_x, right_y, column_width) + gap
    right_y = right_y + draw_other(data, actions, right_x, right_y, column_width)
    return math.max(left_y, right_y) - y
end

function PericoPage.Init(app)
    App = app
    App.Gui.Pages.Perico = PericoPage
    return true
end

function PericoPage.Draw(_, x, y, width, height)
    local scroll = App.Widgets.Scroll
    local context = scroll.Begin(
        "PericoPage",
        x,
        y,
        width,
        height,
        {
            BackgroundColor="Content",
            ScrollbarBackgroundColor="Content",
            Padding=0,
            Rounding=0
        }
    )

    local content_height = 0
    if context.ShouldDraw then
        content_height = draw_content(
            App.Data.Perico,
            App.Actions.Perico,
            context.OriginX,
            context.OriginY,
            context.Width
        )
    end
    scroll.End(context, content_height)
end

function PericoPage.Shutdown(app)
    if app.Gui.Pages.Perico == PericoPage then
        app.Gui.Pages.Perico = nil
    end
    App = nil
end

return PericoPage
