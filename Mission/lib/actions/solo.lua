-- Mission Assistant 单人任务业务操作

local Solo={Name="Actions.Solo",LoopGeneration=0,LoopHandle=nil}
local App
local function context()return App.Data.Solo,App.Actions.Common end
local function running(data,hash)
    return Natives.InvokeInt(data.Natives.GET_RUNNING_SCRIPT_THREAD_COUNT,hash)>0
end
local function apply_settings(data)
    if running(data,data.Scripts.Launcher)then
        local variation=ScriptLocal.GetInt(data.Scripts.Launcher,data.Locals.LauncherVariation)
        if type(variation)=="number" and variation>0 then
            ScriptLocal.SetInt(data.Scripts.Launcher,data.Locals.LauncherMinPlayers,1)
            ScriptGlobal.SetInt(
                data.Globals.MissionMinBase+variation*data.Globals.MissionMinStride+data.Globals.MissionMinOffset,1
            )
        end
    end
    ScriptGlobal.SetInt(data.Globals.MinParticipants,1)
    ScriptGlobal.SetInt(data.Globals.NumberOfTeams,1)
    ScriptGlobal.SetInt(data.Globals.MaxNumberOfTeams,1)
    ScriptGlobal.SetInt(data.Globals.FirstTeamSlots,1)
    ScriptGlobal.SetInt(data.Globals.CriticalMinimum,0)
end
local function controller(data)
    local candidates={
        {Hash=data.Scripts.MissionV3,Skip=data.Locals.SkipV3,Check=data.Locals.HostChecks.MissionV3},
        {Hash=data.Scripts.NewHeist,Skip=data.Locals.SkipNew,Check=data.Locals.HostChecks.NewHeist},
        {Hash=data.Scripts.OldHeist,Skip=data.Locals.SkipOld,Check=data.Locals.HostChecks.OldHeist}
    }
    for _,candidate in ipairs(candidates)do if running(data,candidate.Hash)then return candidate end end
    return nil
end
local function acquire(data,candidate,common,show)
    if ScriptLocal.GetInt(candidate.Hash,candidate.Check)==1 then
        if show then common.Toast("当前已经是脚本主机")end
        return true
    end
    GTA.ForceScriptHost(candidate.Hash);Script.Yield(1500)
    if ScriptLocal.GetInt(candidate.Hash,candidate.Check)==1 then
        if show then common.Toast("成功获取脚本主机")end
        return true
    end
    common.Toast("获取脚本主机失败");return false
end

function Solo.SetEnabled(enabled)
    local data,common=context();enabled=enabled==true
    if data.State.Enabled==enabled then return true end
    data.State.Enabled=enabled;Solo.LoopGeneration=Solo.LoopGeneration+1
    if not enabled then
        Solo.LoopHandle=nil;common.Toast("单人任务已禁用");return true
    end
    local generation=Solo.LoopGeneration
    local ok,handle=pcall(Script.RegisterLooped,function()
        if not data.State.Enabled or generation~=Solo.LoopGeneration then return false end
        apply_settings(data);Script.Yield(100);return true
    end)
    if not ok or not handle then
        data.State.Enabled=false;Solo.LoopGeneration=Solo.LoopGeneration+1
        common.Toast("无法创建单人任务循环");return false
    end
    Solo.LoopHandle=handle;common.Toast("单人任务已启用");return true
end

function Solo.SkipCheckpoint()
    local data,common=context();return common.Queue("跳过检查点",function()
        local current=controller(data)
        if not current then common.Toast("未检测到运行中的任务脚本线程");return end
        if not acquire(data,current,common,false)then return end
        local value=ScriptLocal.GetInt(current.Hash,current.Skip)
        if type(value)~="number" then common.Toast("无法读取当前检查点");return end
        ScriptLocal.SetInt(current.Hash,current.Skip,value|(1<<17));common.Toast("已跳过检查点")
    end)
end
function Solo.GetScriptHost()
    local data,common=context();return common.Queue("获取脚本主机",function()
        local current=controller(data)
        if not current then common.Toast("未检测到运行中的任务脚本线程");return end
        acquire(data,current,common,true)
    end)
end
function Solo.Init(app)App=app;App.Actions.Solo=Solo;return true end
function Solo.Shutdown(app)
    if app.Data.Solo then app.Data.Solo.State.Enabled=false end
    Solo.LoopGeneration=Solo.LoopGeneration+1;Solo.LoopHandle=nil
    if app.Actions.Solo==Solo then app.Actions.Solo=nil end;App=nil
end
return Solo
