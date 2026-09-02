-- Mission Assistant 其他任务数据与独立 UI 状态

local OtherData = {Name = "Data.Other"}

function OtherData.Init(App)
    local lists = {
        Agency={"夜总会","船坞","夜生活泄密","乡村俱乐部","宾客名单","上流社会泄密","戴维斯","巴勒帮","南中心区泄密","工作室时间","别惹德瑞"},
        Tuner={"联合储蓄合约","大钞交易","银行合约","电控单元差事","监狱合约","IAA交易","失落摩托帮合约","数据合约"},
        Clothing={"黑匣子","暴力破解","艺术品","剥离项目公司"},
        SalvageTypes={"货船抢劫","小混混抢劫","杜根抢劫","展台抢劫","麦托尼抢劫"},
        Lowrider={"社区边界","低调，慢慢来","这是好事","葬礼派对","炫酷低底盘车","瞄准射击","绝望的时候需要...","和平礼物"},
        CasinoStory={"解救陈陶","日常杂务","铁腕战术","志在得胜","出奇致胜","金盘套现"},
        Yacht={"翻船落水","打捞行动","全体动员","破冰游戏","一路顺风","作战发起日"},
        Ulp={"情报","反情报","撤离","资产扣押","觅迹行动","清场"},
        DrugWars={"欢迎来到家人团","指定司机","致命侵袭","未受控物质","要战不要爱","脱轨","这是一次入侵","不寻常的嫌疑人","费神","深入","梆梆梆"},
        CluckinTasks={"黑心基金","破门而入","藏匿武装","找事逃逸","瓦解犯罪","犯罪现场"},
        CluckinInfiltrations={"潜行路线","强攻路线"},
        CluckinWeapons={"混混武器","专业武器","军用武器"},
        CluckinArmour={"轻型防弹衣","中型防弹衣","重型防弹衣"},
        CluckinVehicles={"绝致·郁金香","绝致·月光定制版","刺刑官µLX","欧斯洛·扼喉","丁卡·斯国一","旋风·雷电","巨象·爱国者军用版","卡尼斯·终末","巨象·列兵"},
        McKenzieTasks={"开张营业","准备任务：莫古尔","准备任务：情报","准备任务：铁骡","准备任务：弹药","泰坦差事"},
        McKenzieDifficulties={"正常模式","困难模式"},
        Avi={"负面宣传","内线差事","隧道视野","垃圾话","顺利出逃"},
        SalvageVehicles={
            "贝飞特 LM87","兰帕达缇 五千","傲弗拉 独裁者","兰帕达缇 虎狮兽","浪子 冠军","奥北 10F","贝飞特 SM722","奥北 奥姆尼斯 e-GT","菲斯特 嚎叫者","埃努斯 神灵",
            "古罗帝 义塔力 RSX","非凡 艳妇 D10","埃努斯 吉伯力","菲斯特 宇航","菲斯特 陆上彗星 S2 敞篷版","佩嘉西 斗牛","古罗帝 猎豹经典版","古罗帝 远途经典版","佩嘉西 炼狱魔经典版","埃努斯 斯塔福德",
            "古罗帝 GT500","兰帕达缇 维瑟瑞斯","绝致 曼巴","非凡 艳妇黑鳍","古罗帝 史汀格 GT","特卢菲 Z型","卡拉斯科 百老汇","绝致 活力够 ZX","冒险家 猛牛 STX","海岬 拉斯顿",
            "冒险家 铁腕地狱火","威皮 公路霸者 GTT","亚班尼 罗斯福勇气","欧斯洛 放荡者","贝飞特 斯特林 GT","奥北 奥姆尼斯","兰帕达缇 逐波雷厉","欧斯洛 扼喉","巨象 爱国者军用版","佩嘉西 奔牛",
            "威皮 卡拉卡拉四驱车","绝品 卫士经典版","毕福 象鼻虫","丁卡 旅行家羽黑","威拉德 尤朵拉","卡尼斯 卡马乔","爱尼仕 恶人","威皮 爱利","亚班尼 赫耳墨斯","威皮 赫斯勒",
            "古罗帝 远途致敬","冒险家 猛牛 EVX","古罗帝 义塔力 GTO 史汀格 TT","欧斯洛 美德","佩嘉西 伊格纳斯","佩嘉西 桑托劳","菲斯特 霓虹","古罗帝 狂热","佩嘉西 佐路索","特卢菲 特拉克斯",
            "浪子 瓦格纳","苔原 潘瑟力","古罗帝 义塔力 GTO","爱尼仕 S80RR","傲弗拉 统治者","傲弗拉 本质 MT","佩嘉西 斗牛 XO","维沙 尼欧","兰帕达缇 科西塔","埃努斯 帕拉贡 R",
            "亚班尼 科学怪人","菲斯特 彗星狩猎者","深水 FR36","卡林 燃轨埃弗伦","兰帕达缇 科莫达","奥北 密探 S","丁卡 弄臣经典版","丁卡 弄臣 RR","爱尼仕 欧洲","爱尼仕 ZR350",
            "绝品 塞弗","威皮 公路霸者 ASP","悠游 行者 ST-D","兰帕达缇 卡斯科","绝致 漂移约塞米蒂","卡林 埃弗伦","麦霸子 半影使者 FF","亚班尼 V-STR","威皮 公路霸者 GT","贝飞特 撞击 GT",
            "亚班尼 骑兵 XL","威皮 克里克","卡林 粗人","丁卡 斯国一","冒险家 格林伍德","亚班尼 布里格姆","威尼 天威拉力","卡尼斯 陆上专家边境","丁卡 羽黑 SJ","卡林 普莱温"
        }
    }

    local config = {
        Natives={
            PACKED_BOOL=0xDB8A58AEAA67CD07,
            PACKED_INT=0x1581503AE529CD2E,
            GET_RUNNING_SCRIPT_THREAD_COUNT=0x2C83A9DA6BFFC4F9
        },
        AgencyValues={4,12,28,60,123,254,508,1020,2044,2045,4095},
        TunerValues={0,1,2,3,4,5,6,7},
        ClothingValues={0,1,2,3},
        SalvageTypeValues={0,1,2,3,4},
        LowriderValues={1,2,3,4,5,6,7,8},
        CasinoStoryValues={0,1,2,3,4,5},
        YachtValues={0,1,2,3,4,5},
        UlpValues={0,1,2,3,4,5},
        DrugWarsValues={
            {0,0},{1,2},{2,3},{3,7},{4,15},{5,31},{6,4194367},{7,4194431},{8,4194559},{9,4194815},{10,4195327}
        },
        CluckinValues={0,1,3,7,15,31},
        McKenzieValues={0,1,3,7,271,-1},
        AviValues={0,1,2,3,4},
        McKenzieExtraPacked={51265,51266,51264,51268,51269,51270,51271,51260,51261,51262,51263},
        Globals={
            PayphoneCooldown=262145+31373, SecurityCooldown=262145+31293,
            SalvageCooldown1=262145+33655, SalvageCooldown2=262145+33656,
            SalvageTypeSlots={262145+33614,262145+33615,262145+33616},
            SalvageVehicleSlots={262145+33622,262145+33623,262145+33624},
            SalvageBypassSlots={262145+33618,262145+33619,262145+33620}
        },
        Scripts={
            NewHeist=Utils.Joaat("fm_mission_controller_2020"), OldHeist=Utils.Joaat("fm_mission_controller"),
            TunerPlan=Utils.Joaat("tuner_planning"), SalvagePlan=Utils.Joaat("vehrob_planning"),
            Clothing={
                {Hash=Utils.Joaat("fm_content_hacker_house_finale"),Bits=8123+1,State=8267+1192,Name="艺术品"},
                {Hash=Utils.Joaat("fm_content_hacker_cargo_finale"),Bits=7657+1,State=7823+1319,Name="黑匣子"},
                {Hash=Utils.Joaat("fm_content_hacker_whistle_fin"),Bits=6616+1,State=6782+1176,Name="剥离项目公司"},
                {Hash=Utils.Joaat("fm_content_hacker_zancudo_fin"),Bits=8537+1,State=8657+1182,Name="暴力破解"}
            },
            SalvageFinales={
                {Hash=Utils.Joaat("fm_content_vehrob_arena"),Bits=7953+1,State=8073+1315},
                {Hash=Utils.Joaat("fm_content_vehrob_cargo_ship"),Bits=7227+1,State=7372+1250},
                {Hash=Utils.Joaat("fm_content_vehrob_casino_prize"),Bits=9235+1,State=9377+1259},
                {Hash=Utils.Joaat("fm_content_vehrob_police"),Bits=9050+1,State=9183+1306},
                {Hash=Utils.Joaat("fm_content_vehrob_submarine"),Bits=6259+1,State=6420+1160}
            }
        },
        Locals={
            AgencyState1=56504+1, AgencyState2=56504+1776+1,
            TunerBoard=418, NewFinishId=56504+1776+1, NewFinishState=56504+1,
            OldFinishId=20412+1232+1, OldFinishState=20412+1,
            SalvageForceStart=425, SalvageBoard=547
        }
    }

    App.Data.Other={
        Lists=lists,Config=config,
        State={
            AgencyIndex=0,TunerIndex=0,ClothingIndex=0,SalvageTypeIndex=0,SalvageVehicleIndex=0,
            LowriderIndex=0,CasinoStoryIndex=0,YachtIndex=0,UlpIndex=0,DrugWarsIndex=0,AviIndex=0,
            CluckinTaskIndex=0,CluckinInfiltrationIndex=0,CluckinWeaponIndex=0,CluckinArmourIndex=0,CluckinVehicleIndex=0,
            McKenzieTaskIndex=0,McKenzieDifficultyIndex=0,McKenzieExtraEquipment=false
        }
    }
    return true
end

function OtherData.Shutdown(App) App.Data.Other=nil end
return OtherData
