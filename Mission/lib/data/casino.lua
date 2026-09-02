-- Mission Assistant 赌场豪劫数据与运行状态

local CasinoData = {
    Name = "Data.Casino"
}

function CasinoData.Init(App)
    local lists = {
        Approaches = {"气势汹汹", "兵不厌诈", "隐匿潜踪"},
        Targets = {"现金", "名画", "黄金", "钻石"},
        Gunmen = {"5级", "7级", "8级", "9级", "10级"},
        WeaponVariants = {"最佳", "最差"},
        Drivers = {"5级", "6级", "7级", "9级", "10级"},
        VehicleVariants = {"最佳", "良好", "中等", "最差"},
        Hackers = {"3级", "5级", "7级", "9级", "10级"},
        Masks = {
            "移除", "几何", "猎人", "鬼半面", "表情", "华丽骷髅", "幸运水果",
            "游击队", "小丑", "动物", "防暴", "鬼", "曲棍球"
        },
        KeyLevels = {"一级", "二级"},
        GuardStrengths = {"全副武装", "削弱"},
        Teleports = {
            "游戏厅", "计划板", "赌场正门", "员工大厅(入口)", "废物处理间(入口)",
            "小金库", "双人门禁刷卡点", "金库外面", "金库里面", "员工大厅(出口)",
            "废物处理间(出口)"
        }
    }

    local config = {
        Natives = {
            PLAYER_PED_ID = 0xD80958FC74E988A6,
            IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
            GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
            SET_ENTITY_COORDS = 0x06843DA7060A026B,
            SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
            GET_FIRST_BLIP_INFO_ID = 0x1BEDE233E6CD2A1F,
            GET_NEXT_BLIP_INFO_ID = 0x14F96AA50D6FBEA7,
            GET_BLIP_COLOUR = 0xDF729E8D20CF7327,
            GET_BLIP_COORDS = 0x586AFE3FF72D996E,
            GET_RUNNING_SCRIPT_THREAD_COUNT = 0x2C83A9DA6BFFC4F9
        },
        Scripts = {
            OldHeist = Utils.Joaat("fm_mission_controller"),
            NewHeist = Utils.Joaat("fm_mission_controller_2020"),
            MissionV3 = Utils.Joaat("fm_mission_controller_v3"),
            Planning = Utils.Joaat("gb_casino_heist_planning")
        },
        Globals = {
            Payout = 1973762 + 1497 + 736 + 92,
            Difficulty = 4718592 + 3771,
            Buyer = 1973762 + 1497 + 1019,
            VaultCountdown = 4718592 + 230289,
            ForceReady = {
                1978125 + 1 + (0 * 68) + 7 + 1,
                1978125 + 1 + (1 * 68) + 7 + 2,
                1978125 + 1 + (2 * 68) + 7 + 3,
                1978125 + 1 + (3 * 68) + 7 + 4
            }
        },
        Locals = {
            State1 = 20412 + 1062,
            QuickFinishBase = 20412,
            CutPercent = 20412 + 1740 + 1,
            TargetAmount = 20412 + 2686,
            Timer1 = 29326 + 1,
            TimerPlayers = 32785 + 1,
            PlayerStride = 294,
            PlayerTimerOffset = 68,
            InfiniteLives = 26838 + 1325 + 1,
            HackKeypad = 55028,
            HackFingerprint = 56098,
            UnlockDoor1 = 32785 + 1,
            UnlockDoor2 = 64655,
            DrillVaultTarget = 10567 + 37,
            DrillVaultSet = 10567 + 7,
            LootState = 10713,
            LootSpeed = 10713 + 14,
            RefreshBoard = 219,
            HostChecks = {
                OldHeist = 3290,
                NewHeist = 21077,
                MissionV3 = 21133
            }
        },
        ApproachStats = {
            [0] = {3, 3, 2},
            [1] = {2, 2, 3},
            [2] = {1, 1, 3}
        },
        TargetValues = {0, 2, 1, 3},
        GunmanValues = {1, 3, 5, 2, 4},
        DriverValues = {1, 4, 2, 3, 5},
        HackerValues = {1, 3, 2, 5, 4},
        WeaponVariantValues = {1, 0},
        VehicleVariantValues = {3, 2, 1, 0},
        KeyLevelValues = {1, 2},
        GuardStrengthValues = {0, 3},
        PayoutValues = {
            [0] = {1480500, 1628550},
            [1] = {1809500, 1990450},
            [2] = {1645000, 1809500},
            [3] = {2303000, 2533300}
        },
        TargetNames = {[0]="现金", [1]="黄金", [2]="名画", [3]="钻石"},
         WeeklyBoostBit = 1 << 8,
         WeeklyMultiplier = 1.86,
        MaxSafeCap = 2533300,
        BuyerLevels = {[0]=0, [3]=1, [6]=2},
        BuyerFees = {[0]=0.10, [1]=0.05, [2]=0.00},
        GunmanCuts = {[1]=0.05, [2]=0.09, [3]=0.07, [4]=0.10, [5]=0.08},
        DriverCuts = {[1]=0.05, [2]=0.07, [3]=0.09, [4]=0.06, [5]=0.10},
        HackerCuts = {[1]=0.03, [2]=0.07, [3]=0.05, [4]=0.10, [5]=0.09},
        ArcadeBlip = 740,
        TeleportCoords = {
            ["计划板"] = {2711.773, -369.458, -54.781},
            ["赌场正门"] = {917.24634, 48.989567, 80.89892},
            ["员工大厅(入口)"] = {965.14856, -9.05023, 80.63045},
            ["废物处理间(入口)"] = {997.5346, 84.51491, 80.990555},
            ["小金库"] = {2520.8645, -286.30685, -58.723007},
            ["双人门禁刷卡点"] = {2465.4746, -279.2276, -70.694145},
            ["金库外面"] = {2497.5098, -238.50768, -70.7388},
            ["金库里面"] = {2515.1252, -238.91661, -70.73713},
            ["员工大厅(出口)"] = {2547.9192, -273.16754, -58.723003},
            ["废物处理间(出口)"] = {2542.052, -214.3084, -58.722965}
        }
    }

    App.Data.Casino = {
        Lists = lists,
        Config = config,
        State = {
            ApproachIndex = 0,
            TargetIndex = 0,
            GunmanIndex = 0,
            WeaponVariantIndex = 0,
            DriverIndex = 0,
            VehicleVariantIndex = 0,
            HackerIndex = 0,
            MaskIndex = 8,
            KeyLevelIndex = 1,
            GuardStrengthIndex = 1,
             AutoLootEnabled = false,
            Payouts = {0, 0, 0, 0},
            TeleportIndex = 0
        }
    }

    return true
end

function CasinoData.Shutdown(App)
    App.Data.Casino = nil
end

return CasinoData
