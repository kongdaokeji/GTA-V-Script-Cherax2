-- Mission Assistant 科兹中心业务操作

local Kortz = {Name = "Actions.Kortz"}
local App

local function context()
    return App.Data.Kortz, App.Actions.Common
end

local function to_int32(value)
    local unsigned = math.floor(tonumber(value) or 0) & 0xFFFFFFFF
    return unsigned >= 0x80000000 and unsigned - 0x100000000 or unsigned
end

local function set_flag(value, mask, enabled)
    return enabled and (value | mask) or (value & ~mask)
end

local function choose_flag(value, group, selected)
    return (value & ~group) | selected
end

local function with_finale_host(data, common, callback)
    if Natives.InvokeInt(
        data.Config.Natives.GET_RUNNING_SCRIPT_THREAD_COUNT,
        data.Config.Scripts.Finale
    ) <= 0 then
        common.Toast("未检测到科兹中心终章")
        return false
    end
    GTA.ForceScriptHost(data.Config.Scripts.Finale)
    Script.Yield(1500)
    if ScriptLocal.GetInt(data.Config.Scripts.Finale, data.Config.Locals.HostCheck) ~= 1 then
        common.Toast("获取科兹中心脚本主机失败")
        return false
    end
    callback()
    return true
end

function Kortz.ApplySetup()
    local data, common = context()
    return common.Queue("应用科兹中心前置", function()
        local s, c = data.State, data.Config
        local general, robbery = -1, -1
        general = choose_flag(general, c.Masks.LoadoutGroup, c.LoadoutMasks[s.LoadoutIndex + 1])
        robbery = choose_flag(robbery, c.Masks.EntryGroup, c.EntryMasks[s.EntryIndex + 1])
        robbery = choose_flag(robbery, c.Masks.GetawayGroup, c.GetawayMasks[s.GetawayIndex + 1])
        general = set_flag(general, c.Masks.ManholeKey, s.EntryIndex == 3)
        general = general & ~c.Masks.ManchezGroup
        if s.GetawayIndex == 2 then
            general = general | c.ManchezMasks[s.ManchezColorIndex + 1]
        end
        for _, prep in ipairs(c.Preps) do
            general = set_flag(general, prep.General, s[prep.Field])
            robbery = set_flag(robbery, prep.Robbery, s[prep.Field])
        end
        general = set_flag(general, c.Masks.HardMode, s.DifficultyIndex == 1)
        general = set_flag(general, c.Masks.WeakGuards, s.WeakGuards)

        local entries = {
            {c.Stats.General, to_int32(general)}, {c.Stats.General2, -1},
            {c.Stats.Robbery, to_int32(robbery)}, {c.Stats.Target, s.TargetIndex},
            {c.Stats.Scoping, s.ScopeSecondary and -1 or 0},
            {c.Stats.Poi, s.ScopePoi and -1 or 0}
        }
        for _, entry in ipairs(entries) do
            if not common.WriteStatInt(entry[1], entry[2]) then
                common.Toast("Stat 写入失败：" .. entry[1])
                return
            end
        end
        ScriptLocal.SetInt(c.Scripts.Planning, c.Locals.Board, 2)
        common.Toast(string.format(
            "配置已应用：%s / %s",
            data.Lists.Targets[s.TargetIndex + 1],
            data.Lists.Difficulties[s.DifficultyIndex + 1]
        ))
    end)
end

function Kortz.RefreshBoard()
    local data, common = context()
    return common.Queue("刷新科兹中心计划板", function()
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.Board, 2)
        common.Toast("计划板已刷新")
    end)
end

function Kortz.Reset()
    local data, common = context()
    return common.Queue("重置科兹中心", function()
        local c = data.Config
        for _, entry in ipairs({
            {c.Stats.General,125890590}, {c.Stats.General2,-1}, {c.Stats.Robbery,0},
            {c.Stats.Scoping,0}, {c.Stats.Poi,-2}, {c.Stats.Target,0},
            {c.Stats.BuyRequirements,0}
        }) do common.WriteStatInt(entry[1], entry[2]) end
        ScriptLocal.SetInt(c.Scripts.Planning, c.Locals.Board, 2)
        common.Toast("科兹中心已重置")
    end)
end

local function hosted(label, callback)
    local data, common = context()
    return common.Queue(label, function()
        with_finale_host(data, common, callback)
    end)
end

function Kortz.SetIncome()
    local data, common = context()
    return hosted("设置次要目标收入", function()
        local value = math.max(-2147483648, math.min(2147483647,
            math.floor(tonumber(data.State.SecondaryIncome) or 0)))
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.Income, value)
        common.Toast("次要目标收入已设置为 " .. value)
    end)
end

function Kortz.InfiniteLives()
    local data, common = context()
    return hosted("科兹中心无限生命", function()
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.Lives, 10000)
        common.Toast("生命数已设置为无限")
    end)
end

function Kortz.SkipDataHack()
    local data, common = context()
    return common.Queue("跳过数据破解", function()
        for index = 0, 7 do
            ScriptLocal.SetInt(data.Config.Scripts.Finale,
                data.Config.Locals.DataHack + 1 + index * 4, 1)
        end
        common.Toast("已跳过数据破解")
    end)
end

function Kortz.SkipFingerprint()
    local data, common = context()
    return common.Queue("跳过指纹门禁", function()
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.Fingerprint, 5)
        common.Toast("已跳过指纹门禁")
    end)
end

function Kortz.SkipAccessCode()
    local data, common = context()
    return common.Queue("跳过安检门禁密码", function()
        local codes = {}
        for index = 0, 2 do
            local screen = data.Config.Locals.AccessCode + 2 + index * 2
            local code = ScriptLocal.GetInt(data.Config.Scripts.Finale, screen + 1)
            if type(code) ~= "number" then
                common.Toast("无法读取正确的安检门禁密码")
                return
            end
            codes[#codes + 1] = code
            ScriptLocal.SetFloat(data.Config.Scripts.Finale, screen, code + 0.0)
        end
        common.Toast(string.format("门禁代码已匹配：%02d - %02d - %02d", codes[1],codes[2],codes[3]))
    end)
end

function Kortz.RemoveLaser()
    local data, common = context()
    return common.Queue("移除激光网", function()
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.Laser, 4294784)
        local value = ScriptGlobal.GetInt(data.Config.Globals.LaserState) or 0
        ScriptGlobal.SetInt(data.Config.Globals.LaserState, value | 1)
        common.Toast("已移除激光网")
    end)
end

function Kortz.SkipVault()
    local data, common = context()
    return common.Queue("跳过金库门禁", function()
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.Vault, 5)
        common.Toast("已跳过金库门禁")
    end)
end

function Kortz.CutGlass()
    local data, common = context()
    return common.Queue("切割玻璃柜", function()
        for index = 0, 4 do
            ScriptLocal.SetFloat(data.Config.Scripts.Finale,
                data.Config.Locals.Glass + 1 + index * 13 + 3, 100.0)
        end
        common.Toast("玻璃切割进度已设为 100%")
    end)
end

function Kortz.AcceleratePrimary()
    local data, common = context()
    return common.Queue("加速获取主要目标", function()
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.TargetStage, 15)
        Script.Yield(2000)
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.TargetStage, 17)
        common.Toast("已加速获取主要目标")
    end)
end

function Kortz.AccelerateSecondary()
    local data, common = context()
    return common.Queue("加速获取次要目标", function()
        ScriptLocal.SetInt(data.Config.Scripts.Finale, data.Config.Locals.TargetStage, 3)
        common.Toast("已加速获取次要目标")
    end)
end

function Kortz.InfiniteBag()
    local data, common = context()
    return common.Queue("科兹中心无限背包", function()
        local address = ScriptGlobal.GetTunableByHash(data.Config.Tunables.BagCapacity)
        if address ~= 0 then
            Memory.WriteInt(address, 10000)
            common.Toast("背包容量已设置为无限")
        end
    end)
end

function Kortz.UnlockGallery()
    local data, common = context()
    return common.Queue("解锁画廊物品限制", function()
        for _, index in ipairs(data.Config.Globals.SecondaryTargetIndices) do
            local base = data.Config.Globals.SecondaryTargetsBase + index * 333
            ScriptGlobal.SetInt(base + 68, 0)
            ScriptGlobal.SetInt(base + 143, 0)
        end
        common.Toast("画廊物品限制已解锁")
    end)
end

function Kortz.TeleportSelected()
    local data, common = context()
    return common.Queue("科兹中心传送", function()
        local name = data.Lists.Teleports[data.State.TeleportIndex + 1]
        local coords = data.Config.TeleportCoords[name]
        if coords and common.Teleport(data.Config, coords[1], coords[2], coords[3]) then
            common.Toast("已传送至：" .. name)
        end
    end)
end

function Kortz.Init(app)
    App = app
    App.Actions.Kortz = Kortz

    -- 启动时读取已保存的主要目标和困难模式。
    local data = App.Data.Kortz
    local common = App.Actions.Common
    local target = common.ReadStatInt(data.Config.Stats.Target)
    if type(target) == "number" then
        data.State.TargetIndex = math.max(0, math.min(target, #data.Lists.Targets - 1))
    end
    local general = common.ReadStatInt(data.Config.Stats.General)
    if type(general) == "number" then
        data.State.DifficultyIndex = (general & data.Config.Masks.HardMode) ~= 0 and 1 or 0
    end

    return true
end

function Kortz.Shutdown(app)
    if app.Actions.Kortz == Kortz then app.Actions.Kortz = nil end
    App = nil
end

return Kortz
