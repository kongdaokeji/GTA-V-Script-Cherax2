-- Mission Assistant 科兹中心数据与状态

local KortzData = {Name = "Data.Kortz"}

function KortzData.Init(App)
    local lists = {
        Targets = {
            "最后的放纵", "兔个清静", "罗马的衰落", "兄弟", "百态丛生", "化为乌有", "真爱",
            "窒息", "康祀没托", "洋洋盈耳", "千里冰封", "戴珍珠项链的女孩", "瓜田喵下",
            "南瓜", "异同", "潜精研思", "水果", "欲欲丛丛", "功到自然成", "榨干",
            "蜿蜒家道", "腊肠犬", "信任", "至死不渝", "顶瓜瓜", "巧取豪夺", "短兵相见"
        },
        Difficulties = {"普通模式", "困难模式"},
        Entries = {"员工入口", "天窗", "卸货区", "下水道"},
        Loadouts = {"街头装备", "保安装备", "军用装备"},
        Getaways = {"装甲卡拉卡拉", "歼灭者隐形版", "曼切兹"},
        ManchezColors = {"红色", "蓝色", "绿色", "黄色"},
        Teleports = {
            "里奇曼别墅", "通瓦山别墅", "好麦坞别墅", "员工入口", "天窗", "下水道", "卸货区",
            "电梯口", "楼梯口", "展览室一层", "展览室二楼", "画廊", "地下室", "电脑处",
            "安检门", "金库门外面", "金库门里面"
        }
    }

    local config = {
        Natives = {
            PLAYER_PED_ID = 0xD80958FC74E988A6,
            IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
            GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
            SET_ENTITY_COORDS = 0x06843DA7060A026B,
            SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
            GET_RUNNING_SCRIPT_THREAD_COUNT = 0x2C83A9DA6BFFC4F9
        },
        Scripts = {
            Planning = Utils.Joaat("kortz_planning"),
            Finale = Utils.Joaat("fm_mission_controller_v3")
        },
        Stats = {
            General = "MPX_K26_GENERAL_BS",
            General2 = "MPX_K26_GENERAL_BS2",
            Robbery = "MPX_K26_ROBBERY_PROG",
            Target = "MPX_K26_HEIST_TARGET",
            Scoping = "MPX_K26_SCOPING_BS",
            Poi = "MPX_K26_POI_BS",
            BuyRequirements = "MPX_K26_BUYREQ_BS"
        },
        Masks = {
            EntryGroup=30, LoadoutGroup=3584, GetawayGroup=1792,
            ManchezGroup=1966080, ManholeKey=134217728,
            HardMode=268435456, WeakGuards=-2147483648
        },
        EntryMasks = {8,16,2,4},
        LoadoutMasks = {512,1024,2048},
        GetawayMasks = {256,512,1024},
        ManchezMasks = {131072,262144,524288,1048576},
        Preps = {
            {Field="GuardRoutes", General=32, Robbery=8192},
            {Field="GlassCutter", General=64, Robbery=16384},
            {Field="PowerDrills", General=128, Robbery=32768},
            {Field="PrepEmp", General=256, Robbery=2048}
        },
        Globals = {
            LaserState = 1935711,
            SecondaryTargetsBase = 4980736 + 1 + 29174,
            SecondaryTargetIndices = {5,6,7,20,21}
        },
        Tunables = {BagCapacity = 6971439},
        Locals = {
            Board=599, Lives=64049+1110, Income=60737+1376+60,
            DataHack=1388, Fingerprint=26866, AccessCode=32818,
            Laser=70416, Vault=27914, Glass=32855, TargetStage=29355+11,
            HostCheck=21133
        },
        TeleportCoords = {
            ["里奇曼别墅"]={-1693.118,493.434,128.812}, ["通瓦山别墅"]={-2553.108,1911.576,168.975},
            ["好麦坞别墅"]={543.005,778.838,202.240}, ["员工入口"]={-2198.147,248.008,174.607},
            ["天窗"]={-2204.702,259.909,198.104}, ["下水道"]={-2303.034,217.091,167.570},
            ["卸货区"]={-2354.727,303.599,169.467}, ["电梯口"]={2598.021,5923.010,-49.000},
            ["楼梯口"]={2599.538,5933.675,-49.000}, ["展览室一层"]={2599.735,5916.188,-48.999},
            ["展览室二楼"]={2606.097,5916.967,-39.000}, ["画廊"]={2607.339,5890.137,-39.000},
            ["地下室"]={2602.881,5931.063,-61.000}, ["电脑处"]={2631.361,5900.035,-61.000},
            ["安检门"]={2631.359,5892.497,-61.000}, ["金库门外面"]={2631.000,5860.893,-60.996},
            ["金库门里面"]={2630.864,5854.975,-61.000}
        }
    }

    App.Data.Kortz = {
        Lists=lists, Config=config,
        State={
            TargetIndex=0, DifficultyIndex=0, EntryIndex=0, LoadoutIndex=0,
            GetawayIndex=0, ManchezColorIndex=0,
            GuardRoutes=true, GlassCutter=true, PowerDrills=true, PrepEmp=true,
            WeakGuards=true, ScopeSecondary=true, ScopePoi=true,
            TeleportIndex=0, SecondaryIncome=0
        }
    }
    return true
end

function KortzData.Shutdown(App)
    App.Data.Kortz = nil
end

return KortzData
