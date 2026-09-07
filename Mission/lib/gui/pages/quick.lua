-- Mission Assistant 快捷功能页面

local QuickPage={Name="Gui.Pages.Quick"}
local App
local PH,BH,GAP,BOTTOM=47,38,10,18
local function panel_height(n)return PH+n*BH+math.max(0,n-1)*GAP+BOTTOM end
local function draw_panel(title,items,x,y,w)
    local h=panel_height(#items);App.Widgets.Core.Panel(x,y,w,h,title);local ix,iw=x+18,w-36
    for i,item in ipairs(items)do
        if App.Widgets.Button.Draw(item[1],item[2],ix,y+PH+(i-1)*(BH+GAP),iw,BH)then item[3]()end
    end
    return h
end
local function draw_payout(data,actions,x,y,w)
    local h=116;App.Widgets.Core.Panel(x,y,w,h,"本地分红");local rx,ry,rw=x+18,y+48,w-36
    local set_w=math.min(180,math.max(120,math.floor(rw*0.25)));local input_w=rw-set_w-12
    data.State.SelfCut=select(1,App.Widgets.Input.Integer(
        "QuickSelfCut","分红比例",data.State.SelfCut,rx,ry,input_w,
        {Minimum=-10000,Maximum=10000,Height=42}
    ))
    if App.Widgets.Button.Draw("QuickApplyCut","设置",rx+input_w+12,ry,set_w,42)then actions.ApplySelfCut()end
    return h
end
local function draw_content(data,a,x,y,w)
    local self_actions={
        {"QuickHealth","补充血量",a.FillHealth},{"QuickArmour","补充护甲",a.FillArmour},
        {"QuickSnacks","补满零食",a.FillSnacks},{"QuickBodyArmour","补满防弹衣",a.FillBodyArmour},
        {"QuickBreathing","补满呼吸器",a.FillBreathing},{"QuickWanted","清除通缉",a.ClearWanted},
        {"QuickSuicide","自杀",a.Suicide},{"QuickGtaPlus","解锁GTA+会员",a.UnlockGtaPlus}
    }
    local quick_actions={
        {"QuickCutscene","跳过过场动画",a.SkipCutscene},{"QuickConversation","跳过当前对话",a.SkipConversation},
        {"QuickSession","切换非公开好友战局",a.SwitchFriendSession},{"QuickBail","卡云退主菜单",a.BailToMainMenu},
        {"QuickCloudSave","强制云存档",a.ForceCloudSave}
    }
    if w<620 then
        local sy=draw_panel("自我选项",self_actions,x,y,w);local qy=y+sy+14
        local qh=draw_panel("快捷功能",quick_actions,x,qy,w);local py=qy+qh+14
        return py+draw_payout(data,a,x,py,w)-y
    end
    local cw=math.floor((w-14)*0.5);local rx=x+cw+14
    local lh=draw_panel("自我选项",self_actions,x,y,cw);local rh=draw_panel("快捷功能",quick_actions,rx,y,cw)
    local py=y+rh+14;local ph=draw_payout(data,a,rx,py,cw)
    return math.max(lh,rh+14+ph)
end
function QuickPage.Init(app)App=app;App.Gui.Pages.Quick=QuickPage;return true end
function QuickPage.Draw(_,x,y,w,h)
    local ctx=App.Widgets.Scroll.Begin("QuickPage",x,y,w,h,{BackgroundColor="Content",ScrollbarBackgroundColor="Content",Padding=0,Rounding=0})
    local ch=0;if ctx.ShouldDraw then ch=draw_content(App.Data.Quick,App.Actions.Quick,ctx.OriginX,ctx.OriginY,ctx.Width)end
    App.Widgets.Scroll.End(ctx,ch)
end
function QuickPage.Shutdown(app)if app.Gui.Pages.Quick==QuickPage then app.Gui.Pages.Quick=nil end;App=nil end
return QuickPage
