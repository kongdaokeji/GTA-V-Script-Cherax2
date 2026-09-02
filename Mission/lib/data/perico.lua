-- Mission Assistant 佩里科岛数据与运行状态

local PericoData = {
    Name = "Data.Perico"
}

local function filled(count, value)
    local result = {}
    for index = 1, count do result[index] = value end
    return result
end

function PericoData.Init(App)
    local lists = {
        Difficulties = {"普通", "困难"},
        Targets = {"西西米托", "红宝石项链", "不记名债券", "粉钻", "马德拉索文件", "猎豹雕像"},
        Weapons = {"侵略者", "阴谋者", "神枪手", "破坏者", "神射手"},
        Materials = {"随机", "无", "现金", "大麻", "可卡因", "黄金"},
        Paintings = {"空", "满", "1", "2", "3", "4", "5", "6"},
        CompoundLocations = {
            "豪宅桌位 1", "豪宅桌位 2", "豪宅桌位 3", "豪宅桌位 4",
            "豪宅桌位 5", "豪宅桌位 6", "豪宅桌位 7", "豪宅桌位 8"
        },
        IslandLocations = {
            "机场1 (机库下层) 桌A", "机场1 (机库下层) 桌B",
            "机场2 (机库上层) 桌A", "机场2 (机库上层) 桌B",
            "机场3 (北侧库房) 桌A", "机场3 (北侧库房) 桌B",
            "北码头1 (西侧库房) 桌A", "北码头1 (西侧库房) 桌B",
            "北码头2 (南侧库房) 桌A", "北码头2 (南侧库房) 桌B",
            "北码头3 (东侧库房) 桌A", "北码头3 (东侧库房) 桌B",
            "北码头3 (东侧库房) 桌C", "农田 (中心库房) 桌A",
            "农田 (中心库房) 桌B", "主码头1 (北侧库房) 桌A",
            "主码头1 (北侧库房) 桌B", "主码头2 (西侧库房) 桌A",
            "主码头2 (西侧库房) 桌B", "主码头2 (西侧库房) 桌C",
            "主码头3 (南侧库房近) 桌A", "主码头3 (南侧库房近) 桌B",
            "主码头4 (最南库房远) 桌A", "主码头4 (最南库房远) 桌B"
        },
        Teleports = {
            "虎鲸", "排水管道(入口)", "排水管道(出口)", "主要目标(地下室)", "办公室",
            "豪宅出口(里面)", "豪宅入口(外面)", "海里", "机场1", "机场2", "机场3",
            "农田", "主码头1", "主码头2", "主码头3", "主码头4", "北码头1",
            "北码头2", "北码头3"
        }
    }

    local config = {
        Natives = {
            PLAYER_PED_ID = 0xD80958FC74E988A6,
            IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
            GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
            SET_ENTITY_COORDS = 0x06843DA7060A026B,
            SET_ENTITY_HEADING = 0x8E2530AA8ADA980E,
            SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
            GET_FIRST_BLIP_INFO_ID = 0x1BEDE233E6CD2A1F,
            GET_BLIP_INFO_ID_ENTITY_INDEX = 0x4BA4E2553AFEDC2C,
            GET_BLIP_COORDS = 0x586AFE3FF72D996E,
            DOES_ENTITY_EXIST = 0x7239B21A38F536BA,
            GET_ENTITY_COORDS = 0x3FEF770D40960D5A,
            GET_RUNNING_SCRIPT_THREAD_COUNT = 0x2C83A9DA6BFFC4F9
        },
        Scripts = {
            OldHeist = Utils.Joaat("fm_mission_controller"),
            NewHeist = Utils.Joaat("fm_mission_controller_2020"),
            MissionV3 = Utils.Joaat("fm_mission_controller_v3"),
            Planning = Utils.Joaat("heist_island_planning")
        },
        Globals = {
            Payout = 1980570 + 831 + 56,
            KosatkaRequest = 2733326 + 613,
            ForceReady = {
                1981683 + 1 + (0 * 27) + 7 + 1,
                1981683 + 1 + (1 * 27) + 7 + 2,
                1981683 + 1 + (2 * 27) + 7 + 3,
                1981683 + 1 + (3 * 27) + 7 + 4
            }
        },
        Tunables = {
            PavelCut = Utils.Joaat("IH_DEDUCTION_PAVEL_CUT"),
            FencingFee = Utils.Joaat("IH_DEDUCTION_FENCING_FEE"),
            BagCapacity = Utils.Joaat("HEIST_BAG_MAX_CAPACITY")
        },
        Locals = {
            PlanApply = 1580,
            QuickFinish1 = 56504,
            QuickFinish2 = 56504 + 1776 + 1,
            CutDrainage = 31511,
            Fingerprint = 26619,
            CutGlass = 32751 + 3,
            TargetGet1 = 32750,
            TargetGet2 = 32751,
            TargetGet3 = 32725,
            ClearSecondary = 59986 + 1376 + 60,
            InfiniteLives = 63285 + 1109 + 1,
            LootState = 31275,
            LootSpeed = 31275 + 14,
            DualDoorBase = 69374 + 1,
            DualDoorPlayerStride = 293,
            DualDoorPlayerOffset = 236,
            DualDoorFinal = 21215,
            HostChecks = {
                ["OldHeist"] = 3290,
                ["NewHeist"] = 21077,
                ["MissionV3"] = 21133
            }
        },
        MaterialValues = {"RANDOM", "NONE", "CASH", "WEED", "COKE", "GOLD"},
        PaintingValues = {0, 127, 64, 96, 112, 120, 122, 126},
        DifficultyValues = {126823, 131055},
        TargetValues = {0, 1, 2, 3, 4, 5},
        WeaponValues = {1, 2, 3, 4, 5},
        PayoutValues = {
            [126823] = {[0]=723, [1]=516, [2]=470, [3]=317, [4]=263, [5]=152},
            [131055] = {[0]=658, [1]=470, [2]=427, [3]=289, [4]=239, [5]=138}
        },
        TargetNames = {
            [0]="西西米托", [1]="红宝石项链", [2]="不记名债券",
            [3]="粉钻", [4]="马德拉索文件", [5]="猎豹雕像"
        },
        TeleportCoords = {
            ["排水管道(入口)"] = {5044.62, -5815.75, -12.3},
            ["排水管道(出口)"] = {5053.77, -5773.22, -5.4},
            ["主要目标(地下室)"] = {5006.7, -5756.2, 14.8},
            ["办公室"] = {5010.12, -5750.13, 28.84},
            ["豪宅出口(里面)"] = {4990.038, -5717.689, 19.880},
            ["豪宅入口(外面)"] = {4974.189, -5703.279, 19.898},
            ["海里"] = {4771.479, -6165.737, -39.079613},
            ["机场1"] = {4503.587402, -4555.740723, 2.854459},
            ["机场2"] = {4437.821777, -4447.841309, 3.028436},
            ["机场3"] = {4447.091797, -4442.184082, 5.936794},
            ["农田"] = {5330.527, -5269.7515, 33.18603},
            ["主码头1"] = {5193.909668, -5135.642578, 2.045917},
            ["主码头2"] = {4963.184570, -5108.933105, 1.670808},
            ["主码头3"] = {4998.709473, -5165.559570, 1.464137},
            ["主码头4"] = {4924.693359, -5243.244629, 1.223599},
            ["北码头1"] = {5132.558594, -4612.922852, 1.162808},
            ["北码头2"] = {5065.255371, -4591.706543, 1.555012},
            ["北码头3"] = {5090.916016, -4682.670898, 1.107098}
        },
        Kosatka = {
            RequestBlip = 760,
            InteriorBlip = 774,
            Position = {1561.2369, 385.8771, -50.689915},
            Heading = 175.0
        }
    }

    App.Data.Perico = {
        Lists = lists,
        Config = config,
        State = {
            DifficultyIndex = 0,
            TargetIndex = 0,
            WeaponIndex = 0,
            PaintingIndex = 1,
            CompoundLocationIndex = 0,
            CompoundTargets = filled(#lists.CompoundLocations, 5),
            CompoundRandomFill = false,
            IslandLocationIndex = 0,
            IslandTargets = filled(#lists.IslandLocations, 5),
            IslandRandomFill = false,
            AutoLootEnabled = false,
            Payouts = {0, 0, 0, 0},
            TeleportIndex = 0
        }
    }

    return true
end

function PericoData.Shutdown(App)
    App.Data.Perico = nil
end

return PericoData
