-- Mission Assistant 设置页面
-- 仅保留显示/隐藏热键设置。

local SettingsPage={Name="Gui.Pages.Settings"}
local App
local PH,CH,PB=46,42,18
local function panel(x,y,w,h,t)App.Widgets.Core.Panel(x,y,w,h,t)end

local function hotkey_row(x,y,w)
    local core=App.Widgets.Core;local ui=App.Data.State.Ui;local hotkey=App.Hotkey
    local row_height=CH
    local box_width=math.min(w,230,math.max(116,math.floor(w*0.58)))
    local box_x=x+w-box_width
    core.Text(x,y+(row_height-ImGui.GetTextLineHeight())*0.5,"显示/隐藏热键","ControlLabel")
    local label
    if ui.RebindingKey then
        label="按下新键..."
    else
        label=hotkey.ToggleKeyName()
    end
    local pressed=App.Widgets.Button.Draw(
        "SettingsHotkey",label,box_x,y+3,box_width,row_height-6,
        {Tooltip="点击后按下任意键重新绑定显示/隐藏热键，按 Esc 取消"}
    )
    if pressed then
        ui.RebindingKey=true;ui.RebindBaseline=nil
    end
end

local function draw_content(x,y,w)
    local h=PH+CH+PB;panel(x,y,w,h,"设置")
    hotkey_row(x+18,y+PH,w-36)
    return h
end

function SettingsPage.Init(app)App=app;App.Gui.Pages.Settings=SettingsPage;return true end
function SettingsPage.Draw(_,x,y,w,h)
    local ctx=App.Widgets.Scroll.Begin("SettingsPage",x,y,w,h,{BackgroundColor="Content",ScrollbarBackgroundColor="Content",Padding=0,Rounding=0})
    local ch=0;if ctx.ShouldDraw then ch=draw_content(ctx.OriginX,ctx.OriginY,ctx.Width)end
    App.Widgets.Scroll.End(ctx,ch)
end
function SettingsPage.Shutdown(app)if app.Gui.Pages.Settings==SettingsPage then app.Gui.Pages.Settings=nil end;App=nil end
return SettingsPage
