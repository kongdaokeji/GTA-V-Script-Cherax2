-- Mission Assistant 佩里科岛业务操作

local Perico = {
    Name = "Actions.Perico",
    AutoLootGeneration = 0,
    AutoLootLoopHandle = nil,
    DoorTaskGeneration = 0
}

local App

local function context()
    return App.Data.Perico, App.Actions.Common
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

local function random_material(pool)
    return pool[math.random(1, #pool)]
end

local function build_masks(indices, count, random_fill, material_values, pool)
    local masks = {CASH = 0, WEED = 0, COKE = 0, GOLD = 0}
    for index = 1, count do
        local material = material_values[(indices[index] or 1) + 1]
        if material == "RANDOM" or (material == "NONE" and random_fill) then
            material = random_material(pool)
        end
        if material and material ~= "NONE" then
            masks[material] = masks[material] | (1 << (index - 1))
        end
    end
    return masks
end

function Perico.SetCompoundAll(material_index)
    local data, common = context()
    for index = 1, #data.Lists.CompoundLocations do
        data.State.CompoundTargets[index] = material_index
    end
    common.Toast(material_index == 1
        and "豪宅 8 处物资点已设为：无 (清空)！"
        or "豪宅 8 处物资点已设为：黄金！")
end

function Perico.SetIslandAll(material_index)
    local data, common = context()
    for index = 1, #data.Lists.IslandLocations do
        data.State.IslandTargets[index] = material_index
    end
    common.Toast(material_index == 1
        and "全岛 24 处物资点已设为：无 (清空)！"
        or "全岛 24 处物资点已设为：黄金！")
end

function Perico.ApplySetup()
    local data, common = context()
    return common.Queue("应用佩里科岛前置", function()
        local state = data.State
        local config = data.Config
        local compound = build_masks(
            state.CompoundTargets,
            8,
            state.CompoundRandomFill,
            config.MaterialValues,
            {"CASH", "GOLD"}
        )
        local island = build_masks(
            state.IslandTargets,
            24,
            state.IslandRandomFill,
            config.MaterialValues,
            {"CASH", "WEED", "COKE"}
        )
        local difficulty = config.DifficultyValues[state.DifficultyIndex + 1]
        local target = config.TargetValues[state.TargetIndex + 1]
        local weapon = config.WeaponValues[state.WeaponIndex + 1]
        local painting = config.PaintingValues[state.PaintingIndex + 1]

        local entries = {
            {"MPX_H4_PROGRESS", difficulty},
            {"MPX_H4CNF_TARGET", target},
            {"MPX_H4CNF_WEAPONS", weapon},
            {"MPX_H4LOOT_CASH_C", compound.CASH},
            {"MPX_H4LOOT_CASH_C_SCOPED", compound.CASH},
            {"MPX_H4LOOT_WEED_C", compound.WEED},
            {"MPX_H4LOOT_WEED_C_SCOPED", compound.WEED},
            {"MPX_H4LOOT_COKE_C", compound.COKE},
            {"MPX_H4LOOT_COKE_C_SCOPED", compound.COKE},
            {"MPX_H4LOOT_GOLD_C", compound.GOLD},
            {"MPX_H4LOOT_GOLD_C_SCOPED", compound.GOLD},
            {"MPX_H4LOOT_CASH_I", island.CASH},
            {"MPX_H4LOOT_CASH_I_SCOPED", island.CASH},
            {"MPX_H4LOOT_WEED_I", island.WEED},
            {"MPX_H4LOOT_WEED_I_SCOPED", island.WEED},
            {"MPX_H4LOOT_COKE_I", island.COKE},
            {"MPX_H4LOOT_COKE_I_SCOPED", island.COKE},
            {"MPX_H4LOOT_GOLD_I", island.GOLD},
            {"MPX_H4LOOT_GOLD_I_SCOPED", island.GOLD},
            {"MPX_H4LOOT_PAINT", painting},
            {"MPX_H4LOOT_PAINT_SCOPED", painting},
            {"MPX_H4LOOT_CASH_V", 83250},
            {"MPX_H4LOOT_WEED_V", 135000},
            {"MPX_H4LOOT_COKE_V", 202500},
            {"MPX_H4LOOT_GOLD_V", 458484},
            {"MPX_H4LOOT_PAINT_V", 343863},
            {"MPX_H4CNF_BS_ABIL", 63},
            {"MPX_H4CNF_WEP_DISRP", 3},
            {"MPX_H4CNF_ARM_DISRP", 3},
            {"MPX_H4CNF_HEL_DISRP", 3},
            {"MPX_H4CNF_BOLTCUT", 15},
            {"MPX_H4CNF_UNIFORM", 8},
            {"MPX_H4CNF_GRAPPEL", 2},
            {"MPX_H4_MISSIONS", -1},
            {"MPX_H4CNF_TROJAN", 1},
            {"MPX_H4CNF_BS_GEN", 131071},
            {"MPX_H4_PLAYTHROUGH_STATUS", 100}
        }

        if not write_stats(common, entries) then return end
        ScriptLocal.SetInt(
            config.Scripts.Planning,
            config.Locals.PlanApply,
            2
        )
        common.Toast(string.format(
            "佩里科岛终章配置已应用完成！\n任务难度：%s\n主要目标：%s\n武器套装：%s",
            data.Lists.Difficulties[state.DifficultyIndex + 1],
            data.Lists.Targets[state.TargetIndex + 1],
            data.Lists.Weapons[state.WeaponIndex + 1]
        ))
    end)
end

function Perico.ForceReady()
    local data, common = context()
    return common.Queue("佩里科岛强制准备", function()
        for _, global in ipairs(data.Config.Globals.ForceReady) do
            ScriptGlobal.SetInt(global, 1)
        end
        common.Toast("所有玩家已强制准备就绪 (佩里科岛)")
    end)
end

function Perico.RefreshBoard()
    local data, common = context()
    return common.Queue("刷新佩里科岛计划板", function()
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.PlanApply, 2)
        common.Toast("计划板已刷新")
    end)
end

local function unlock_stat(name, message)
    local _, common = context()
    return common.Queue(message, function()
        if common.WriteStatInt(name, -1) then common.Toast(message) end
    end)
end

function Perico.UnlockEntry()
    return unlock_stat("MPX_H4CNF_BS_ENTR", "已解锁所有入侵点")
end

function Perico.UnlockEscape()
    return unlock_stat("MPX_H4CNF_APPROACH", "已解锁所有逃离点")
end

function Perico.UnlockInterest()
    return unlock_stat("MPX_H4CNF_BS_GEN", "已解锁所有兴趣点")
end

function Perico.Reset()
    local data, common = context()
    return common.Queue("重置佩里科岛", function()
        local entries = {
            {"MPX_H4_PROGRESS", 0},
            {"MPX_H4_MISSIONS", 0},
            {"MPX_H4CNF_APPROACH", 0},
            {"MPX_H4CNF_BS_GEN", 0},
            {"MPX_H4CNF_BS_ENTR", 0},
            {"MPX_H4CNF_BS_ABIL", 0},
            {"MPX_H4_PLAYTHROUGH_STATUS", 0},
            {"MPX_H4CNF_TARGET", -1}
        }
        if not write_stats(common, entries) then return end
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.PlanApply, 2)
        common.Toast("已重置")
    end)
end

function Perico.ApplyPayouts()
    local data, common = context()
    return common.Queue("应用佩里科岛分红", function()
        for index = 1, 4 do
            ScriptGlobal.SetInt(
                data.Config.Globals.Payout + index,
                math.floor(tonumber(data.State.Payouts[index]) or 0)
            )
        end
        common.Toast(string.format(
            "分红已应用：%d / %d / %d / %d",
            data.State.Payouts[1], data.State.Payouts[2],
            data.State.Payouts[3], data.State.Payouts[4]
        ))
    end)
end

function Perico.AutoPayout()
    local data, common = context()
    return common.Queue("自动设置佩里科岛分红", function()
        local target = common.ReadStatInt("MPX_H4CNF_TARGET")
        local difficulty = common.ReadStatInt("MPX_H4_PROGRESS")
        local values = data.Config.PayoutValues[difficulty]
        local payout = values and values[target]
        if not payout then
            common.Toast("未知目标或难度，无法设置分红")
            return
        end
        for index = 1, 4 do
            ScriptGlobal.SetInt(data.Config.Globals.Payout + index, payout)
        end
        common.Toast(string.format(
            "已为 %s 设置分红为 %d",
            data.Config.TargetNames[target] or "未知目标",
            payout
        ))
    end)
end

function Perico.TeleportSelected()
    local data, common = context()
    return common.Queue("佩里科岛传送", function()
        local name = data.Lists.Teleports[data.State.TeleportIndex + 1]
        if name == "虎鲸" then
            if Natives.InvokeInt(
                data.Config.Natives.GET_FIRST_BLIP_INFO_ID,
                data.Config.Kosatka.RequestBlip
            ) == 0 then
                common.Toast("错误：未检测到虎鲸图标，请先点击呼叫虎鲸")
                return
            end
            local position = data.Config.Kosatka.Position
            local ped = Natives.InvokeInt(data.Config.Natives.PLAYER_PED_ID)
            if ped == 0 then
                common.Toast("失败：无法获取玩家")
                return
            end
            local vehicle = Natives.InvokeInt(
                data.Config.Natives.GET_VEHICLE_PED_IS_IN,
                ped,
                false
            )
            local entity = vehicle ~= 0 and vehicle or ped
            for tick = 1, 100 do
                Natives.InvokeVoid(
                    data.Config.Natives.SET_ENTITY_COORDS,
                    entity,
                    position[1], position[2], position[3],
                    false, false, false, false
                )
                if Natives.InvokeInt(
                    data.Config.Natives.GET_FIRST_BLIP_INFO_ID,
                    data.Config.Kosatka.InteriorBlip
                ) ~= 0 then
                    Natives.InvokeVoid(
                        data.Config.Natives.SET_ENTITY_HEADING,
                        entity,
                        data.Config.Kosatka.Heading
                    )
                    Natives.InvokeVoid(
                        data.Config.Natives.SET_GAMEPLAY_CAM_RELATIVE_HEADING,
                        0.0
                    )
                    common.Toast("已传送到虎鲸内部")
                    return
                end
                if not common.Yield(50) then return end
            end
            common.Toast("传送超时：5秒内未传送到虎鲸内部")
            return
        end

        local coords = data.Config.TeleportCoords[name]
        if not coords then
            common.Toast("未配置传送点：" .. tostring(name))
            return
        end
        if common.Teleport(data.Config, coords[1], coords[2], coords[3]) then
            common.Toast("已传送至：" .. name)
        end
    end)
end

function Perico.RequestKosatka()
    local data, common = context()
    return common.Queue("呼叫虎鲸", function()
        ScriptGlobal.SetInt(data.Config.Globals.KosatkaRequest, 1)
        common.Toast("正在呼叫虎鲸...")
    end)
end

local function local_action(label, key, value, is_float)
    local data, common = context()
    return common.Queue(label, function()
        if is_float then
            ScriptLocal.SetFloat(data.Config.Scripts.NewHeist, data.Config.Locals[key], value)
        else
            ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals[key], value)
        end
    end)
end

function Perico.CutDrainage() return local_action("切割排水管道", "CutDrainage", 6) end
function Perico.HackFingerprint() return local_action("破解指纹门禁", "Fingerprint", 5) end
function Perico.CutGlass() return local_action("切割玻璃柜", "CutGlass", 100.0, true) end

function Perico.TakePrimary()
    local data, common = context()
    return common.Queue("获取主要目标", function()
        local target = common.ReadStatInt("MPX_H4CNF_TARGET") or 0
        if target == 0 or target == 1 or target == 3 or target == 5 then
            ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.TargetGet1, 5)
            ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.TargetGet2, 3)
        elseif target == 2 or target == 4 then
            ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.TargetGet3, 7)
        end
    end)
end

local function hosted_action(label, callback)
    local data, common = context()
    return common.Queue(label, function()
        common.WithMissionHost(data.Config, callback)
    end)
end

function Perico.ClearSecondary()
    local data = App.Data.Perico
    return hosted_action("清除次要目标价值", function()
        ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.ClearSecondary, 0)
    end)
end

function Perico.Finish()
    local data = App.Data.Perico
    return hosted_action("一键完成佩里科岛", function()
        ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.QuickFinish1, 9)
        ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.QuickFinish2, 50)
    end)
end

function Perico.RemoveNpcCut()
    local data, common = context()
    return hosted_action("移除 NPC 分红", function()
        local pavel = ScriptGlobal.GetTunableByHash(data.Config.Tunables.PavelCut)
        local fencing = ScriptGlobal.GetTunableByHash(data.Config.Tunables.FencingFee)
        if pavel ~= 0 then Memory.WriteFloat(pavel, 0.0) end
        if fencing ~= 0 then Memory.WriteFloat(fencing, 0.0) end
        common.Toast("移除分红成功")
    end)
end

function Perico.InfiniteLives()
    local data, common = context()
    return hosted_action("无限生命数", function()
        ScriptLocal.SetInt(data.Config.Scripts.NewHeist, data.Config.Locals.InfiniteLives, 10000)
        common.Toast("已开启佩里科岛无限生命数")
    end)
end

function Perico.InfiniteBag()
    local data, common = context()
    return hosted_action("无限背包", function()
        local address = ScriptGlobal.GetTunableByHash(data.Config.Tunables.BagCapacity)
        if address ~= 0 then Memory.WriteInt(address, 99999) end
        common.Toast("背包容量已设置")
    end)
end

function Perico.TeleportKeycard()
    local data, common = context()
    return common.Queue("传送到门禁卡", function()
        common.TeleportToBlip(data.Config, 763)
    end)
end

function Perico.TeleportKey()
    local data, common = context()
    return common.Queue("传送到钥匙", function()
        common.TeleportToBlip(data.Config, 134)
    end)
end

function Perico.SetAutoLootEnabled(enabled)
    local data, common = context()
    enabled = enabled == true

    if data.State.AutoLootEnabled == enabled then
        return true
    end

    data.State.AutoLootEnabled = enabled
    Perico.AutoLootGeneration = Perico.AutoLootGeneration + 1

    if not enabled then
        Perico.AutoLootLoopHandle = nil
        common.Toast("佩里科岛自动拾取已关闭")
        return true
    end

    local generation = Perico.AutoLootGeneration
    local ok, handle = pcall(Script.RegisterLooped, function()
        if not data.State.AutoLootEnabled
            or generation ~= Perico.AutoLootGeneration
        then
            return false
        end

        local loot_state = ScriptLocal.GetInt(
            data.Config.Scripts.NewHeist,
            data.Config.Locals.LootState
        )
        if loot_state == 5 then
            data.State.AutoLootEnabled = false
            Perico.AutoLootGeneration = Perico.AutoLootGeneration + 1
            Perico.AutoLootLoopHandle = nil
            common.Toast("佩里科岛自动拾取已完成，循环已关闭")
            return false
        end

        ScriptLocal.SetInt(
            data.Config.Scripts.NewHeist,
            data.Config.Locals.LootState,
            4
        )
        ScriptLocal.SetFloat(
            data.Config.Scripts.NewHeist,
            data.Config.Locals.LootSpeed,
            2.0
        )
        Script.Yield(100)
        return true
    end)

    if not ok or not handle then
        data.State.AutoLootEnabled = false
        Perico.AutoLootGeneration = Perico.AutoLootGeneration + 1
        Perico.AutoLootLoopHandle = nil
        common.Toast("无法创建佩里科岛自动拾取循环")
        return false
    end

    Perico.AutoLootLoopHandle = handle
    common.Toast("佩里科岛自动拾取已启用")
    return true
end

function Perico.UnlockDualDoor()
    local data, common = context()
    local generation = Perico.DoorTaskGeneration

    return common.Queue("破解佩里科岛双人门禁", function()
        if generation ~= Perico.DoorTaskGeneration then
            return
        end

        local player = tonumber(GTA.GetLocalPlayerId()) or 0
        ScriptLocal.SetInt(
            data.Config.Scripts.NewHeist,
            data.Config.Locals.DualDoorBase
                + player * data.Config.Locals.DualDoorPlayerStride
                + data.Config.Locals.DualDoorPlayerOffset,
            7
        )
        Script.Yield(500)

        if generation ~= Perico.DoorTaskGeneration then
            return
        end

        ScriptLocal.SetInt(
            data.Config.Scripts.NewHeist,
            data.Config.Locals.DualDoorFinal,
            1
        )
        common.Toast("佩里科岛双人门禁已破解")
    end)
end

function Perico.Init(app)
    App = app
    App.Actions.Perico = Perico
    Perico.DoorTaskGeneration = Perico.DoorTaskGeneration + 1
    math.randomseed(os.time())
    return true
end

function Perico.Shutdown(app)
    if app.Data.Perico then
        app.Data.Perico.State.AutoLootEnabled = false
    end
    Perico.AutoLootGeneration = Perico.AutoLootGeneration + 1
    Perico.AutoLootLoopHandle = nil
    Perico.DoorTaskGeneration = Perico.DoorTaskGeneration + 1
    if app.Actions.Perico == Perico then
        app.Actions.Perico = nil
    end
    App = nil
end

return Perico
