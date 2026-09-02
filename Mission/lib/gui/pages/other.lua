-- Mission Assistant 其他任务页面

local OtherPage={Name="Gui.Pages.Other"}
local App
local PH,CH,BH,SG,GG,PG,PB=46,42,38,10,14,14,18
local function sh(n,h)return n<=0 and 0 or n*h+(n-1)*SG end
local function panel(x,y,w,h,t)App.Widgets.Core.Panel(x,y,w,h,t)end
local function button(id,label,x,y,w,run)if App.Widgets.Button.Draw(id,label,x,y,w,BH)then run()end end
local function buttons(items,x,y,w)
    for i,item in ipairs(items)do button(item[1],item[2],x,y+(i-1)*(BH+SG),w,item[3])end
end
local function select_field(id,label,state_key,list_key,data,x,y,w,visible)
    data.State[state_key]=select(1,App.Widgets.Select.Draw(id,label,data.State[state_key],data.Lists[list_key],x,y,w,{MaxVisibleItems=visible or 8}))
end

local function contract_panel(data,actions,opt)
    local extra=opt.Extra or{};local count=2+#extra;local h=PH+CH+GG+sh(count,BH)+PB
    panel(opt.X,opt.Y,opt.W,h,opt.Title);local ix,iw=opt.X+18,opt.W-36
    select_field(opt.Id.."Select","任务",opt.State,opt.List,data,ix,opt.Y+PH,iw,8)
    local items={{opt.Id.."Start","开启",opt.Start},{opt.Id.."Finish","一键完成",opt.Finish}}
    for _,v in ipairs(extra)do items[#items+1]=v end
    buttons(items,ix,opt.Y+PH+CH+GG,iw);return h
end

local function clothing_panel(d,a,x,y,w)
    local h=PH+CH+GG+sh(5,BH)+PB;panel(x,y,w,h,"服装厂");local ix,iw=x+18,w-36
    select_field("OtherClothing","任务","ClothingIndex","Clothing",d,ix,y+PH,iw)
    buttons({
        {"ClothingStart","开启",a.StartClothing},{"ClothingFinish","一键完成",a.FinishClothing},
        {"ClothingReset","重置档案前置",a.ResetClothing},{"ClothingCooldown","清除档案冷却",a.ClearClothingCooldown},
        {"ClothingAvailable","档案状态可用",a.MakeClothingAvailable}
    },ix,y+PH+CH+GG,iw);return h
end

local function salvage_panel(d,a,x,y,w)
    local h=PH+CH+SG+BH+GG+CH+SG+BH+GG+sh(4,BH)+PB
    panel(x,y,w,h,"回收站");local ix,iw=x+18,w-36;local c=y+PH
    select_field("SalvageType","任务类型","SalvageTypeIndex","SalvageTypes",d,ix,c,iw)
    c=c+CH+SG;button("SalvageTypeApply","设置类型",ix,c,iw,a.SetSalvageType)
    c=c+BH+GG;select_field("SalvageVehicle","抢劫载具","SalvageVehicleIndex","SalvageVehicles",d,ix,c,iw,8)
    c=c+CH+SG;button("SalvageVehicleApply","设置载具",ix,c,iw,a.SetSalvageVehicle)
    c=c+BH+GG;buttons({
        {"SalvagePreps","跳过前置",a.SkipSalvagePreps},{"SalvageCd","清除冷却",a.ClearSalvageCooldown},
        {"SalvageForce","强制开启",a.ForceSalvageStart},{"SalvageFinish","一键完成",a.FinishSalvage}
    },ix,c,iw);return h
end

local function series_panel(d,a,opt)
    local h=PH+CH+GG+sh(2,BH)+PB;panel(opt.X,opt.Y,opt.W,h,opt.Title);local ix,iw=opt.X+18,opt.W-36
    select_field(opt.Id.."Task","任务",opt.State,opt.List,d,ix,opt.Y+PH,iw,8)
    buttons({
        {opt.Id.."Start","开启",function()if opt.Key=="DrugWars"then a.StartDrugWars()else a.StartSeries(opt.Key)end end},
        {opt.Id.."Finish","一键完成",function()if opt.Key=="DrugWars"then a.FinishDrugWars()else a.FinishSeries(opt.Key)end end}
    },ix,opt.Y+PH+CH+GG,iw);return h
end

local function cluckin_panel(d,a,x,y,w)
    local h=PH+sh(5,CH)+GG+sh(2,BH)+PB;panel(x,y,w,h,"当当钟农场突袭");local ix,iw=x+18,w-36;local c=y+PH
    local fields={{"任务类型","CluckinTaskIndex","CluckinTasks",8},{"入侵方式","CluckinInfiltrationIndex","CluckinInfiltrations"},{"武器套装","CluckinWeaponIndex","CluckinWeapons"},{"防弹背心","CluckinArmourIndex","CluckinArmour"},{"逃跑载具","CluckinVehicleIndex","CluckinVehicles",8}}
    for i,f in ipairs(fields)do select_field("Cluckin"..i,f[1],f[2],f[3],d,ix,c,iw,f[4]);c=c+CH;if i<#fields then c=c+SG end end
    c=c+GG;buttons({{"CluckinStart","开启",a.StartCluckin},{"CluckinFinish","一键完成",a.FinishCluckin}},ix,c,iw);return h
end

local function mckenzie_panel(d,a,x,y,w)
    local h=PH+sh(2,CH)+GG+CH+GG+sh(2,BH)+PB;panel(x,y,w,h,"麦肯奇机库");local ix,iw=x+18,w-36;local c=y+PH
    select_field("McKenzieTask","任务类型","McKenzieTaskIndex","McKenzieTasks",d,ix,c,iw)
    c=c+CH+SG;select_field("McKenzieDifficulty","任务难度","McKenzieDifficultyIndex","McKenzieDifficulties",d,ix,c,iw)
    c=c+CH+GG;d.State.McKenzieExtraEquipment=select(1,App.Widgets.Toggle.Draw("McKenzieExtra","解锁额外装备",d.State.McKenzieExtraEquipment,ix,c,iw,{Height=CH}))
    c=c+CH+GG;buttons({{"McKenzieStart","开启",a.StartMcKenzie},{"McKenzieFinish","一键完成",a.FinishMcKenzie}},ix,c,iw);return h
end

local function draw_content(d,a,x,y,w)
    local function agency(xx,yy,ww)return contract_panel(d,a,{X=xx,Y=yy,W=ww,Title="事务所",Id="Agency",State="AgencyIndex",List="Agency",Start=a.StartAgency,Finish=a.FinishAgency,Extra={{"AgencyPayphone","清除电话暗杀冷却",a.ClearPayphone},{"AgencySecurity","清除安保合约冷却",a.ClearSecurity}}})end
    local function tuner(xx,yy,ww)return contract_panel(d,a,{X=xx,Y=yy,W=ww,Title="改装铺",Id="Tuner",State="TunerIndex",List="Tuner",Start=a.StartTuner,Finish=a.FinishTuner})end
    local series={
        {"Lowrider","古惑跳跳车","LowriderIndex","Lowrider"},{"CasinoStory","赌场故事","CasinoStoryIndex","CasinoStory"},
        {"Yacht","超级游艇人生","YachtIndex","Yacht"},{"Ulp","觅迹行动","UlpIndex","Ulp"},
        {"DrugWars","洛圣都毒品战","DrugWarsIndex","DrugWars"},{"Avi","阿维施瓦茨曼","AviIndex","Avi"}
    }
    if w<620 then
        local c=y;c=c+agency(x,c,w)+PG;c=c+clothing_panel(d,a,x,c,w)+PG;c=c+salvage_panel(d,a,x,c,w)+PG;c=c+cluckin_panel(d,a,x,c,w)+PG;c=c+mckenzie_panel(d,a,x,c,w)+PG;c=c+tuner(x,c,w)+PG
        for _,s in ipairs(series)do c=c+series_panel(d,a,{X=x,Y=c,W=w,Id=s[1],Title=s[2],State=s[3],List=s[4],Key=s[1]})+PG end
        return c-y
    end
    local cw=math.floor((w-PG)*0.5);local rx=x+cw+PG;local ly,ry=y,y
    ly=ly+agency(x,ly,cw)+PG;ly=ly+clothing_panel(d,a,x,ly,cw)+PG;ly=ly+salvage_panel(d,a,x,ly,cw)+PG;ly=ly+cluckin_panel(d,a,x,ly,cw)+PG;ly=ly+mckenzie_panel(d,a,x,ly,cw)
    ry=ry+tuner(rx,ry,cw)+PG
    for _,s in ipairs(series)do ry=ry+series_panel(d,a,{X=rx,Y=ry,W=cw,Id=s[1],Title=s[2],State=s[3],List=s[4],Key=s[1]})+PG end
    return math.max(ly,ry)-y
end

function OtherPage.Init(app)App=app;App.Gui.Pages.Other=OtherPage;return true end
function OtherPage.Draw(_,x,y,w,h)
    local ctx=App.Widgets.Scroll.Begin("OtherPage",x,y,w,h,{BackgroundColor="Content",ScrollbarBackgroundColor="Content",Padding=0,Rounding=0})
    local ch=0;if ctx.ShouldDraw then ch=draw_content(App.Data.Other,App.Actions.Other,ctx.OriginX,ctx.OriginY,ctx.Width)end
    App.Widgets.Scroll.End(ctx,ch)
end
function OtherPage.Shutdown(app)if app.Gui.Pages.Other==OtherPage then app.Gui.Pages.Other=nil end;App=nil end
return OtherPage
