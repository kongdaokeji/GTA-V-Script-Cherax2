-- Mission Assistant 任务载具页面

local VehiclesPage={Name="Gui.Pages.Vehicles"}
local App
local PH,BH,GAP,BOTTOM=47,40,10,18
local function panel_height(count)return PH+count*BH+math.max(0,count-1)*GAP+BOTTOM end

local function draw_panel(title,items,x,y,w)
    local h=panel_height(#items);App.Widgets.Core.Panel(x,y,w,h,title)
    local ix,iw=x+18,w-36
    for index,item in ipairs(items)do
        if App.Widgets.Button.Draw(item.Id,item.Label,ix,y+PH+(index-1)*(BH+GAP),iw,BH)then item.Run()end
    end
    return h
end

local function draw_content(data,actions,x,y,w)
    local common={}
    for index,preset in ipairs(data.Presets)do
        local preset_index=index
        common[#common+1]={Id="Vehicle"..preset.Id,Label=preset.Label,Run=function()actions.SpawnPreset(preset_index)end}
    end
    local other={
        {Id="VehicleRepair",Label="修复载具",Run=actions.Repair},
        {Id="VehicleEnterPersonal",Label="进入个人载具",Run=actions.EnterPersonalVehicle}
    }
    if w<620 then
        local c=y;c=c+draw_panel("常用载具",common,x,c,w)+14;c=c+draw_panel("其他功能",other,x,c,w);return c-y
    end
    local cw=math.floor((w-14)*0.5);local rx=x+cw+14
    return math.max(draw_panel("常用载具",common,x,y,cw),draw_panel("其他功能",other,rx,y,cw))
end

function VehiclesPage.Init(app)App=app;App.Gui.Pages.Vehicles=VehiclesPage;return true end
function VehiclesPage.Draw(_,x,y,w,h)
    local ctx=App.Widgets.Scroll.Begin("VehiclesPage",x,y,w,h,{BackgroundColor="Content",ScrollbarBackgroundColor="Content",Padding=0,Rounding=0})
    local ch=0;if ctx.ShouldDraw then ch=draw_content(App.Data.Vehicles,App.Actions.Vehicles,ctx.OriginX,ctx.OriginY,ctx.Width)end
    App.Widgets.Scroll.End(ctx,ch)
end
function VehiclesPage.Shutdown(app)if app.Gui.Pages.Vehicles==VehiclesPage then app.Gui.Pages.Vehicles=nil end;App=nil end
return VehiclesPage
