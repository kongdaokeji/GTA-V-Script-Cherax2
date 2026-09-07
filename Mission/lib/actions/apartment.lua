-- Mission Assistant 公寓抢劫业务操作

local Apartment = {
    Name = "Actions.Apartment"
}

local App

local function context()
    return App.Data.Apartment, App.Actions.Common
end

local function write_stat_bool(common, name, value)
    local hash = common.StatHash(name)
    return hash ~= nil and Stats.SetBool(hash, value == true) == true
end

local function write_stat_string(data, common, name, value)
    local hash = common.StatHash(name)
    if hash == nil then return false end
    return Natives.InvokeBool(
        data.Config.Natives.STAT_SET_STRING,
        hash,
        tostring(value or ""),
        true
    ) == true
end

local function current_heist_id(data, common)
    local prefixes = {"MP0_", "MP1_", ""}
    for _, prefix in ipairs(prefixes) do
        local hash = Utils.Joaat(prefix .. "HEIST_MISSION_RCONT_ID_1")
        local value = Natives.InvokeString(data.Config.Natives.STAT_GET_STRING, hash, -1)
        if value and value ~= "" and value ~= "STAT_UNKNOWN" and value ~= "." then
            return value
        end
    end
    return "空"
end

function Apartment.ApplySetup()
    local data, common = context()
    return common.Queue("开启公寓抢劫终章", function()
        local name = data.Lists.Heists[data.State.HeistIndex + 1]
        local heist = data.Config.Heists[name]
        local character = common.GetCharacterSlot()
        local player = GTA.GetLocalPlayerId()
        if not heist or character == nil then
            common.Toast("无法获取任务配置或角色槽")
            return
        end

        local g = data.Config.Globals
        local apartment_global = g.PlayerApartmentBase
            + player * g.PlayerApartmentStride
            + g.PlayerApartmentOffset
        local apartment_id = ScriptGlobal.GetInt(apartment_global)
        local base_stats = {
            {"MPX_HEIST_PLANNING_STAGE", -1},
            {"MPX_BITSET_HEIST_VS_MISSIONS", -17809409},
            {"MPX_HEIST_SESSION_ID_MACADDR", 183381814},
            {"MPX_HEIST_LEADER_APART_ID", apartment_id},
            {"MPPLY_HEIST_PROGRESS_HASH", heist.ProgressHash},
            {"MPX_HEIST_TOTAL_REWARD_COSMETIC", heist.RewardCosmetic}
        }
        for _, entry in ipairs(base_stats) do
            if not common.WriteStatInt(entry[1], entry[2]) then
                common.Toast("Stat 写入失败：" .. entry[1])
                return
            end
        end

        for index = 0, 7 do
            local rcont = heist.RcontIds[index + 1]
            local stat_name = "MP" .. character .. "_HEIST_MISSION_RCONT_ID_" .. index
            local ok
            if rcont == nil then
                ok = write_stat_string(data, common, stat_name, "")
            elseif type(rcont) == "string" then
                ok = write_stat_string(data, common, stat_name, rcont)
            else
                ok = Stats.SetInt(Utils.Joaat(stat_name), rcont)
            end
            if not ok then
                common.Toast("任务内容 Stat 写入失败：" .. stat_name)
                return
            end
            Stats.SetInt(
                Utils.Joaat("MP" .. character .. "_HEIST_MISSION_DEPTH_LV_" .. index),
                heist.DepthLevels[index + 1] or -1
            )
        end

        ScriptGlobal.SetString(g.RootContentId1, heist.RootContentId)
        ScriptGlobal.SetInt(g.RootContentHash, Utils.Joaat(heist.RootContentId))
        ScriptGlobal.SetString(g.RootContentId2, heist.RootContentId)
        ScriptGlobal.SetInt(g.PlayerStateBase + player * g.PlayerStateStride + g.PlayerStateOffset, 1)
        ScriptGlobal.SetInt(g.ContentState, 0)
        ScriptGlobal.SetInt(g.ContentLaunch, 0)
        if not common.Yield(1000) then return end
        ScriptGlobal.SetInt(g.ContentLaunch, 5)
        ScriptGlobal.SetInt(g.BoardState, 10)
        common.Toast("已完成并刷新策划板")
    end)
end

function Apartment.ForceReady()
    local data, common = context()
    return common.Queue("公寓抢劫强制准备", function()
        for _, global in ipairs(data.Config.Globals.ForceReady) do
            ScriptGlobal.SetInt(global, 6)
        end
        common.Toast("所有玩家已强制准备就绪 (公寓抢劫)")
    end)
end

function Apartment.SkipPreps()
    local _, common = context()
    return common.Queue("跳过公寓前置", function()
        common.WriteStatInt("MPX_HEIST_PLANNING_STAGE", -1)
        common.Toast("公寓前置已跳过")
    end)
end

function Apartment.ApplyPayouts()
    local data, common = context()
    return common.Queue("应用公寓分红", function()
        local payouts = data.State.Payouts
        local first = 100 - (payouts[1] + payouts[2] + payouts[3] + payouts[4])
        local g = data.Config.Globals
        ScriptGlobal.SetInt(g.Payout1 + 1, first)
        for index = 2, 4 do
            ScriptGlobal.SetInt(g.Payout1 + index, payouts[index])
        end
        if not common.Yield(1000) then return end
        local second_first = -1 * (first + payouts[2] + payouts[3] + payouts[4] - 100)
        ScriptGlobal.SetInt(g.Payout2, second_first)
        for index = 2, 4 do
            ScriptGlobal.SetInt(g.Payout2 + index - 1, payouts[index])
        end
        common.Toast(string.format(
            "分红已应用：%d / %d / %d / %d",
            payouts[1], payouts[2], payouts[3], payouts[4]
        ))
    end)
end

function Apartment.AutoPayout()
    local data, common = context()
    return common.Queue("公寓自动分红", function()
        local id = current_heist_id(data, common)
        local mission = data.Config.HeistNamesById[id]
        local difficulty = ScriptGlobal.GetInt(data.Config.Globals.Difficulty)
        local values = data.Config.PayoutValues[difficulty]
        local payout = values and values[mission]
        if not payout then
            common.Toast("你当前不在公寓任务中，或未检测到有效任务")
            return
        end
        local weekly_first = common.IsWeeklyBoostAvailable(
            data.Config.WeeklyBoostBits[mission]
        )
        if weekly_first == nil then
            common.Toast("无法读取公寓每周首次状态")
            return
        end
        if weekly_first then
            payout = math.floor(payout / data.Config.WeeklyMultiplier + 0.5)
        end
        local first = 100 - payout * 4
        local g = data.Config.Globals
        ScriptGlobal.SetInt(g.Payout1 + 1, first)
        for index = 2, 4 do ScriptGlobal.SetInt(g.Payout1 + index, payout) end
        if not common.Yield(1000) then return end
        ScriptGlobal.SetInt(g.Payout2, -1 * (first + payout * 3 - 100))
        for index = 1, 3 do ScriptGlobal.SetInt(g.Payout2 + index, payout) end
        common.Toast(string.format(
            "已设置 %s 分红：%d（每周首次：%s）",
            mission,
            payout,
            weekly_first and "可用" or "已使用"
        ))
    end)
end

function Apartment.TeleportSelected()
    local data, common = context()
    return common.Queue("公寓传送", function()
        local name = data.Lists.Teleports[data.State.TeleportIndex + 1]
        local coords = data.Config.TeleportCoords[name]
        if coords and common.Teleport(data.Config, coords[1], coords[2], coords[3]) then
            common.Toast("已传送至：" .. name)
        end
    end)
end

function Apartment.SkipSnake()
    local data, common = context()
    return common.Queue("跳过贪吃蛇", function()
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.SkipSnake, 7)
    end)
end

function Apartment.SkipDrill()
    local data, common = context()
    return common.Queue("跳过钻孔", function()
        ScriptLocal.SetFloat(data.Config.Scripts.OldHeist, data.Config.Locals.SkipDrill, 100.0)
    end)
end

function Apartment.SkipPacificHack()
    local data, common = context()
    return common.Queue("跳过太平洋破解", function()
        local value = ScriptLocal.GetInt(data.Config.Scripts.OldHeist, data.Config.Locals.HackPacific)
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.HackPacific, (value or 0) | 512)
    end)
end

function Apartment.UnlockBoard()
    local _, common = context()
    return common.Queue("解锁公寓计划板", function()
        for _, stat in ipairs({
            "MPPLY_AWD_FLEECA_FIN", "MPPLY_AWD_PRISON_FIN", "MPPLY_AWD_HUMANE_FIN",
            "MPPLY_AWD_SERIESA_FIN", "MPPLY_AWD_PACIFIC_FIN"
        }) do
            write_stat_bool(common, stat, true)
        end
        common.Toast("已解锁公寓计划板")
    end)
end

local function write_timers(data)
    for player = 0, 3 do
        ScriptLocal.SetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.TimerPlayers
                + player * data.Config.Locals.PlayerStride
                + data.Config.Locals.PlayerTimerOffset,
            99999
        )
    end
end

local function pacific_amount(data, common)
    local difficulty = ScriptGlobal.GetInt(data.Config.Globals.Difficulty)
    local amount = data.Config.PacificAmounts[difficulty] or data.Config.PacificAmounts[1]
    local weekly_first = common.IsWeeklyBoostAvailable(
        data.Config.WeeklyBoostBits["太平洋标准银行"]
    )
    if weekly_first == nil then
        common.Toast("无法读取太平洋标准银行每周首次状态")
        return nil
    end
    return weekly_first
        and math.floor(amount * data.Config.WeeklyMultiplier + 0.5)
        or amount
end

local function settle_pacific(data, common)
    local amount = pacific_amount(data, common)
    if amount == nil then return false end
    ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.State1, 5)
    ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.CutPercent, 80)
    ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.TargetAmount, amount)
    ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.Timer1, 99999)
    write_timers(data)
    return true
end

local function wait_for_cutscene(data, delay_after, callback, common)
    local checkpoint = ScriptLocal.GetInt(data.Config.Scripts.OldHeist, data.Config.Locals.HeistState) or 0
    for attempt = 1, 20 do
        ScriptLocal.SetInt(
            data.Config.Scripts.OldHeist,
            data.Config.Locals.HeistState,
            checkpoint | 131072
        )
        if not common.Yield(2000) then return false end
        if Natives.InvokeBool(data.Config.Natives.IS_CUTSCENE_PLAYING) then
            if not common.Yield(delay_after) then return false end
            callback()
            return true
        end
    end
    common.Toast("等待过场动画超时，请重试")
    return false
end

function Apartment.Finish()
    local data, common = context()
    return common.Queue("一键完成公寓抢劫", function()
        local id = current_heist_id(data, common)
        common.WithMissionHost(data.Config, function()
            if id == data.Config.PacificId then
                wait_for_cutscene(data, 5000, function() settle_pacific(data, common) end, common)
            else
                ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.QuickFinishBase, 12)
                ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.CutPercent, 80)
                ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.Timer1, 99999)
                write_timers(data)
            end
        end)
    end)
end

function Apartment.InfiniteLives()
    local data, common = context()
    return common.Queue("公寓无限生命数", function()
        common.WithMissionHost(data.Config, function()
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.InfiniteLives, 10000)
            common.Toast("已开启公寓无限生命数")
        end)
    end)
end

function Apartment.CriminalMastermind()
    local data, common = context()
    return common.Queue("公寓犯罪之神", function()
        if current_heist_id(data, common) ~= data.Config.PacificId then
            common.Toast("请在太平洋标准银行差事里点击犯罪之神")
            return
        end
        common.WithMissionHost(data.Config, function()
            wait_for_cutscene(data, 5000, function()
                for _, stat in ipairs({
                    "MPPLY_HEISTFLOWORDERPROGRESS",
                    "MPPLY_HEISTTEAMPROGRESSBITSET",
                    "MPPLY_HEISTNODEATHPROGREITSET"
                }) do
                    common.WriteStatInt(stat, 268435455)
                end
                for _, stat in ipairs({
                    "MPPLY_AWD_HST_ORDER",
                    "MPPLY_AWD_HST_SAME_TEAM",
                    "MPPLY_AWD_HST_ULT_CHAL"
                }) do
                    write_stat_bool(common, stat, false)
                end
                if not common.Yield(1000) then return end
                settle_pacific(data, common)
            end, common)
        end)
    end)
end

function Apartment.Init(app)
    App = app
    App.Actions.Apartment = Apartment
    return true
end

function Apartment.Shutdown(app)
    if app.Actions.Apartment == Apartment then app.Actions.Apartment = nil end
    App = nil
end

return Apartment
