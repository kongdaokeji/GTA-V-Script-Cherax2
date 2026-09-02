-- Mission Assistant require() 模块探针
-- 标准模块只返回一个表，由 Loader 调用 Init(MissionApp)。

local Probe = {
    Name = "Probe"
}

function Probe.Init(App)
    if type(App) ~= "table" then
        return false, "Init(App) 未收到有效的 MissionApp"
    end

    local runtime = App.Runtime
    local probe = runtime and runtime.Probe

    if type(probe) ~= "table" or type(probe.Token) ~= "table" then
        return false, "Loader 探针状态不存在或格式无效"
    end

    probe.Executed = true
    probe.ReturnedToken = probe.Token
    probe.Shared =
        probe.ExpectedGeneration == App.Generation and
        probe.Token.Generation == App.Generation

    if not probe.Shared then
        return false, "Generation 或 Token 校验失败"
    end

    return true
end

return Probe
