-- Mission Assistant 资产管理数据与运行状态

local AssetData = { Name = "Data.Asset" }

function AssetData.Init(App)
    local lists = {
        WarehouseGoods = {
            "医疗用品", "香烟酒精", "艺术品古董", "电子产品", "武器弹药",
            "毒品", "宝石", "动物材料", "假冒商品", "珠宝", "金条"
        },
        HangarGoods = {
            "动物材料", "艺术品", "化学制品", "假冒商品",
            "首饰宝石", "医疗用品", "迷幻药", "烟酒"
        },
        WarehouseNames = {
            [1] = "太平洋鱼饵仓储", [2] = "白寡妇车库", [3] = "塞尔托瓦单元",
            [4] = "便利店车库", [5] = "法拍车库", [6] = "希罗汽油工厂",
            [7] = "翘臀内衣外景场地", [8] = "透心凉副楼仓库", [9] = "码头 400 号工作仓库",
            [10] = "GEE 仓库", [11] = "洛圣都海事大厦 3 号楼", [12] = "火车站仓库",
            [13] = "贝尔吉科仓库", [14] = "废弃的工厂直销店", [15] = "折扣零售商店",
            [16] = "物流仓库", [17] = "达内尔兄弟仓库", [18] = "家具批发仓库",
            [19] = "柏树仓库", [20] = "西好麦坞外景场地", [21] = "旧发电站",
            [22] = "沃克父子仓库"
        },
        WarehouseCapacities = {
            [1]=16,[2]=16,[3]=16,[4]=16,[5]=16,[6]=111,[7]=42,[8]=111,
            [9]=16,[10]=42,[11]=42,[12]=42,[13]=42,[14]=42,[15]=42,
            [16]=111,[17]=111,[18]=111,[19]=111,[20]=111,[21]=42,[22]=111
        },
        HangarNames = {
            [1] = "洛圣都国际机场 1 号机库", [2] = "洛圣都国际机场 A17 号机库",
            [3] = "桑库多堡 A2 号机库", [4] = "桑库多堡 3497 号机库",
            [5] = "桑库多堡 3499 号机库"
        }
    }

    local config = {
        Natives = {
            PACKED_BOOL = 0xDB8A58AEAA67CD07,
            PACKED_INT = 0x1581503AE529CD2E,
            GET_RUNNING_SCRIPT_THREAD_COUNT = 0x2C83A9DA6BFFC4F9
        },
        Scripts = {
            WarehouseSell = Utils.Joaat("gb_contraband_sell"),
            HangarSell = Utils.Joaat("gb_smuggler")
        },
        Globals = {
            PlayerBase = 1845347 + 1,
            PlayerStride = 884,
            WarehouseOffset = 260 + 128 + 1, -- f_128[slot /*3*/] 嵌套数组头
            WarehouseSlotStride = 3,
            HangarOffset = 260 + 304,
            HangarStockOffset = 260 + 307,
            WarehouseRestockAmount = 1882762 + 13,
            WarehouseGoodsType = 1882762 + 16,
            HangarRestockAmount = 1882787 + 7,
            HangarGoodsType = 1882787 + 8
        },
        Tunables = {
            XpMultiplier = Utils.Joaat("XP_MULTIPLIER"),
            WarehouseCooldowns = {
                {Name="EXEC_BUY_COOLDOWN",Default=300000},
                {Name="EXEC_BUY_FAIL_COOLDOWN",Default=0},
                {Name="EXEC_SELL_COOLDOWN",Default=1800000},
                {Name="EXEC_SELL_FAIL_COOLDOWN",Default=0}
            },
            HangarCooldowns = {
                {Name="SMUG_STEAL_EASY_COOLDOWN_TIMER",Default=120000},
                {Name="SMUG_STEAL_MED_COOLDOWN_TIMER",Default=180000},
                {Name="SMUG_STEAL_HARD_COOLDOWN_TIMER",Default=240000},
                {Name="SMUG_STEAL_ADDITIONAL_CRATE_COOLDOWN_TIME",Default=60000},
                {Name="SMUG_SELL_SELL_COOLDOWN_TIMER",Default=180000}
            }
        },
        Locals = {
            WarehouseSellProgress = 576 + 1,
            WarehouseSellProgressMask = 67230,
            HangarSellUnitCount = 1998 + 1035,
            HangarSellDeliveredCount = 1998 + 1078
        },
        WarehouseRestockReadyPackedFirst = 32359,
        HangarRestockReadyPacked = 36828,
        WarehouseRestockFillAmount = 111,
        HangarRestockFillAmount = 50,
        WarehouseRestockDelayMs = 2000,
        HangarCapacityMax = 50
    }

    App.Data.Asset = {
        Lists = lists,
        Config = config,
        State = {
            WarehouseNoXp = false,
            HangarNoXp = false,
            WarehouseCooldownOff = false,
            HangarCooldownOff = false,
            WarehouseCustomGoods = false,
            WarehouseGoodsIndex = 0,
            HangarCustomGoods = false,
            HangarGoodsIndex = 0
        }
    }
    return true
end

function AssetData.Shutdown(App)
    App.Data.Asset = nil
end

return AssetData
