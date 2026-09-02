-- Mission Assistant 赌场豪劫业务操作

local Casino = {
    Name = "Actions.Casino",
    AutoLootGeneration = 0,
    AutoLootLoopHandle = nil
}

local App

local function context()
    return App.Data.Casino, App.Actions.Common
end

local function write_stats(common, entries)
    for _, entry in ipairs(entries) do
        if not common.WriteStatInt(entry[1], entry[2]) then
            common.Toast("Stat 写入失败：" .. tostring(entry[1]))
            return false
        end
    end
    return true
end

function Casino.ApplySetup()
    local data, common = context()
    return common.Queue("应用赌场豪劫前置", function()
        local state, config = data.State, data.Config
        local approach = config.ApproachStats[state.ApproachIndex]
        local entries = {
            {"MPX_H3OPT_ACCESSPOINTS", -1},
            {"MPX_H3OPT_POI", -1},
            {"MPX_CAS_HEIST_FLOW", -1},
            {"MPX_H3OPT_APPROACH", approach[1]},
            {"MPX_H3_HARD_APPROACH", approach[2]},
            {"MPX_H3_LAST_APPROACH", approach[3]},
            {"MPX_H3OPT_TARGET", config.TargetValues[state.TargetIndex + 1]},
            {"MPX_H3OPT_BITSET1", -1},
            {"MPX_H3OPT_BITSET0", -1},
            {"MPX_H3OPT_KEYLEVELS", config.KeyLevelValues[state.KeyLevelIndex + 1]},
            {"MPX_H3OPT_DISRUPTSHIP", config.GuardStrengthValues[state.GuardStrengthIndex + 1]},
            {"MPX_H3OPT_CREWWEAP", config.GunmanValues[state.GunmanIndex + 1]},
            {"MPX_H3OPT_CREWDRIVER", config.DriverValues[state.DriverIndex + 1]},
            {"MPX_H3OPT_CREWHACKER", config.HackerValues[state.HackerIndex + 1]},
            {"MPX_H3OPT_MASKS", state.MaskIndex},
            {"MPX_H3OPT_VEHS", config.VehicleVariantValues[state.VehicleVariantIndex + 1]},
            {"MPX_H3OPT_WEAPS", config.WeaponVariantValues[state.WeaponVariantIndex + 1]}
        }
        if not write_stats(common, entries) then return end
        ScriptLocal.SetInt(config.Scripts.Planning, config.Locals.RefreshBoard, 2)
        common.Toast(string.format(
            "赌场豪劫终章配置已应用完成！\n入侵方式：%s\n抢劫目标：%s\n枪手等级：%s\n车手等级：%s\n黑客等级：%s",
            data.Lists.Approaches[state.ApproachIndex + 1],
            data.Lists.Targets[state.TargetIndex + 1],
            data.Lists.Gunmen[state.GunmanIndex + 1],
            data.Lists.Drivers[state.DriverIndex + 1],
            data.Lists.Hackers[state.HackerIndex + 1]
        ))
    end)
end

function Casino.ForceReady()
    local data, common = context()
    return common.Queue("赌场豪劫强制准备", function()
        for _, global in ipairs(data.Config.Globals.ForceReady) do
            ScriptGlobal.SetInt(global, 1)
        end
        common.Toast("所有玩家已强制准备就绪 (赌场豪劫)")
    end)
end

function Casino.RefreshBoard()
    local data, common = context()
    return common.Queue("刷新赌场计划板", function()
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.RefreshBoard, 2)
        common.Toast("计划板已刷新")
    end)
end

function Casino.ScopePoints()
    local _, common = context()
    return common.Queue("侦查兴趣点", function()
        if common.WriteStatInt("MPX_H3OPT_POI", -1) then
            common.Toast("已侦查所有兴趣点")
        end
    end)
end

function Casino.ScopeAccess()
    local _, common = context()
    return common.Queue("侦查出入口", function()
        if common.WriteStatInt("MPX_H3OPT_ACCESSPOINTS", -1) then
            common.Toast("已侦查所有出入口")
        end
    end)
end

function Casino.Reset()
    local data, common = context()
    return common.Queue("重置赌场豪劫", function()
        local names = {
            "MPX_H3_LAST_APPROACH", "MPX_H3_HARD_APPROACH", "MPX_H3_APPROACH",
            "MPX_H3OPT_APPROACH", "MPX_H3OPT_CREWWEAP", "MPX_H3OPT_WEAPS",
            "MPX_H3OPT_CREWDRIVER", "MPX_H3OPT_VEHS", "MPX_H3OPT_CREWHACKER",
            "MPX_H3OPT_MASKS", "MPX_H3OPT_TARGET", "MPX_H3OPT_DISRUPTSHIP",
            "MPX_H3OPT_BODYARMORLVL", "MPX_H3OPT_KEYLEVELS", "MPX_H3OPT_BITSET0",
            "MPX_H3OPT_BITSET1", "MPPLY_H3_COOLDOWN"
        }
        local entries = {}
        for _, name in ipairs(names) do entries[#entries + 1] = {name, 0} end
        if not write_stats(common, entries) then return end
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.RefreshBoard, 2)
        common.Toast("已重置赌场豪劫")
    end)
end

function Casino.ApplyPayouts()
    local data, common = context()
    return common.Queue("应用赌场分红", function()
        for index = 1, 4 do
            ScriptGlobal.SetInt(
                data.Config.Globals.Payout + index,
                math.floor(tonumber(data.State.Payouts[index]) or 0)
            )
        end
        common.Toast(string.format(
            "赌场分红已应用：%d / %d / %d / %d",
            data.State.Payouts[1], data.State.Payouts[2],
            data.State.Payouts[3], data.State.Payouts[4]
        ))
    end)
end

local function apply_weekly(value, enabled, multiplier)
    return enabled and math.floor(value * multiplier + 0.5) or value
end

local function weekly_boost_available(data, common)
    local available = common.IsWeeklyBoostAvailable(data.Config.WeeklyBoostBit)
    if available == nil then
        common.Toast("无法读取赌场每周首次状态")
    end
    return available
end

function Casino.AutoPayout()
    local data, common = context()
    return common.Queue("赌场自动分红", function()
        local config = data.Config
        local weekly_first = weekly_boost_available(data, common)
        if weekly_first == nil then return end
        local target = common.ReadStatInt("MPX_H3OPT_TARGET") or 0
        local difficulty = ScriptGlobal.GetInt(config.Globals.Difficulty) == 2 and 2 or 1
        local payouts = config.PayoutValues[target]
        if not payouts then
            common.Toast("未选择金库目标或目标无效")
            return
        end

        local raw = apply_weekly(payouts[difficulty], weekly_first, config.WeeklyMultiplier)
        local cap = apply_weekly(config.MaxSafeCap, weekly_first, config.WeeklyMultiplier)
        local buyer = config.BuyerLevels[ScriptGlobal.GetInt(config.Globals.Buyer)] or 0
        local after_buyer = raw - raw * (config.BuyerFees[buyer] or 0.10)
        local gunman = common.ReadStatInt("MPX_H3OPT_CREWWEAP") or 1
        local driver = common.ReadStatInt("MPX_H3OPT_CREWDRIVER") or 1
        local hacker = common.ReadStatInt("MPX_H3OPT_CREWHACKER") or 1
        local npc = after_buyer * 0.05
            + after_buyer * (config.GunmanCuts[gunman] or 0.05)
            + after_buyer * (config.DriverCuts[driver] or 0.05)
            + after_buyer * (config.HackerCuts[hacker] or 0.03)
        local pool = after_buyer - npc
        if pool <= 0 then
            common.Toast("自动分红计算失败：有效奖池为 0")
            return
        end
        local percent = math.floor(cap / (pool / 100))
        for index = 1, 4 do
            ScriptGlobal.SetInt(config.Globals.Payout + index, percent)
        end
        common.Toast(string.format(
            "已应用赌场自动分红 %d%%（每周首次：%s）",
            percent,
            weekly_first and "可用" or "已使用"
        ))
    end)
end

local function get_property_blip(data)
    local n = data.Config.Natives
    local blip = Natives.InvokeInt(n.GET_FIRST_BLIP_INFO_ID, data.Config.ArcadeBlip)
    local best = 0
    while blip ~= 0 do
        local color = Natives.InvokeInt(n.GET_BLIP_COLOUR, blip)
        if color ~= 69 and color ~= 3 and color ~= 93 then
            if color == 0 or color == 4 then return blip end
            if best == 0 then best = blip end
        end
        blip = Natives.InvokeInt(n.GET_NEXT_BLIP_INFO_ID, data.Config.ArcadeBlip)
    end
    return best
end

function Casino.TeleportSelected()
    local data, common = context()
    return common.Queue("赌场传送", function()
        local name = data.Lists.Teleports[data.State.TeleportIndex + 1]
        if name == "游戏厅" then
            local blip = get_property_blip(data)
            if blip == 0 then
                common.Toast("未检测到 [游戏厅] 的有效图标")
                return
            end
            local x, y, z = Natives.InvokeV3(data.Config.Natives.GET_BLIP_COORDS, blip)
            if x and common.Teleport(data.Config, x, y, z) then
                common.Toast("已传送到：游戏厅")
            end
            return
        end
        local coords = data.Config.TeleportCoords[name]
        if coords and common.Teleport(data.Config, coords[1], coords[2], coords[3]) then
            common.Toast("已传送至：" .. name)
        else
            common.Toast("未配置传送点：" .. tostring(name))
        end
    end)
end

function Casino.HackKeypad()
    local data, common = context()
    return common.Queue("破解门禁", function()
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.HackKeypad, 5)
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.HackFingerprint, 5)
    end)
end

function Casino.HackDualKeypad()
    local data, common = context()
    return common.Queue("解锁双人门禁", function()
        local player = GTA.GetLocalPlayerId()
        ScriptLocal.SetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.UnlockDoor1 + player * data.Config.Locals.PlayerStride + 143,
            8
        )
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.UnlockDoor2, 5)
    end)
end

function Casino.SkipVaultDrill()
    local data, common = context()
    return common.Queue("跳过金库门钻孔", function()
        local value = ScriptLocal.GetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.DrillVaultTarget
        )
        if type(value) ~= "number" then
            common.Toast("无法读取金库门钻孔目标值")
            return
        end
        ScriptLocal.SetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.DrillVaultSet,
            value
        )
    end)
end

local function target_amount(data, common)
    local weekly_first = weekly_boost_available(data, common)
    if weekly_first == nil then return nil end
    local target = common.ReadStatInt("MPX_H3OPT_TARGET") or 0
    local difficulty = ScriptGlobal.GetInt(data.Config.Globals.Difficulty) == 2 and 2 or 1
    local payouts = data.Config.PayoutValues[target]
    local amount = payouts and payouts[difficulty] or data.Config.MaxSafeCap
    return apply_weekly(amount, weekly_first, data.Config.WeeklyMultiplier)
end

function Casino.Finish()
    local data, common = context()
    return common.Queue("赌场一键完成", function()
        local amount = target_amount(data, common)
        if amount == nil then return end
        common.WithMissionHost(data.Config, function()
            local approach = common.ReadStatInt("MPX_H3OPT_APPROACH") or 0
            if approach == 3 then
                ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.QuickFinishBase, 12)
            else
                ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.State1, 5)
            end
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.CutPercent, 80)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.TargetAmount, amount)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.Timer1, 99999)
            for player = 0, 3 do
                ScriptLocal.SetInt(
                    data.Config.Scripts.OldHeist,
                    data.Config.Locals.TimerPlayers
                        + player * data.Config.Locals.PlayerStride
                        + data.Config.Locals.PlayerTimerOffset,
                    99999
                )
            end
        end)
    end)
end

function Casino.TakeTarget()
    local data, common = context()
    return common.Queue("赌场一键拿取", function()
        local target = common.ReadStatInt("MPX_H3OPT_TARGET")
        local payouts = target ~= nil and data.Config.PayoutValues[target] or nil
        if not payouts then
            common.Toast("未检测到有效的赌场金库目标")
            return
        end
        local difficulty = ScriptGlobal.GetInt(data.Config.Globals.Difficulty) == 2 and 2 or 1
        local weekly_first = weekly_boost_available(data, common)
        if weekly_first == nil then return end
        local amount = apply_weekly(
            payouts[difficulty],
            weekly_first,
            data.Config.WeeklyMultiplier
        )
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.TargetAmount, amount)
        common.Toast(string.format(
            "已设置 [%s] %s模式拿取金额：$%d",
            data.Config.TargetNames[target],
            difficulty == 2 and "困难" or "普通",
            amount
        ))
    end)
end

function Casino.InfiniteLives()
    local data, common = context()
    return common.Queue("赌场无限生命数", function()
        common.WithMissionHost(data.Config, function()
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.InfiniteLives, 10000)
            common.Toast("已开启赌场无限生命数")
        end)
    end)
end

function Casino.InfiniteVaultTimer()
    local data, common = context()
    return common.Queue("赌场无限金库倒计时", function()
        local player = GTA.GetLocalPlayerId()
        local global = data.Config.Globals.VaultCountdown + 1 + player * 194 + 44
        ScriptGlobal.SetInt(global, 30 * 60 * 1000)
        common.Toast("赌场金库倒计时已设置为 30 分钟")
    end)
end

function Casino.SetAutoLootEnabled(enabled)
    local data, common = context()
    enabled = enabled == true

    if data.State.AutoLootEnabled == enabled then
        return true
    end

    data.State.AutoLootEnabled = enabled
    Casino.AutoLootGeneration = Casino.AutoLootGeneration + 1

    if not enabled then
        Casino.AutoLootLoopHandle = nil
        common.Toast("赌场自动拾取已关闭")
        return true
    end

    local generation = Casino.AutoLootGeneration
    local ok, handle = pcall(Script.RegisterLooped, function()
        if not data.State.AutoLootEnabled
            or generation ~= Casino.AutoLootGeneration
        then
            return false
        end

        local loot_state = ScriptLocal.GetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.LootState
        )
        if loot_state == 5 then
            data.State.AutoLootEnabled = false
            Casino.AutoLootGeneration = Casino.AutoLootGeneration + 1
            Casino.AutoLootLoopHandle = nil
            common.Toast("赌场自动拾取已完成，循环已关闭")
            return false
        end

        ScriptLocal.SetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.LootState,
            4
        )
        ScriptLocal.SetFloat(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.LootSpeed,
            2.0
        )
        Script.Yield(100)
        return true
    end)

    if not ok or not handle then
        data.State.AutoLootEnabled = false
        Casino.AutoLootGeneration = Casino.AutoLootGeneration + 1
        Casino.AutoLootLoopHandle = nil
        common.Toast("无法创建赌场自动拾取循环")
        return false
    end

    Casino.AutoLootLoopHandle = handle
    common.Toast("赌场自动拾取已启用")
    return true
end

function Casino.Init(app)
    App = app
    App.Actions.Casino = Casino
    return true
end

function Casino.Shutdown(app)
    if app.Data.Casino then
        app.Data.Casino.State.AutoLootEnabled = false
    end
    Casino.AutoLootGeneration = Casino.AutoLootGeneration + 1
    Casino.AutoLootLoopHandle = nil
    if app.Actions.Casino == Casino then
        app.Actions.Casino = nil
    end
    App = nil
end

return Casino
