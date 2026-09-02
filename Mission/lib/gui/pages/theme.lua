-- Mission Assistant 主题设置页面

local ThemePage={Name="Gui.Pages.Theme"}
local App
local PH,CH,BH,SG,GG,PG,PB=46,42,38,10,14,14,18
local function sh(n,h)return n<=0 and 0 or n*h+(n-1)*SG end
local function panel(x,y,w,h,t)App.Widgets.Core.Panel(x,y,w,h,t)end
local function index_of(items,value)
    for i,item in ipairs(items)do if item.Value==value then return i-1 end end
    return 0
end
local function enum_select(id,label,key,items,x,y,w)
    local labels={}for i,item in ipairs(items)do labels[i]=item.Label end
    local manager=App.Theme.Manager;local old=index_of(items,manager.Get(key))
    local value,changed=App.Widgets.Select.Draw(id,label,old,labels,x,y,w)
    if changed then manager.Set(key,items[value+1].Value,true)end
end
local function number_input(id,label,key,min,max,x,y,w)
    local manager=App.Theme.Manager;local value,changed=App.Widgets.Input.Integer(
        id,label,manager.Get(key),x,y,w,{Minimum=min,Maximum=max,Height=CH}
    )
    if changed then manager.Set(key,value,true)end
end

local UI_MODES={{Label="经典界面",Value="classic"},{Label="玻璃界面",Value="glass"}}
local NAV={{Label="图标和文字",Value="full"},{Label="纯图标",Value="icons"}}
local DENSITY={{Label="紧凑",Value="compact"},{Label="标准",Value="standard"},{Label="宽松",Value="comfortable"}}
local OVERLAY={{Label="浅色",Value="light"},{Label="深色",Value="dark"}}
local BG_MODE={{Label="覆盖",Value="cover"},{Label="适应",Value="contain"},{Label="拉伸",Value="stretch"},{Label="居中",Value="center"}}
local CURSOR_STYLES={{Label="自动（浅黑 / 深白）",Value="auto"},{Label="经典白色",Value="classic"},{Label="玻璃黑色",Value="glass"}}

local function hotkey_row(x,y,w)
    local core=App.Widgets.Core;local ui=App.Data.State.Ui;local manager=App.Theme.Manager
    local row_height=CH
    local box_width=math.min(w,230,math.max(116,math.floor(w*0.58)))
    local box_x=x+w-box_width
    core.Text(x,y+(row_height-ImGui.GetTextLineHeight())*0.5,"显示/隐藏热键","ControlLabel")
    local label
    if ui.RebindingKey then
        label="按下新键..."
    else
        label=manager.ToggleKeyName()
    end
    local pressed=App.Widgets.Button.Draw(
        "ThemeHotkey",label,box_x,y+3,box_width,row_height-6,
        {Tooltip="点击后按下任意键重新绑定显示/隐藏热键，按 Esc 取消"}
    )
    if pressed then
        ui.RebindingKey=true;ui.RebindBaseline=nil
    end
end

local function layout_panel(x,y,w)
    local h=PH+sh(10,CH)+PB;panel(x,y,w,h,"界面")
    local ix,iw=x+18,w-36;local c=y+PH
    hotkey_row(ix,c,iw);c=c+CH+SG
    enum_select("ThemeMode","界面模式","UiMode",UI_MODES,ix,c,iw);c=c+CH+SG
    enum_select("ThemeNav","导航样式","NavigationStyle",NAV,ix,c,iw);c=c+CH+SG
    enum_select("ThemeCursor","鼠标样式","CursorStyle",CURSOR_STYLES,ix,c,iw);c=c+CH+SG
    enum_select("ThemeDensity","界面密度","Density",DENSITY,ix,c,iw);c=c+CH+SG
    enum_select("ThemeOverlay","遮罩风格","OverlayStyle",OVERLAY,ix,c,iw);c=c+CH+SG
    number_input("ThemeRadius","圆角","CornerRadius",0,24,ix,c,iw);c=c+CH+SG
    number_input("ThemeText","文字比例","TextScale",80,130,ix,c,iw);c=c+CH+SG
    number_input("ThemePanelAlpha","面板透明度","PanelOpacity",0,100,ix,c,iw);c=c+CH+SG
    number_input("ThemeOverlayAlpha","遮罩强度","OverlayOpacity",0,100,ix,c,iw)
    return h
end

local function color_panel(x,y,w)
    local h=PH+sh(3,CH)+PB;panel(x,y,w,h,"强调色")
    local ix,iw=x+18,w-36;local c=y+PH
    number_input("ThemeR","强调色 R","AccentR",0,255,ix,c,iw);c=c+CH+SG
    number_input("ThemeG","强调色 G","AccentG",0,255,ix,c,iw);c=c+CH+SG
    number_input("ThemeB","强调色 B","AccentB",0,255,ix,c,iw)
    local col=App.Theme.Current.Colors.Accent
    ImGui.AddRectFilled(x+w-48,y+15,x+w-20,y+31,col[1],col[2],col[3],col[4],5,0)
    return h
end

local function background_panel(x,y,w)
    local h=PH+CH+SG+CH+SG+CH+SG+sh(5,CH)+GG+BH+26+PB;panel(x,y,w,h,"背景")
    local m=App.Theme.Manager;local ix,iw=x+18,w-36;local c=y+PH
    local enabled,changed=App.Widgets.Toggle.Draw("ThemeBgEnabled","启用背景图片",m.Get("BackgroundEnabled"),ix,c,iw,{Height=CH})
    if changed then
        if enabled and not m.IsGlass()then m.Set("UiMode","glass",false)end
        m.Set("BackgroundEnabled",enabled,true)
    end
    c=c+CH+SG
    local bgidx=m.BackgroundIndex();local newidx,bgchanged=App.Widgets.Select.Draw("ThemeBackground","背景图片",bgidx,m.Backgrounds,ix,c,iw,{MaxVisibleItems=8})
    if bgchanged then m.SetBackgroundIndex(newidx)end;c=c+CH+SG
    enum_select("ThemeBgMode","显示模式","BackgroundMode",BG_MODE,ix,c,iw);c=c+CH+SG
    local window_opacity,window_changed=App.Widgets.Input.Integer(
        "ThemeWindowOpacity","窗口透明度",m.Get("WindowOpacity"),ix,c,iw,
        {Minimum=0,Maximum=100,Height=CH,Enabled=m.IsGlass()}
    )
    if window_changed then m.Set("WindowOpacity",window_opacity,true)end;c=c+CH+SG
    number_input("ThemeBgOpacity","背景透明度","BackgroundOpacity",0,100,ix,c,iw);c=c+CH+SG
    number_input("ThemeBgScale","背景缩放","BackgroundScale",50,200,ix,c,iw);c=c+CH+SG
    number_input("ThemeBgX","水平偏移","BackgroundOffsetX",-1000,1000,ix,c,iw);c=c+CH+SG
    number_input("ThemeBgY","垂直偏移","BackgroundOffsetY",-1000,1000,ix,c,iw);c=c+CH+GG
    if App.Widgets.Button.Draw(
        "ThemeRefreshBackground","刷新背景列表",ix,c,iw,BH,
        {Tooltip="扫描目录："..m.BackgroundDirectory()}
    )then
        m.RefreshBackgrounds()
        local count=m.BackgroundCount()
        App.Actions.Common.Toast(count>0
            and("已找到 "..count.." 张背景图片")
            or("未找到背景图片，请检查目录："..m.BackgroundDirectory()),5000)
    end
    App.Widgets.Core.Text(ix,c+BH+8,"目录：Mission/theme/backgrounds","TextSecondary")
    return h
end

local function actions_panel(x,y,w)
    local h=PH+BH+PB;panel(x,y,w,h,"主题配置");local ix,iw=x+18,w-36;local gap=12;local bw=math.floor((iw-gap)*0.5)
    if App.Widgets.Button.Draw("ThemeSave","保存主题",ix,y+PH,bw,BH)then
        App.Actions.Common.Toast(App.Theme.Manager.Save()and"主题配置已保存"or"主题配置保存失败")
    end
    if App.Widgets.Button.Draw("ThemeReset","恢复默认",ix+bw+gap,y+PH,bw,BH)then
        App.Actions.Common.Toast(App.Theme.Manager.Reset()and"已恢复默认主题"or"恢复默认主题失败")
    end
    return h
end

local function draw_content(x,y,w)
    if w<620 then
        local c=y;c=c+layout_panel(x,c,w)+PG;c=c+background_panel(x,c,w)+PG;c=c+color_panel(x,c,w)+PG;c=c+actions_panel(x,c,w);return c-y
    end
    local cw=math.floor((w-PG)*0.5);local rx=x+cw+PG;local ly,ry=y,y
    ly=ly+background_panel(x,ly,cw)+PG;ly=ly+actions_panel(x,ly,cw)
    ry=ry+layout_panel(rx,ry,cw)+PG;ry=ry+color_panel(rx,ry,cw)
    return math.max(ly,ry)-y
end

function ThemePage.Init(app)App=app;App.Gui.Pages.Theme=ThemePage;return true end
function ThemePage.Draw(_,x,y,w,h)
    local ctx=App.Widgets.Scroll.Begin("ThemePage",x,y,w,h,{BackgroundColor="Content",ScrollbarBackgroundColor="Content",Padding=0,Rounding=0})
    local ch=0;if ctx.ShouldDraw then ch=draw_content(ctx.OriginX,ctx.OriginY,ctx.Width)end
    App.Widgets.Scroll.End(ctx,ch)
end
function ThemePage.Shutdown(app)if app.Gui.Pages.Theme==ThemePage then app.Gui.Pages.Theme=nil end;App=nil end
return ThemePage
