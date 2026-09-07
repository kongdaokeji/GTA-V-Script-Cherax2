-- Mission Assistant 快捷功能业务操作

local Quick={Name="Actions.Quick"}
local App
local function context()return App.Data.Quick,App.Actions.Common end
local function write_stats(entries)
    local common=App.Actions.Common;local ok=true
    for _,entry in ipairs(entries)do if not common.WriteStatInt(entry[1],entry[2])then ok=false end end
    return ok
end
local function to_int32(value)
    local u=math.floor(tonumber(value)or 0)&0xFFFFFFFF
    return u>=0x80000000 and u-0x100000000 or u
end

function Quick.FillHealth()
    local d,c=context();return c.Queue("补充血量",function()
        local ped=Natives.InvokeInt(d.Natives.PLAYER_PED_ID);if ped==0 then return end
        local maximum=Natives.InvokeInt(d.Natives.GET_PED_MAX_HEALTH,ped)
        Natives.InvokeVoid(d.Natives.SET_ENTITY_HEALTH,ped,maximum,0,0);c.Toast("血量已补满")
    end)
end
function Quick.FillArmour()
    local d,c=context();return c.Queue("补充护甲",function()
        local ped=Natives.InvokeInt(d.Natives.PLAYER_PED_ID);if ped==0 then return end
        Natives.InvokeVoid(d.Natives.SET_PED_ARMOUR,ped,100);c.Toast("护甲已补满")
    end)
end
function Quick.FillSnacks()local d,c=context();return c.Queue("补满零食",function()local ok=write_stats(d.Stats.Snacks);c.Toast(ok and"零食已补满"or"补充零食失败")end)end
function Quick.FillBodyArmour()local d,c=context();return c.Queue("补满防弹衣",function()local ok=write_stats(d.Stats.Armour);c.Toast(ok and"防弹衣已补满"or"补充防弹衣失败")end)end
function Quick.FillBreathing()local d,c=context();return c.Queue("补满呼吸器",function()local ok=write_stats(d.Stats.Breathing);c.Toast(ok and"呼吸器已补满"or"补充呼吸器失败")end)end
function Quick.ClearWanted()
    local d,c=context();return c.Queue("清除通缉",function()
        local player=Natives.InvokeInt(d.Natives.PLAYER_ID)
        Natives.InvokeVoid(d.Natives.SET_PLAYER_WANTED_LEVEL,player,0,false)
        Natives.InvokeVoid(d.Natives.SET_PLAYER_WANTED_LEVEL_NOW,player,false);c.Toast("通缉已清除")
    end)
end
function Quick.Suicide()
    local d,c=context();return c.Queue("自杀",function()
        local ped=Natives.InvokeInt(d.Natives.PLAYER_PED_ID);if ped~=0 then Natives.InvokeVoid(d.Natives.SET_ENTITY_HEALTH,ped,0,0,0)end
    end)
end
function Quick.UnlockGtaPlus()
    local d,c=context();return c.Queue("解锁 GTA+",function()
        local player=GTA.GetLocalPlayerId();local g=d.Globals
        ScriptGlobal.SetBool(g.GtaPlusValid,true)
        ScriptGlobal.SetInt(g.GtaPlusFlags,to_int32((ScriptGlobal.GetInt(g.GtaPlusFlags)or 0)|(1<<3)))
        local pg=g.PlayerInfoBase+player*g.PlayerInfoStride+g.PlayerGtaPlusFlags
        ScriptGlobal.SetInt(pg,to_int32((ScriptGlobal.GetInt(pg)or 0)|(1<<31)))
        ScriptGlobal.SetInt(g.GtaPlusSessionType,11);c.Toast("已成功解锁 GTA+ 会员")
    end)
end
function Quick.SkipCutscene()
    local d,c=context();return c.Queue("跳过过场动画",function()
        if not Natives.InvokeBool(d.Natives.IS_CUTSCENE_PLAYING)then c.Toast("当前没有正在播放的过场动画");return end
        Natives.InvokeVoid(d.Natives.STOP_CUTSCENE_IMMEDIATELY);Natives.InvokeVoid(d.Natives.REMOVE_CUTSCENE);c.Toast("已跳过过场动画")
    end)
end
function Quick.SkipConversation()
    local d,c=context();return c.Queue("跳过当前对话",function()
        if not Natives.InvokeBool(d.Natives.IS_SCRIPTED_CONVERSATION_ONGOING)then c.Toast("当前没有正在播放的对话");return end
        Natives.InvokeVoid(d.Natives.SKIP_TO_NEXT_SCRIPTED_CONVERSATION_LINE);c.Toast("已跳过当前对话")
    end)
end
function Quick.SwitchFriendSession()
    local d=context();return App.Actions.Common.Queue("切换非公开好友战局",function()
        ScriptGlobal.SetInt(d.Globals.SessionType,6);ScriptGlobal.SetInt(d.Globals.SessionState,1);ScriptGlobal.SetInt(d.Globals.SessionExtra,0)
    end)
end
function Quick.BailToMainMenu()
    local d,c=context();return c.Queue("卡云退主菜单",function()
        if not Natives.InvokeBool(d.Natives.NETWORK_CAN_BAIL)then c.Toast("当前状态无法退出线上模式");return end
        Natives.InvokeVoid(d.Natives.NETWORK_BAIL,15,0,0);c.Toast("正在退出当前战局...")
    end)
end
function Quick.ForceCloudSave()
    local d,c=context();return c.Queue("强制云存档",function()
        Script.ExecuteAsScript("freemode",function()
            Natives.InvokeBool(d.Natives.FORCE_CLOUD_SAVE,0,false,3,false)
        end)
    end)
end
function Quick.ApplySelfCut()
    local d,c=context();return c.Queue("设置本地分红",function()
        local value=math.max(-10000,math.min(10000,math.floor(tonumber(d.State.SelfCut)or 0)))
        ScriptGlobal.SetInt(d.Globals.SelfCut,value);c.Toast("已应用本地分红："..value.."%")
    end)
end

function Quick.Init(app)App=app;App.Actions.Quick=Quick;return true end
function Quick.Shutdown(app)if app.Actions.Quick==Quick then app.Actions.Quick=nil end;App=nil end
return Quick
