-- Mission Assistant 任务载具业务操作

local Vehicles={Name="Actions.Vehicles"}
local App
local function context()return App.Data.Vehicles,App.Actions.Common end

local function maximize(data,vehicle)
    local n=data.Natives
    Natives.InvokeVoid(n.SET_VEHICLE_MOD_KIT,vehicle,0)
    for slot=0,49 do
        local count=Natives.InvokeInt(n.GET_NUM_VEHICLE_MODS,vehicle,slot)
        if count>0 then Natives.InvokeVoid(n.SET_VEHICLE_MOD,vehicle,slot,count-1,false)end
    end
    for slot=17,22 do Natives.InvokeVoid(n.TOGGLE_VEHICLE_MOD,vehicle,slot,true)end
end

function Vehicles.SpawnPreset(index)
    local data,common=context();local preset=data.Presets[index]
    if not preset then return false end
    if data.Busy then common.Toast("正在处理上一项载具操作");return false end
    data.Busy=true
    local queued=common.Queue("生成任务载具",function()
        local ok,err=pcall(function()
            local vehicle=GTA.SpawnVehicleForPlayer(preset.Model,GTA.GetLocalPlayerId(),5.0)
            if type(vehicle)~="number" or vehicle<=0 then error("创建载具失败")end
            maximize(data,vehicle)
            Natives.InvokeVoid(data.Natives.SET_VEHICLE_ON_GROUND_PROPERLY,vehicle,5.0)
            local ped=Natives.InvokeInt(data.Natives.PLAYER_PED_ID)
            if ped~=0 then Natives.InvokeVoid(data.Natives.SET_PED_INTO_VEHICLE,ped,vehicle,-1)end
            common.Toast(preset.Label.."已生成")
        end)
        data.Busy=false
        if not ok then error(err)end
    end)
    if not queued then data.Busy=false end
    return queued
end

local function request_control(data,vehicle,common)
    local n=data.Natives
    for _=1,30 do
        if Natives.InvokeBool(n.NETWORK_HAS_CONTROL_OF_ENTITY,vehicle)then return true end
        Natives.InvokeBool(n.NETWORK_REQUEST_CONTROL_OF_ENTITY,vehicle)
        if not common.Yield(10) then return nil end
    end
    return Natives.InvokeBool(n.NETWORK_HAS_CONTROL_OF_ENTITY,vehicle)
end

function Vehicles.Repair()
    local data,common=context()
    if data.Busy then common.Toast("正在处理上一项载具操作");return false end
    data.Busy=true
    local queued=common.Queue("修复当前载具",function()
        local ok,err=pcall(function()
            local ped=Natives.InvokeInt(data.Natives.PLAYER_PED_ID)
            if not Natives.InvokeBool(data.Natives.IS_PED_IN_ANY_VEHICLE,ped,false)then
                common.Toast("当前不在载具中");return
            end
            local vehicle=Natives.InvokeInt(data.Natives.GET_VEHICLE_PED_IS_IN,ped,false)
            if vehicle==0 then common.Toast("无法获取当前载具");return end
            local controlled=request_control(data,vehicle,common)
            if controlled==nil then return end
            if not controlled then common.Toast("无法取得载具控制权");return end
            local n=data.Natives
            Natives.InvokeVoid(n.SET_VEHICLE_FIXED,vehicle)
            Natives.InvokeVoid(n.SET_VEHICLE_DEFORMATION_FIXED,vehicle)
            Natives.InvokeVoid(n.SET_VEHICLE_DIRT_LEVEL,vehicle,0.0)
            Natives.InvokeVoid(n.SET_VEHICLE_ENGINE_HEALTH,vehicle,1000.0)
            Natives.InvokeVoid(n.SET_VEHICLE_PETROL_TANK_HEALTH,vehicle,1000.0)
            common.Toast("载具已完全修复")
        end)
        data.Busy=false
        if not ok then error(err)end
    end)
    if not queued then data.Busy=false end
    return queued
end

function Vehicles.EnterPersonalVehicle()
    local data,common=context()
    return common.Queue("进入个人载具",function()
        ScriptGlobal.SetInt(data.Globals.EnterPersonalVehicle,1)
        common.Toast("已请求进入个人载具")
    end)
end

function Vehicles.Init(app)App=app;App.Actions.Vehicles=Vehicles;return true end
function Vehicles.Shutdown(app)if app.Actions.Vehicles==Vehicles then app.Actions.Vehicles=nil end;App=nil end
return Vehicles
