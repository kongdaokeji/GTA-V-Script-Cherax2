-- Mission Assistant 单人任务页面

local SoloPage={Name="Gui.Pages.Solo"}
local App

function SoloPage.Init(app)App=app;App.Gui.Pages.Solo=SoloPage;return true end

function SoloPage.Draw(_,x,y,w,h)
    local panel_h=174
    App.Widgets.Core.Panel(x,y,w,panel_h,"任务模式")
    local rx,ry,rw=x+18,y+47,w-36
    local value,changed=App.Widgets.Toggle.Draw(
        "SoloEnabled","启用单人任务",App.Data.Solo.State.Enabled,
        rx,ry,rw,{Height=48}
    )
    if changed then
        if not App.Actions.Solo.SetEnabled(value) then
            App.Data.Solo.State.Enabled=not value
        end
    end
    local gap=12;local by=ry+61;local bw=math.floor((rw-gap)*0.5)
    if App.Widgets.Button.Draw("SoloSkip","跳过检查点",rx,by,bw,38)then
        App.Actions.Solo.SkipCheckpoint()
    end
    if App.Widgets.Button.Draw("SoloHost","获取脚本主机",rx+bw+gap,by,bw,38)then
        App.Actions.Solo.GetScriptHost()
    end
end

function SoloPage.Shutdown(app)
    if app.Gui.Pages.Solo==SoloPage then app.Gui.Pages.Solo=nil end
    App=nil
end
return SoloPage
