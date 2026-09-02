-- Mission Assistant 任务载具数据

local VehiclesData={Name="Data.Vehicles"}

function VehiclesData.Init(App)
    App.Data.Vehicles={
        Presets={
            {Id="Toreador",Label="图拉尔多",Model="toreador"},
            {Id="Deluxo",Label="德罗索",Model="deluxo"},
            {Id="Kuruma",Label="骷髅马",Model="kuruma2"},
            {Id="OppressorMk2",Label="马克兔",Model="oppressor2"},
            {Id="Polmav",Label="小蛮牛",Model="polmav"}
        },
        Globals={EnterPersonalVehicle=2640101+8},
        Natives={
            PLAYER_PED_ID=0xD80958FC74E988A6,
            IS_PED_IN_ANY_VEHICLE=0x997ABD671D25CA0B,
            GET_VEHICLE_PED_IS_IN=0x9A9112A0FE9A4713,
            NETWORK_HAS_CONTROL_OF_ENTITY=0x01BF60A500E28887,
            NETWORK_REQUEST_CONTROL_OF_ENTITY=0xB69317BF5E782347,
            SET_VEHICLE_FIXED=0x115722B1B9C14C1C,
            SET_VEHICLE_DEFORMATION_FIXED=0x953DA1E1B12C0491,
            SET_VEHICLE_DIRT_LEVEL=0x79D3B596FE44EE8B,
            SET_VEHICLE_ENGINE_HEALTH=0x45F6D8EEF34ABEF1,
            SET_VEHICLE_PETROL_TANK_HEALTH=0x70DB57649FA8D0D8,
            SET_VEHICLE_MOD_KIT=0x1F2AA07F00B3217A,
            GET_NUM_VEHICLE_MODS=0xE38E9162A2500646,
            SET_VEHICLE_MOD=0x6AF0636DDEDCB6DD,
            TOGGLE_VEHICLE_MOD=0x2A1F4F37F95BAD08,
            SET_VEHICLE_ON_GROUND_PROPERLY=0x49733E92263139D1,
            SET_PED_INTO_VEHICLE=0xF75B0D629E1C063D
        },
        Busy=false
    }
    return true
end

function VehiclesData.Shutdown(App)App.Data.Vehicles=nil end
return VehiclesData
