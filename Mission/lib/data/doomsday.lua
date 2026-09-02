-- Mission Assistant 末日豪劫数据与运行状态

local DoomsdayData = {
    Name = "Data.Doomsday"
}

function DoomsdayData.Init(App)
    local lists = {
        Setups = {"数据泄露", "波格丹危机", "末日将至"},
        Teleports = {"设施", "计划板", "末日二虎鲸禁闭室", "末日二虎鲸控制室"}
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
            Planning = Utils.Joaat("gb_gang_ops_planning")
        },
        Globals = {
            Payout = 1969071 + 812 + 50,
            Difficulty = 4718592 + 3771,
            ForceReady = {
                1882797 + 1 + (0 * 321) + 43 + 11 + 1,
                1882797 + 1 + (1 * 321) + 43 + 11 + 2,
                1882797 + 1 + (2 * 321) + 43 + 11 + 3,
                1882797 + 1 + (3 * 321) + 43 + 11 + 4
            }
        },
        Locals = {
            RefreshBoard = 218,
            SkipHack1 = 1588,
            SkipHack2 = 1557,
            SkipHack3 = 1314 + 135,
            QuickFinishBase = 20412,
            State1 = 20412 + 1062, -- 后续功能预留，按要求保留
            CutPercent = 20412 + 1740 + 1,
            Timer1 = 29326 + 1,
            TimerPlayers = 32785 + 1,
            PlayerStride = 294,
            PlayerTimerOffset = 68,
            State2 = 32785 + 97,
            InfiniteLives = 26838 + 1325 + 1,
            HeistState = 20412 + 2,
            HostChecks = {
                OldHeist = 3290,
                NewHeist = 21077,
                MissionV3 = 21133
            }
        },
        SetupValues = {
            {MissionProgress=503, HeistStatus=-229383},
            {MissionProgress=240, HeistStatus=-229378},
            {MissionProgress=16368, HeistStatus=-229380}
        },
        MissionByProgress = {
            [503] = "数据泄露",
            [240] = "波格丹危机",
            [16368] = "末日将至"
        },
        PayoutValues = {
            [1] = { ["数据泄露"]=290, ["波格丹危机"]=198, ["末日将至"]=154 },
            [2] = { ["数据泄露"]=232, ["波格丹危机"]=159, ["末日将至"]=123 }
        },
        WeeklyBoostBits = {
            ["数据泄露"] = 1 << 5,
            ["波格丹危机"] = 1 << 6,
            ["末日将至"] = 1 << 7
        },
        WeeklyMultiplier = 1.22,
        FacilityBlip = 590,
        TeleportCoords = {
            ["计划板"] = {350.69284, 4872.308, -60.794243},
            ["末日二虎鲸禁闭室"] = {512.888, 4833.033, -68.989},
            ["末日二虎鲸控制室"] = {515.528, 4835.353, -62.587}
        }
    }

    App.Data.Doomsday = {
        Lists = lists,
        Config = config,
        State = {
            SetupIndex = 0,
            Payouts = {0, 0, 0, 0},
            TeleportIndex = 0
        }
    }

    return true
end

function DoomsdayData.Shutdown(App)
    App.Data.Doomsday = nil
end

return DoomsdayData
