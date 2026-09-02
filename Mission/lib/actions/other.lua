-- Mission Assistant 其他任务业务操作

local Other={Name="Actions.Other"}
local App
local function context() return App.Data.Other,App.Actions.Common end
local function stat(name,value) return App.Actions.Common.WriteStatInt(name,value) end
local function queue(label,fn) return App.Actions.Common.Queue(label,fn) end

local function packed(hash,index,value)
    local slot=App.Actions.Common.GetCharacterSlot()
    if slot==nil then return false end
    return pcall(Natives.InvokeVoid,hash,index,value,slot)
end

function Other.StartAgency()
    local d,c=context();return queue("开启事务所任务",function()
        local value=d.Config.AgencyValues[d.State.AgencyIndex+1]
        stat("MPX_FIXER_STORY_BS",value)
        local strand=value<18 and 0 or value<128 and 1 or value<2044 and 2 or -1
        if strand>=0 then stat("MPX_FIXER_STORY_STRAND",strand) end
        stat("MPX_FIXER_GENERAL_BS",-1);stat("MPX_FIXER_COMPLETED_BS",-1)
        c.Toast("已完成事务所前置")
    end)
end
function Other.FinishAgency()
    local d=context();return queue("完成事务所任务",function()
        ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.AgencyState1,51338752)
        ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.AgencyState2,50)
    end)
end
function Other.ClearPayphone() local d=context();return queue("清除电话暗杀冷却",function()ScriptGlobal.SetInt(d.Config.Globals.PayphoneCooldown,0)end)end
function Other.ClearSecurity() local d=context();return queue("清除安保合约冷却",function()ScriptGlobal.SetInt(d.Config.Globals.SecurityCooldown,0)end)end

function Other.StartTuner()
    local d,c=context();return queue("开启改装铺终章",function()
        stat("MPX_TUNER_CURRENT",d.Config.TunerValues[d.State.TunerIndex+1]);stat("MPX_TUNER_GEN_BS",-1)
        ScriptLocal.SetInt(d.Config.Scripts.TunerPlan,d.Config.Locals.TunerBoard,2);c.Toast("改装铺终章已开启")
    end)
end
function Other.FinishTuner()
    local d=context();return queue("完成改装铺任务",function()
        ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishId,101)
        ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishState,51338977)
    end)
end

function Other.StartClothing()
    local d,c=context();return queue("设置服装厂档案",function()
        stat("MPX_HACKER24_ACTIVE_ROB",d.Config.ClothingValues[d.State.ClothingIndex+1]);stat("MPX_HACKER24_GEN_BS",-1)
        c.Toast("已设置档案类型："..d.Lists.Clothing[d.State.ClothingIndex+1])
    end)
end
function Other.FinishClothing()
    local d,c=context();return queue("完成服装厂档案",function()
        for _,task in ipairs(d.Config.Scripts.Clothing) do
            if Natives.InvokeInt(d.Config.Natives.GET_RUNNING_SCRIPT_THREAD_COUNT,task.Hash)>0 then
                local bits=ScriptLocal.GetInt(task.Hash,task.Bits) or 0
                ScriptLocal.SetInt(task.Hash,task.Bits,bits|2048);ScriptLocal.SetInt(task.Hash,task.State,1)
                c.Toast(task.Name.."差事已完成");return
            end
        end
        c.Toast("未检测到正在进行的服装厂差事")
    end)
end
function Other.ResetClothing() return queue("重置档案前置",function()stat("MPX_HACKER24_GEN_BS",0)end)end
function Other.ClearClothingCooldown() return queue("清除档案冷却",function()stat("MPX_HACKER24_ROBBERY_CD",0)end)end
function Other.MakeClothingAvailable() return queue("档案状态可用",function()stat("MPX_HACKER24_WEEK_ID",0)end)end

function Other.SetSalvageType()
    local d,c=context();return queue("设置回收站类型",function()
        local value=d.Config.SalvageTypeValues[d.State.SalvageTypeIndex+1]
        for _,g in ipairs(d.Config.Globals.SalvageTypeSlots)do ScriptGlobal.SetInt(g,value)end
        c.Toast("回收站类型已设置，重新进入回收站生效")
    end)
end
function Other.SetSalvageVehicle()
    local d,c=context();return queue("设置回收站载具",function()
        local value=d.State.SalvageVehicleIndex+1
        for _,g in ipairs(d.Config.Globals.SalvageVehicleSlots)do ScriptGlobal.SetInt(g,value)end
        for _,g in ipairs(d.Config.Globals.SalvageBypassSlots)do ScriptGlobal.SetInt(g,1)end
        c.Toast("回收站载具已设置，重新进入回收站生效")
    end)
end
function Other.SkipSalvagePreps()
    local d=context();return queue("跳过回收站前置",function()
        for _,name in ipairs({"MPX_SALV23_SCOPE_BS","MPX_SALV23_GEN_BS","MPX_SALV23_FM_PROG","MPX_SALV23_INST_PROG"})do stat(name,-1)end
        ScriptLocal.SetInt(d.Config.Scripts.SalvagePlan,d.Config.Locals.SalvageBoard,2)
    end)
end
function Other.ClearSalvageCooldown()
    local d=context();return queue("清除回收站冷却",function()
        ScriptGlobal.SetInt(d.Config.Globals.SalvageCooldown1,0);ScriptGlobal.SetInt(d.Config.Globals.SalvageCooldown2,0)
        stat("MPX_SALV23_VEHROB_CD",0)
    end)
end
function Other.ForceSalvageStart()local d=context();return queue("强制开启回收站",function()ScriptLocal.SetInt(d.Config.Scripts.SalvagePlan,d.Config.Locals.SalvageForceStart,2)end)end
function Other.FinishSalvage()
    local d,c=context();return queue("完成回收站抢劫",function()
        for _,task in ipairs(d.Config.Scripts.SalvageFinales)do
            if Natives.InvokeInt(d.Config.Natives.GET_RUNNING_SCRIPT_THREAD_COUNT,task.Hash)>0 then
                ScriptLocal.SetInt(task.Hash,task.Bits,-2145370424);ScriptLocal.SetInt(task.Hash,task.State,1);c.Toast("回收站抢劫已完成");return
            end
        end;c.Toast("请先开启回收站抢劫")
    end)
end

local series_config={
    Lowrider={List="Lowrider",State="LowriderIndex",Values="LowriderValues",Stats={{"LOW_FLOW_CURRENT_PROG",1},{"LOW_FLOW_CURRENT_CALL",1},{"LOWRIDER_FLOW_COMPLETE",0}},Finish={50,17784544},Old=true},
    CasinoStory={List="CasinoStory",State="CasinoStoryIndex",Values="CasinoStoryValues",Stats={{"VCM_STORY_PROGRESS",1},{"VCM_FLOW_PROGRESS",1311695}},Finish={102,51338976},Old=true},
    Yacht={List="Yacht",State="YachtIndex",Values="YachtValues",Stats={{"YACHT_MISSION_PROG",1},{"YACHT_MISSION_FLOW",21845}},Finish={108,17784544}},
    Ulp={List="Ulp",State="UlpIndex",Values="UlpValues",Stats={{"ULP_MISSION_CURRENT",1},{"ULP_MISSION_PROGRESS",127}},Finish={100,17784544}},
    Avi={List="Avi",State="AviIndex",Values="AviValues",Stats={{"M25_AVI_MISSION_CURRENT",1}},Finish={201,17784544}}
}
function Other.StartSeries(key)
    local d,c=context();local cfg=series_config[key];return queue("开启系列任务",function()
        local value=d.Config[cfg.Values][d.State[cfg.State]+1]
        for _,entry in ipairs(cfg.Stats)do stat("MPX_"..entry[1],entry[2]==1 and value or entry[2])end
        c.Toast("已开启："..d.Lists[cfg.List][d.State[cfg.State]+1])
    end)
end
function Other.FinishSeries(key)
    local d=context();local cfg=series_config[key];return queue("完成系列任务",function()
        local script=cfg.Old and d.Config.Scripts.OldHeist or d.Config.Scripts.NewHeist
        local id=cfg.Old and d.Config.Locals.OldFinishId or d.Config.Locals.NewFinishId
        local state=cfg.Old and d.Config.Locals.OldFinishState or d.Config.Locals.NewFinishState
        ScriptLocal.SetInt(script,id,cfg.Finish[1]);ScriptLocal.SetInt(script,state,cfg.Finish[2])
    end)
end
function Other.StartDrugWars()
    local d,c=context();return queue("开启毒品战任务",function()
        local v=d.Config.DrugWarsValues[d.State.DrugWarsIndex+1];stat("MPX_XM22_CURRENT",v[1]);stat("MPX_XM22_MISSIONS",v[2]);c.Toast("已开启："..d.Lists.DrugWars[d.State.DrugWarsIndex+1])
    end)
end
function Other.FinishDrugWars()local d=context();return queue("完成毒品战",function()ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishId,183);ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishState,17784544)end)end

function Other.StartCluckin()
    local d,c=context();return queue("开启当当钟农场突袭",function()
        local slot=c.GetCharacterSlot();if slot==nil then return end
        if d.State.CluckinTaskIndex==5 then
            if not packed(d.Config.Natives.PACKED_BOOL,42108,d.State.CluckinInfiltrationIndex==1) then return end
            if not packed(d.Config.Natives.PACKED_INT,51019,d.State.CluckinWeaponIndex) then return end
            if not packed(d.Config.Natives.PACKED_INT,51021,d.State.CluckinArmourIndex) then return end
            if not packed(d.Config.Natives.PACKED_INT,51023,d.State.CluckinVehicleIndex) then return end
        end
        stat("MPX_SALV23_INST_PROG",d.Config.CluckinValues[d.State.CluckinTaskIndex+1]);c.Toast("已开启当当钟任务")
    end)
end
function Other.FinishCluckin()local d=context();return queue("完成当当钟",function()ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishId,34);ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishState,51338976)end)end

function Other.StartMcKenzie()
    local d,c=context();return queue("开启麦肯奇机库任务",function()
        if d.State.McKenzieTaskIndex==5 then
            if not packed(d.Config.Natives.PACKED_BOOL,51272,d.State.McKenzieDifficultyIndex==1) then return end
            for _,idx in ipairs(d.Config.McKenzieExtraPacked)do
                if not packed(d.Config.Natives.PACKED_BOOL,idx,d.State.McKenzieExtraEquipment) then return end
            end
        end
        stat("MPX_HACKER24_INST_BS",d.Config.McKenzieValues[d.State.McKenzieTaskIndex+1]);c.Toast("已开启麦肯奇机库任务")
    end)
end
function Other.FinishMcKenzie()local d=context();return queue("完成麦肯奇机库",function()ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishId,257);ScriptLocal.SetInt(d.Config.Scripts.NewHeist,d.Config.Locals.NewFinishState,51338976)end)end

function Other.Init(app)App=app;App.Actions.Other=Other;return true end
function Other.Shutdown(app)if app.Actions.Other==Other then app.Actions.Other=nil end;App=nil end
return Other
