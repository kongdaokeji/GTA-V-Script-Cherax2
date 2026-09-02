-- Mission Assistant 单人任务数据与状态

local SoloData={Name="Data.Solo"}

function SoloData.Init(App)
    App.Data.Solo={
        State={Enabled=false},
        Natives={GET_RUNNING_SCRIPT_THREAD_COUNT=0x2C83A9DA6BFFC4F9},
        Globals={
            MinParticipants=4718592+3769,
            NumberOfTeams=4718592+3772,
            MaxNumberOfTeams=4718592+3773,
            FirstTeamSlots=4718592+3775+1,
            CriticalMinimum=4718592+196663+1,
            MissionMinBase=794989+4+1,
            MissionMinStride=95,
            MissionMinOffset=75
        },
        Scripts={
            Launcher=Utils.Joaat("fmmc_launcher"),
            OldHeist=Utils.Joaat("fm_mission_controller"),
            NewHeist=Utils.Joaat("fm_mission_controller_2020"),
            MissionV3=Utils.Joaat("fm_mission_controller_v3")
        },
        Locals={
            LauncherMinPlayers=20196+15,
            LauncherVariation=20196+34,
            SkipOld=20412+2,
            SkipNew=56504+2,
            SkipV3=57250+2,
            HostChecks={OldHeist=3290,NewHeist=21077,MissionV3=21133}
        }
    }
    return true
end

function SoloData.Shutdown(App)App.Data.Solo=nil end
return SoloData
