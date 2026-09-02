-- Mission Assistant 科兹中心页面

local KortzPage = {Name = "Gui.Pages.Kortz"}
local App

local PANEL_HEADER, CONTROL_HEIGHT, BUTTON_HEIGHT = 46, 42, 38
local STACK_GAP, GROUP_GAP, PANEL_GAP, PANEL_BOTTOM = 10, 14, 14, 18

local function stack_height(count, height)
    return count <= 0 and 0 or count * height + (count - 1) * STACK_GAP
end

local function panel(x,y,w,h,title) App.Widgets.Core.Panel(x,y,w,h,title) end

local function draw_buttons(actions,x,y,w)
    local cursor=y
    for index,action in ipairs(actions) do
        if App.Widgets.Button.Draw(action.Id,action.Label,x,cursor,w,BUTTON_HEIGHT) then action.Run() end
        cursor=cursor+BUTTON_HEIGHT
        if index<#actions then cursor=cursor+STACK_GAP end
    end
end

local function draw_preps(data,actions,x,y,w)
    local fields={
        {Id="Target",Label="主要目标",State="TargetIndex",List="Targets",Visible=8},
        {Id="Difficulty",Label="任务难度",State="DifficultyIndex",List="Difficulties"},
        {Id="Entry",Label="入侵方式",State="EntryIndex",List="Entries"},
        {Id="Loadout",Label="武器套装",State="LoadoutIndex",List="Loadouts"},
        {Id="Getaway",Label="逃离载具",State="GetawayIndex",List="Getaways"},
        {Id="Manchez",Label="载具颜色",State="ManchezColorIndex",List="ManchezColors"}
    }
    local toggles={
        {Id="Routes",Label="巡逻路线",State="GuardRoutes"},
        {Id="Cutter",Label="玻璃切割器",State="GlassCutter"},
        {Id="Drills",Label="电钻",State="PowerDrills"},
        {Id="Emp",Label="电磁脉冲装置",State="PrepEmp"},
        {Id="Weak",Label="削弱保安",State="WeakGuards"},
        {Id="ScopeSecondary",Label="侦察全部次要目标",State="ScopeSecondary"},
        {Id="ScopePoi",Label="侦察全部兴趣点",State="ScopePoi"}
    }
    local buttons={
        {Id="KortzStart",Label="开启终章",Run=actions.ApplySetup},
        {Id="KortzRefresh",Label="刷新计划板",Run=actions.RefreshBoard},
        {Id="KortzReset",Label="重置科兹中心",Run=actions.Reset}
    }
    local h=PANEL_HEADER+stack_height(#fields,CONTROL_HEIGHT)+GROUP_GAP
        +stack_height(#toggles,CONTROL_HEIGHT)+GROUP_GAP
        +stack_height(#buttons,BUTTON_HEIGHT)+PANEL_BOTTOM
    panel(x,y,w,h,"科兹中心前置")
    local ix,iw=x+18,w-36
    local cursor=y+PANEL_HEADER
    for index,field in ipairs(fields) do
        data.State[field.State]=select(1,App.Widgets.Select.Draw(
            "Kortz"..field.Id,field.Label,data.State[field.State],data.Lists[field.List],
            ix,cursor,iw,{MaxVisibleItems=field.Visible or 6}
        ))
        cursor=cursor+CONTROL_HEIGHT
        if index<#fields then cursor=cursor+STACK_GAP end
    end
    cursor=cursor+GROUP_GAP
    for index,toggle in ipairs(toggles) do
        data.State[toggle.State]=select(1,App.Widgets.Toggle.Draw(
            "Kortz"..toggle.Id,toggle.Label,data.State[toggle.State],
            ix,cursor,iw,{Height=CONTROL_HEIGHT}
        ))
        cursor=cursor+CONTROL_HEIGHT
        if index<#toggles then cursor=cursor+STACK_GAP end
    end
    cursor=cursor+GROUP_GAP
    draw_buttons(buttons,ix,cursor,iw)
    return h
end

local function draw_teleports(data,actions,x,y,w)
    local h=PANEL_HEADER+CONTROL_HEIGHT+STACK_GAP+BUTTON_HEIGHT+PANEL_BOTTOM
    panel(x,y,w,h,"传送点位")
    local ix,iw=x+18,w-36
    data.State.TeleportIndex=select(1,App.Widgets.Select.Draw(
        "KortzTeleport","地点",data.State.TeleportIndex,data.Lists.Teleports,
        ix,y+PANEL_HEADER,iw,{MaxVisibleItems=8}
    ))
    if App.Widgets.Button.Draw(
        "KortzTeleportGo","传送",ix,
        y+PANEL_HEADER+CONTROL_HEIGHT+STACK_GAP,iw,BUTTON_HEIGHT
    ) then actions.TeleportSelected() end
    return h
end

local function draw_other(data,actions,x,y,w)
    local buttons={
        {Id="KortzLives",Label="无限生命",Run=actions.InfiniteLives},
        {Id="KortzDataHack",Label="跳过数据破解",Run=actions.SkipDataHack},
        {Id="KortzFingerprint",Label="跳过指纹门禁",Run=actions.SkipFingerprint},
        {Id="KortzAccess",Label="跳过安检门禁密码",Run=actions.SkipAccessCode},
        {Id="KortzLaser",Label="移除激光网",Run=actions.RemoveLaser},
        {Id="KortzVault",Label="跳过金库门禁",Run=actions.SkipVault},
        {Id="KortzGlass",Label="切割玻璃柜",Run=actions.CutGlass},
        {Id="KortzPrimary",Label="加速获取主要目标(画作)",Run=actions.AcceleratePrimary},
        {Id="KortzSecondary",Label="加速获取次要目标(画作)",Run=actions.AccelerateSecondary},
        {Id="KortzBag",Label="无限背包",Run=actions.InfiniteBag},
        {Id="KortzGallery",Label="解锁画廊物品限制",Run=actions.UnlockGallery}
    }
    local h=PANEL_HEADER+CONTROL_HEIGHT+STACK_GAP+BUTTON_HEIGHT+GROUP_GAP
        +stack_height(#buttons,BUTTON_HEIGHT)+PANEL_BOTTOM
    panel(x,y,w,h,"其他功能")
    local ix,iw=x+18,w-36
    local cursor=y+PANEL_HEADER
    data.State.SecondaryIncome=select(1,App.Widgets.Input.Integer(
        "KortzIncome","次要目标收入",data.State.SecondaryIncome,
        ix,cursor,iw,{Minimum=-2147483648,Maximum=2147483647,Height=CONTROL_HEIGHT}
    ))
    cursor=cursor+CONTROL_HEIGHT+STACK_GAP
    if App.Widgets.Button.Draw(
        "KortzIncomeApply","设置次要目标收入",ix,cursor,iw,BUTTON_HEIGHT
    ) then actions.SetIncome() end
    cursor=cursor+BUTTON_HEIGHT+GROUP_GAP
    draw_buttons(buttons,ix,cursor,iw)
    return h
end

local function draw_content(data,actions,x,y,w)
    if w<620 then
        local cursor=y
        cursor=cursor+draw_preps(data,actions,x,cursor,w)+PANEL_GAP
        cursor=cursor+draw_other(data,actions,x,cursor,w)+PANEL_GAP
        cursor=cursor+draw_teleports(data,actions,x,cursor,w)
        return cursor-y
    end
    local cw=math.floor((w-PANEL_GAP)*0.5)
    local rx=x+cw+PANEL_GAP
    local ly,ry=y,y
    ly=ly+draw_preps(data,actions,x,ly,cw)
    ry=ry+draw_other(data,actions,rx,ry,cw)+PANEL_GAP
    ry=ry+draw_teleports(data,actions,rx,ry,cw)
    return math.max(ly,ry)-y
end

function KortzPage.Init(app)
    App=app
    App.Gui.Pages.Kortz=KortzPage
    return true
end

function KortzPage.Draw(_,x,y,w,h)
    local ctx=App.Widgets.Scroll.Begin(
        "KortzPage",x,y,w,h,
        {BackgroundColor="Content",ScrollbarBackgroundColor="Content",Padding=0,Rounding=0}
    )
    local content_height=0
    if ctx.ShouldDraw then
        content_height=draw_content(
            App.Data.Kortz,App.Actions.Kortz,ctx.OriginX,ctx.OriginY,ctx.Width
        )
    end
    App.Widgets.Scroll.End(ctx,content_height)
end

function KortzPage.Shutdown(app)
    if app.Gui.Pages.Kortz==KortzPage then app.Gui.Pages.Kortz=nil end
    App=nil
end

return KortzPage
