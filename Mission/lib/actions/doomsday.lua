-- Mission Assistant 末日豪劫业务操作

local Doomsday = {
    Name = "Actions.Doomsday"
}

local App

local function context()
    return App.Data.Doomsday, App.Actions.Common
end

function Doomsday.ApplySetup()
    local data, common = context()
    return common.Queue("开启末日豪劫终章", function()
        local setup = data.Config.SetupValues[data.State.SetupIndex + 1]
        if not setup then
            common.Toast("请先选择前置设置")
            return
        end
        local entries = {
            {"MPX_GANGOPS_FLOW_MISSION_PROG", setup.MissionProgress},
            {"MPX_GANGOPS_HEIST_STATUS", setup.HeistStatus},
            {"MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557}
        }
        for _, entry in ipairs(entries) do
            if not common.WriteStatInt(entry[1], entry[2]) then
                common.Toast("Stat 写入失败：" .. entry[1])
                return
            end
        end
        ScriptLocal.SetInt(
            data.Config.Scripts.Planning,
            data.Config.Locals.RefreshBoard,
            6
        )
        common.Toast("已开启：" .. data.Lists.Setups[data.State.SetupIndex + 1] .. " 终章")
    end)
end

function Doomsday.ForceReady()
    local data, common = context()
    return common.Queue("末日豪劫强制准备", function()
        for _, global in ipairs(data.Config.Globals.ForceReady) do
            ScriptGlobal.SetInt(global, 1)
        end
        common.Toast("所有玩家已强制准备就绪 (末日豪劫)")
    end)
end

function Doomsday.RefreshBoard()
    local data, common = context()
    return common.Queue("刷新末日计划板", function()
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.RefreshBoard, 6)
        common.Toast("计划板已刷新")
    end)
end

function Doomsday.Reset()
    local data, common = context()
    return common.Queue("重置末日豪劫", function()
        common.WriteStatInt("MPX_GANGOPS_FLOW_MISSION_PROG", 503)
        common.WriteStatInt("MPX_GANGOPS_HEIST_STATUS", 0)
        common.WriteStatInt("MPX_GANGOPS_FLOW_NOTIFICATIONS", 1557)
        ScriptLocal.SetInt(data.Config.Scripts.Planning, data.Config.Locals.RefreshBoard, 6)
        common.Toast("已重置末日豪劫")
    end)
end

function Doomsday.ApplyPayouts()
    local data, common = context()
    return common.Queue("应用末日豪劫分红", function()
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

function Doomsday.AutoPayout()
    local data, common = context()
    return common.Queue("末日豪劫自动分红", function()
        local progress = common.ReadStatInt("MPX_GANGOPS_FLOW_MISSION_PROG")
        local mission = data.Config.MissionByProgress[progress]
        local difficulty = ScriptGlobal.GetInt(data.Config.Globals.Difficulty)
        local values = data.Config.PayoutValues[difficulty]
        local payout = values and values[mission]
        if not payout then
            common.Toast("无法识别当前末日任务或难度")
            return
        end
        local weekly_first = common.IsWeeklyBoostAvailable(
            data.Config.WeeklyBoostBits[mission]
        )
        if weekly_first == nil then
            common.Toast("无法读取末日每周首次状态")
            return
        end
        if weekly_first then
            payout = math.floor(payout / data.Config.WeeklyMultiplier + 0.5)
        end
        for index = 1, 4 do
            ScriptGlobal.SetInt(data.Config.Globals.Payout + index, payout)
        end
        common.Toast(string.format(
            "已设置%s分红：%d（每周首次：%s）",
            mission,
            payout,
            weekly_first and "可用" or "已使用"
        ))
    end)
end

local function property_blip(data)
    local n = data.Config.Natives
    local blip = Natives.InvokeInt(n.GET_FIRST_BLIP_INFO_ID, data.Config.FacilityBlip)
    local best = 0
    while blip ~= 0 do
        local color = Natives.InvokeInt(n.GET_BLIP_COLOUR, blip)
        if color ~= 69 and color ~= 3 and color ~= 93 then
            if color == 0 or color == 4 then return blip end
            if best == 0 then best = blip end
        end
        blip = Natives.InvokeInt(n.GET_NEXT_BLIP_INFO_ID, data.Config.FacilityBlip)
    end
    return best
end

function Doomsday.TeleportSelected()
    local data, common = context()
    return common.Queue("末日豪劫传送", function()
        local name = data.Lists.Teleports[data.State.TeleportIndex + 1]
        if name == "设施" then
            local blip = property_blip(data)
            if blip == 0 then
                common.Toast("未检测到 [设施] 的有效图标")
                return
            end
            local x, y, z = Natives.InvokeV3(data.Config.Natives.GET_BLIP_COORDS, blip)
            if x and common.Teleport(data.Config, x, y, z) then
                common.Toast("已传送到：设施")
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

function Doomsday.SkipTerminal()
    local data, common = context()
    return common.Queue("跳过终端解密", function()
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.SkipHack1, 2)
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.SkipHack2, 3)
        ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.SkipHack3, 3)
        common.Toast("已跳过终端解密")
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

function Doomsday.Finish()
    local data, common = context()
    return common.Queue("一键完成末日豪劫", function()
        common.WithMissionHost(data.Config, function()
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.QuickFinishBase, 12)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.CutPercent, 80)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.Timer1, 99999)
            write_timers(data)
        end)
    end)
end

function Doomsday.FinishActThree()
    local data, common = context()
    return common.Queue("一键完成末日将至", function()
        common.WithMissionHost(data.Config, function()
            local checkpoint = ScriptLocal.GetInt(
                data.Config.Scripts.OldHeist,
                data.Config.Locals.HeistState
            ) or 0
            ScriptLocal.SetInt(
                data.Config.Scripts.OldHeist,
                data.Config.Locals.HeistState,
                checkpoint | 131328
            )
            Script.Yield(2000)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.QuickFinishBase, 12)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.CutPercent, 150)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.Timer1, 99999)
            write_timers(data)
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.State2, 80)
        end)
    end)
end

function Doomsday.InfiniteLives()
    local data, common = context()
    return common.Queue("末日豪劫无限生命数", function()
        common.WithMissionHost(data.Config, function()
            ScriptLocal.SetInt(data.Config.Scripts.OldHeist, data.Config.Locals.InfiniteLives, 10000)
            common.Toast("已开启末日无限生命数")
        end)
    end)
end

function Doomsday.Init(app)
    App = app
    App.Actions.Doomsday = Doomsday
    return true
end

function Doomsday.Shutdown(app)
    if app.Actions.Doomsday == Doomsday then
        app.Actions.Doomsday = nil
    end
    App = nil
end

return Doomsday
