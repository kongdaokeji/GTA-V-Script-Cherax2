-- Mission Assistant 公寓抢劫数据与运行状态

local ApartmentData = {
    Name = "Data.Apartment"
}

function ApartmentData.Init(App)
    local lists = {
        Heists = {"全福银行", "越狱", "突袭人道研究实验室", "首轮募资", "太平洋标准银行"},
        Teleports = {
            "阿尔塔街", "阿尔塔街计划板", "正直小道", "正直小道计划板", "日蚀大厦",
            "日蚀大厦计划板", "佩罗高地", "佩罗高地计划板", "七叶树", "七叶树计划板"
        }
    }

    local config = {
        Natives = {
            STAT_SET_STRING = 0xA87B2335D12531D7,
            STAT_GET_STRING = 0xE50384ACC2C3DB74,
            IS_CUTSCENE_PLAYING = 0xD3C2E180A40F031E,
            PLAYER_PED_ID = 0xD80958FC74E988A6,
            IS_PED_IN_ANY_VEHICLE = 0x997ABD671D25CA0B,
            GET_VEHICLE_PED_IS_IN = 0x9A9112A0FE9A4713,
            SET_ENTITY_COORDS = 0x06843DA7060A026B,
            SET_GAMEPLAY_CAM_RELATIVE_HEADING = 0xB4EC2312F4E5B1F1,
            GET_RUNNING_SCRIPT_THREAD_COUNT = 0x2C83A9DA6BFFC4F9,
            GET_FIRST_BLIP_INFO_ID = 0x1BEDE233E6CD2A1F,
            GET_BLIP_INFO_ID_ENTITY_INDEX = 0x4BA4E2553AFEDC2C,
            GET_BLIP_COORDS = 0x586AFE3FF72D996E,
            DOES_ENTITY_EXIST = 0x7239B21A38F536BA,
            GET_ENTITY_COORDS = 0x3FEF770D40960D5A
        },
        Scripts = {
            OldHeist = Utils.Joaat("fm_mission_controller"),
            NewHeist = Utils.Joaat("fm_mission_controller_2020"),
            MissionV3 = Utils.Joaat("fm_mission_controller_v3")
        },
        Globals = {
            PlayerApartmentBase = 1845347 + 1,
            PlayerApartmentStride = 884,
            PlayerApartmentOffset = 260 + 39,
            RootContentId1 = 1941984 + 10,
            RootContentHash = 2635125 + 2,
            RootContentId2 = 1936441 + 1787,
            PlayerStateBase = 1877383 + 1,
            PlayerStateStride = 77,
            PlayerStateOffset = 76,
            ContentState = 2635125 + 1,
            ContentLaunch = 2635124,
            BoardState = 1938374 + 2768,
            ForceReady = {
                2658296 + 1 + (0 * 468) + 270,
                2658296 + 1 + (1 * 468) + 270,
                2658296 + 1 + (2 * 468) + 270,
                2658296 + 1 + (3 * 468) + 270
            },
            Payout1 = 1936406 + 1,
            Payout2 = 1938374 + 3008 + 1,
            Difficulty = 4718592 + 3771
        },
        Locals = {
            SkipSnake = 12239 + 24,
            SkipDrill = 10527 + 11,
            HackPacific = 10233,
            InfiniteLives = 26838 + 1325 + 1,
            QuickFinishBase = 20412,
            CutPercent = 20412 + 1740 + 1,
            TargetAmount = 20412 + 2686,
            State1 = 20412 + 1062,
            HeistState = 20412 + 2,
            Timer1 = 29326 + 1,
            TimerPlayers = 32785 + 1,
            PlayerStride = 294,
            PlayerTimerOffset = 68,
            HostChecks = {OldHeist=3290, NewHeist=21077, MissionV3=21133}
        },
        Heists = {
            ["全福银行"] = {
                RcontIds={-1072870761, "hK5OgJk1BkinXGGXghhTMg", "V7yEdnL6TEyU3i-U1Rv_pQ"},
                DepthLevels={-1,0,1}, ProgressHash=-836352461, RewardCosmetic=25,
                RootContentId="33TxqLipLUintwlU_YDzMg"
            },
            ["越狱"] = {
                RcontIds={979654579, "7-w96-PU4kSevhtG5YwUHQ", "oSXhVwaHH0KDOzg0rfIj3Q", "QS6WYcjJFk2YxqYDMN8mjQ", "JJ9OzPbPo02eQbaniO8E3g"},
                DepthLevels={-1,0,0,0,1}, ProgressHash=137052480, RewardCosmetic=22,
                RootContentId="A6UBSyF61kiveglc58lm2Q"
            },
            ["突袭人道研究实验室"] = {
                RcontIds={-1096986654, "BWsCWtmnvEWXBrprK9hDHA", "6k6LOpnf2E-GG38OhjS-TA", "nSWwSwAf3EaHZWsk449lBg", "ciWN4gwmakid4lW-nSllcA", "v-8OOQYzxE-Zvqj5xO03DQ"},
                DepthLevels={-1,0,0,1,2,2}, ProgressHash=496643418, RewardCosmetic=23,
                RootContentId="a_hWnpMUz0-7Yd_Rc5pJ4w"
            },
            ["首轮募资"] = {
                RcontIds={164435858, "20Lu41Px20OJMPdZ6wXG3g", "6UzZkstFeEeCkvs2lrF_6A", "PPnsIR0v2U2COyRbED87gw", "z49DSS9db0i_vh6A2e-Q-g", "Fo168mMjCUCeN_IKmL4VnA"},
                DepthLevels={-1,0,0,0,1,2}, ProgressHash=1585746186, RewardCosmetic=24,
                RootContentId="7r5AKL5aB0qe9HiDy3nW8w"
            },
            ["太平洋标准银行"] = {
                RcontIds={-231973569, "zCxFg29teE2ReKGnr0L4Bg", "6ClY8ZA_DkuBUdZ_fPn6Rw", "OiSO3Z0YdkCaEqVHhhkj4Q", "Cy2OZSwCt0-mSXY00o4SNw", "Y4zpRQDfvkawfFDR1Uxi2A"},
                DepthLevels={-1,0,1,2,2,2}, ProgressHash=911181645, RewardCosmetic=21,
                RootContentId="hKSf9RCT8UiaZlykyGrMwg"
            }
        },
        HeistNamesById = {
            ["hK5OgJk1BkinXGGXghhTMg"]="全福银行",
            ["7-w96-PU4kSevhtG5YwUHQ"]="越狱",
            ["BWsCWtmnvEWXBrprK9hDHA"]="突袭人道研究实验室",
            ["20Lu41Px20OJMPdZ6wXG3g"]="首轮募资",
            ["zCxFg29teE2ReKGnr0L4Bg"]="太平洋标准银行"
        },
        PacificId = "zCxFg29teE2ReKGnr0L4Bg",
        PayoutValues = {
            [0]={ ["全福银行"]=2981, ["越狱"]=857, ["突袭人道研究实验室"]=634, ["首轮募资"]=848, ["太平洋标准银行"]=400 },
            [1]={ ["全福银行"]=1491, ["越狱"]=428, ["突袭人道研究实验室"]=317, ["首轮募资"]=424, ["太平洋标准银行"]=200 },
            [2]={ ["全福银行"]=1192, ["越狱"]=342, ["突袭人道研究实验室"]=253, ["首轮募资"]=339, ["太平洋标准银行"]=160 }
        },
        WeeklyBoostBits = {
            ["全福银行"] = 1 << 0,
            ["越狱"] = 1 << 2,
            ["突袭人道研究实验室"] = 1 << 1,
            ["首轮募资"] = 1 << 3,
            ["太平洋标准银行"] = 1 << 4
        },
        WeeklyMultiplier = 1.5,
        PacificAmounts = {[0]=750000, [1]=1500000, [2]=1875000},
        TeleportCoords = {
            ["阿尔塔街"]={-258.810,-970.212,31.220}, ["阿尔塔街计划板"]={-270.683,-949.492,92.516},
            ["正直小道"]={-49.510,-588.354,37.838}, ["正直小道计划板"]={-24.686,-598.627,100.238},
            ["日蚀大厦"]={-776.731,311.628,85.698}, ["日蚀大厦计划板"]={-798.450,326.422,187.313},
            ["佩罗高地"]={-1441.584,-545.335,34.742}, ["佩罗高地计划板"]={-1455.615,-532.397,69.562},
            ["七叶树"]={371.873,429.564,145.233}, ["七叶树计划板"]={378.326,432.332,138.300}
        }
    }

    App.Data.Apartment = {
        Lists=lists, Config=config,
        State={HeistIndex=0, Payouts={0,0,0,0}, TeleportIndex=0}
    }
    return true
end

function ApartmentData.Shutdown(App)
    App.Data.Apartment = nil
end

return ApartmentData
