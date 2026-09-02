-- Mission Assistant 公共业务能力

local Common = {
    Name = "Actions.Common"
}

local App

function Common.Init(app)
    App = app
    App.Actions.Common = Common
    return true
end

function Common.Toast(message, duration)
    GUI.AddToast(
        "任务助手",
        tostring(message or ""),
        duration or 3000,
        eToastPos.BOTTOM_RIGHT
    )
end

function Common.Queue(label, callback)
    if type(callback) ~= "function" then
        return false
    end

    local queued, result = pcall(
        Script.QueueJob,
        function()
            local ok, err = pcall(callback)
            if not ok then
                Logger.LogError(
                    string.format(
                        "[Mission Action] %s: %s",
                        tostring(label or "操作失败"),
                        tostring(err)
                    )
                )
                Common.Toast(tostring(label or "操作失败") .. ": " .. tostring(err), 5000)
            end
        end
    )

    if not queued then
        Logger.LogError(
            string.format(
                "[Mission Action] 无法提交 %s: %s",
                tostring(label or "任务"),
                tostring(result)
            )
        )
        return false
    end

    return true
end

function Common.GetCharacterSlot()
    local ok, character = Stats.GetInt(Utils.Joaat("MPPLY_LAST_MP_CHAR"))
    if ok and (character == 0 or character == 1) then
        return character
    end
    return nil
end

function Common.StatHash(stat_name)
    stat_name = tostring(stat_name or "")
    if stat_name:sub(1, 4) == "MPX_" then
        local character = Common.GetCharacterSlot()
        if character == nil then
            return nil
        end
        stat_name = "MP" .. tostring(character) .. "_" .. stat_name:sub(5)
    end
    return Utils.Joaat(stat_name)
end

function Common.ReadStatInt(stat_name)
    local hash = Common.StatHash(stat_name)
    if hash == nil then return nil end
    local ok, value = Stats.GetInt(hash)
    return ok and value or nil
end

-- MPX_WEEKLY_BOOST_BS uses a cleared bit to indicate an available first-time boost.
function Common.IsWeeklyBoostAvailable(bit_mask)
    bit_mask = tonumber(bit_mask)
    if bit_mask == nil then return nil end

    local value = Common.ReadStatInt("MPX_WEEKLY_BOOST_BS")
    if type(value) ~= "number" then return nil end
    return (value & math.floor(bit_mask)) == 0
end

function Common.WriteStatInt(stat_name, value)
    local hash = Common.StatHash(stat_name)
    if hash == nil then return false end
    return Stats.SetInt(hash, math.floor(tonumber(value) or 0)) == true
end

function Common.IsScriptRunning(script_hash, thread_count_native)
    return Natives.InvokeInt(thread_count_native, script_hash) > 0
end

function Common.WithMissionHost(config, callback)
    local natives = config.Natives
    local scripts = config.Scripts
    local locals = config.Locals
    local candidates = {
        {Hash = scripts.OldHeist, Check = locals.HostChecks.OldHeist},
        {Hash = scripts.NewHeist, Check = locals.HostChecks.NewHeist},
        {Hash = scripts.MissionV3, Check = locals.HostChecks.MissionV3}
    }

    local selected = nil
    for _, candidate in ipairs(candidates) do
        if Common.IsScriptRunning(
            candidate.Hash,
            natives.GET_RUNNING_SCRIPT_THREAD_COUNT
        ) then
            selected = candidate
            break
        end
    end

    if not selected then
        Common.Toast("获取失败：未检测到运行中的任务脚本线程")
        return false
    end

    GTA.ForceScriptHost(selected.Hash)
    Script.Yield(1500)

    if ScriptLocal.GetInt(selected.Hash, selected.Check) ~= 1 then
        Common.Toast("接管脚本主机失败")
        return false
    end

    Common.Toast("成功接管脚本主机！")
    callback()
    return true
end

function Common.Teleport(config, x, y, z)
    local natives = config.Natives
    local ped = Natives.InvokeInt(natives.PLAYER_PED_ID)
    if ped == 0 then
        Common.Toast("失败：无法获取玩家")
        return false
    end

    local entity = ped
    if Natives.InvokeBool(natives.IS_PED_IN_ANY_VEHICLE, ped, false) then
        local vehicle = Natives.InvokeInt(
            natives.GET_VEHICLE_PED_IS_IN,
            ped,
            false
        )
        if vehicle ~= 0 then entity = vehicle end
    end

    Natives.InvokeVoid(
        natives.SET_ENTITY_COORDS,
        entity,
        x,
        y,
        z,
        false,
        false,
        false,
        false
    )
    Natives.InvokeVoid(
        natives.SET_GAMEPLAY_CAM_RELATIVE_HEADING,
        0.0
    )
    return true
end

function Common.TeleportToBlip(config, sprite)
    local natives = config.Natives
    local blip = Natives.InvokeInt(natives.GET_FIRST_BLIP_INFO_ID, sprite)
    if blip == 0 then
        Common.Toast("失败：未检测到对应地图图标")
        return false
    end

    local entity = Natives.InvokeInt(
        natives.GET_BLIP_INFO_ID_ENTITY_INDEX,
        blip
    )
    local x, y, z

    if entity ~= 0 and Natives.InvokeBool(natives.DOES_ENTITY_EXIST, entity) then
        x, y, z = Natives.InvokeV3(natives.GET_ENTITY_COORDS, entity, false)
    else
        x, y, z = Natives.InvokeV3(natives.GET_BLIP_COORDS, blip)
    end

    if not x then
        Common.Toast("失败：无法获取图标坐标")
        return false
    end

    if not Common.Teleport(config, x, y, z + 0.5) then
        return false
    end
    Common.Toast(entity ~= 0 and "已传送到目标实体" or "已传送到图标位置")
    return true
end

function Common.Shutdown(app)
    if app.Actions.Common == Common then
        app.Actions.Common = nil
    end
    App = nil
end

return Common
