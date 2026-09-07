-- Mission Assistant 快捷功能数据

local QuickData={Name="Data.Quick"}

function QuickData.Init(App)
    App.Data.Quick={
        State={SelfCut=0},
        Natives={
            PLAYER_PED_ID=0xD80958FC74E988A6,PLAYER_ID=0x4F8644AF03D0E0D6,
            GET_PED_MAX_HEALTH=0x4700A416E8324EF3,SET_ENTITY_HEALTH=0x6B76DC1F3AE6E6A3,
            SET_PED_ARMOUR=0xCEA04D83135264CC,SET_PLAYER_WANTED_LEVEL=0x39FF19C64EF7DA5B,
            SET_PLAYER_WANTED_LEVEL_NOW=0xE0A7D1E497FFCD6F,IS_CUTSCENE_PLAYING=0xD3C2E180A40F031E,
            STOP_CUTSCENE_IMMEDIATELY=0xD220BDD222AC4A1E,REMOVE_CUTSCENE=0x440AF51A3462B86F,
            IS_SCRIPTED_CONVERSATION_ONGOING=0x16754C556D2EDE3D,
            SKIP_TO_NEXT_SCRIPTED_CONVERSATION_LINE=0x9663FE6B7A61EB00,
            NETWORK_CAN_BAIL=0x580CE4438479CC61,NETWORK_BAIL=0x95914459A87EBA28,
            FORCE_CLOUD_SAVE=0xE07BCA305B82D2FD
        },
        Globals={
            SessionType=1575048,SessionState=1574589,SessionExtra=1574589+2,
            SelfCut=2686124+6802,GtaPlusValid=1970586,GtaPlusFlags=1970586+3,
            GtaPlusSessionType=1575048,PlayerInfoBase=2658296+1,
            PlayerInfoStride=468,PlayerGtaPlusFlags=204
        },
        Stats={
            Snacks={
                {"MPX_NO_BOUGHT_YUM_SNACKS",30},{"MPX_NO_BOUGHT_HEALTH_SNACKS",15},
                {"MPX_NO_BOUGHT_EPIC_SNACKS",5},{"MPX_NUMBER_OF_ORANGE_BOUGHT",10},
                {"MPX_NUMBER_OF_BOURGE_BOUGHT",10},{"MPX_NUMBER_OF_CHAMP_BOUGHT",5},
                {"MPX_CIGARETTES_BOUGHT",20},{"MPX_NUMBER_OF_SPRUNK_BOUGHT",10}
            },
            Armour={
                {"MPX_MP_CHAR_ARMOUR_1_COUNT",10},{"MPX_MP_CHAR_ARMOUR_2_COUNT",10},
                {"MPX_MP_CHAR_ARMOUR_3_COUNT",10},{"MPX_MP_CHAR_ARMOUR_4_COUNT",10},
                {"MPX_MP_CHAR_ARMOUR_5_COUNT",10}
            },
            Breathing={{"MPX_BREATHING_APPAR_BOUGHT",20}}
        }
    }
    return true
end

function QuickData.Shutdown(App)App.Data.Quick=nil end
return QuickData
