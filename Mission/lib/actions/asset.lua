-- Mission Assistant 资产业务操作

local Asset = { Name = "Actions.Asset" }
local App
local function context() return App.Data.Asset, App.Actions.Common end
local function queue(label, fn) return App.Actions.Common.Queue(label, fn) end
local function packed(hash, index, value)
    local slot = App.Actions.Common.GetCharacterSlot()
    if slot == nil then return false end
    return pcall(Natives.InvokeVoid, hash, index, value, slot)
end

function Asset.Init(app)
    App = app
    App.Actions.Asset = Asset
    return true
end

-- Tunable 整数写入：Data 层保存名称，运行时转换为 JOAAT。
local function set_tunable_int(name, value)
    local addr = ScriptGlobal.GetTunableByHash(Utils.Joaat(name))
    if addr == 0 then return false end
    Memory.WriteInt(addr, value)
    return true
end

-- 无经验出售：XP_MULTIPLIER 为全局 Tunable，仓库/机库任一开关开启即置 0，都关闭才恢复 1.0。
local function sync_no_xp(d, c)
    local enabled = d.State.WarehouseNoXp or d.State.HangarNoXp
    local addr = ScriptGlobal.GetTunableByHash(d.Config.Tunables.XpMultiplier)
    if addr == 0 then
        c.Toast("无经验出售设置失败：未找到 XP_MULTIPLIER", 4000)
        return
    end
    Memory.WriteFloat(addr, enabled and 0.0 or 1.0)
    c.Toast(enabled and "无经验出售已启用（XP 倍率 0）" or "无经验出售已关闭（XP 倍率恢复）", 3000)
end

function Asset.SetWarehouseNoXp(enabled)
    local d, c = context()
    d.State.WarehouseNoXp = enabled
    return queue("仓库无经验出售", function() sync_no_xp(d, c) end)
end

function Asset.SetHangarNoXp(enabled)
    local d, c = context()
    d.State.HangarNoXp = enabled
    return queue("机库无经验出售", function() sync_no_xp(d, c) end)
end

-- 关闭/恢复冷却 Tunable。
local function apply_cooldowns(list, off)
    local failed = 0
    for _, item in ipairs(list) do
        if not set_tunable_int(item.Name, off and 0 or item.Default) then
            failed = failed + 1
        end
    end
    return failed == 0
end

function Asset.SetWarehouseCooldown(off)
    local d, c = context()
    return queue("仓库冷却", function()
        local ok = apply_cooldowns(d.Config.Tunables.WarehouseCooldowns, off)
        c.Toast(ok and (off and "特殊货物购买/出售冷却已关闭" or "特殊货物购买/出售冷却已恢复")
            or "部分冷却 Tunable 未找到", 3000)
    end)
end

function Asset.SetHangarCooldown(off)
    local d, c = context()
    return queue("机库冷却", function()
        local ok = apply_cooldowns(d.Config.Tunables.HangarCooldowns, off)
        c.Toast(ok and (off and "机库采购/出售冷却已关闭" or "机库采购/出售冷却已恢复")
            or "部分冷却 Tunable 未找到", 3000)
    end)
end

-- 立即补货：循环 5 个仓库槽位，逐槽写入并延迟复查。
function Asset.RestockWarehouse()
    local d, c = context()
    return queue("仓库补货", function()
        local player = GTA.GetLocalPlayerId()
        local g = d.Config.Globals
        local warehouses = {}
        for slot = 0, 4 do
            local property_global = g.PlayerBase + player*g.PlayerStride
                + g.WarehouseOffset + slot*g.WarehouseSlotStride
            local property_id = ScriptGlobal.GetInt(property_global)
            if property_id and property_id > 0 then
                local stock_global = property_global + 1
                warehouses[#warehouses+1] = {
                    slot = slot,
                    property_global = property_global,
                    stock_global = stock_global,
                    property_id = property_id,
                    stock = ScriptGlobal.GetInt(stock_global) or 0,
                    capacity = d.Lists.WarehouseCapacities[property_id]
                }
            end
        end

        if #warehouses == 0 then
            c.Toast("未检测到特种货物仓库", 4000)
            return
        end

        local has_space = false
        for _, w in ipairs(warehouses) do
            if w.capacity ~= nil and w.stock < w.capacity then has_space = true break end
        end
        if not has_space then
            c.Toast("仓库容量已满，无需补货", 4000)
            return
        end

        local custom = d.State.WarehouseCustomGoods
        local goods_index = d.State.WarehouseGoodsIndex

        for _, w in ipairs(warehouses) do
            local property_id = ScriptGlobal.GetInt(w.property_global)
            local capacity = d.Lists.WarehouseCapacities[property_id]
            if property_id >= 1 and capacity ~= nil then
                local stock = ScriptGlobal.GetInt(w.stock_global) or 0
                if stock < capacity then
                    if custom then
                        ScriptGlobal.SetInt(g.WarehouseGoodsType, goods_index)
                    end
                    ScriptGlobal.SetInt(g.WarehouseRestockAmount, d.Config.WarehouseRestockFillAmount)
                    packed(d.Config.Natives.PACKED_BOOL,
                        d.Config.WarehouseRestockReadyPackedFirst + w.slot, true)
                    if not c.Yield(d.Config.WarehouseRestockDelayMs) then return end
                end
            end
        end

        if custom then
            c.Toast("特种货物仓库补货完成，货物种类：" .. d.Lists.WarehouseGoods[goods_index+1], 4000)
        else
            c.Toast("特种货物仓库补货完成，货物种类为随机", 4000)
        end
    end)
end

-- 立即出售：写入出售脚本 Local 完成位掩码。
function Asset.SellWarehouse()
    local d, c = context()
    return queue("仓库出售", function()
        local script_hash = d.Config.Scripts.WarehouseSell
        if not c.IsScriptRunning(script_hash, d.Config.Natives.GET_RUNNING_SCRIPT_THREAD_COUNT) then
            c.Toast("请先启动特种货物出售任务", 4000)
            return
        end
        ScriptLocal.SetInt(script_hash, d.Config.Locals.WarehouseSellProgress,
            d.Config.Locals.WarehouseSellProgressMask)
        c.Toast("已执行特种货物立即出售", 3000)
    end)
end

-- 查询仓库库存。
function Asset.QueryWarehouse()
    local d, c = context()
    return queue("查询仓库库存", function()
        local player = GTA.GetLocalPlayerId()
        local g = d.Config.Globals
        local lines = {}
        for slot = 0, 4 do
            local property_global = g.PlayerBase + player*g.PlayerStride
                + g.WarehouseOffset + slot*g.WarehouseSlotStride
            local property_id = ScriptGlobal.GetInt(property_global)
            if property_id and property_id > 0 then
                local stock = ScriptGlobal.GetInt(property_global + 1) or 0
                local name = d.Lists.WarehouseNames[property_id] or "未知仓库"
                local capacity = d.Lists.WarehouseCapacities[property_id]
                local text = "仓库：" .. name .. " 库存：" .. tostring(stock)
                if capacity ~= nil then text = text .. "/" .. tostring(capacity) end
                lines[#lines+1] = text
            end
        end
        if #lines == 0 then
            c.Toast("未检测到特种货物仓库", 4000)
            return
        end
        for index, text in ipairs(lines) do
            c.Toast(string.format("[%d/%d] %s", index, #lines, text), 6000)
            if index < #lines and not c.Yield(200) then return end
        end
    end)
end

-- 机库立即补货。
function Asset.RestockHangar()
    local d, c = context()
    return queue("机库补货", function()
        local player = GTA.GetLocalPlayerId()
        local g = d.Config.Globals
        local owned_global = g.PlayerBase + player*g.PlayerStride + g.HangarOffset
        local property_id = ScriptGlobal.GetInt(owned_global)
        if not property_id or property_id < 1 then
            c.Toast("未检测到机库", 4000)
            return
        end
        local stock_global = g.PlayerBase + player*g.PlayerStride + g.HangarStockOffset
        local stock = ScriptGlobal.GetInt(stock_global) or 0
        if stock >= d.Config.HangarCapacityMax then
            c.Toast("机库容量已满，无需补货", 4000)
            return
        end
        if d.State.HangarCustomGoods then
            ScriptGlobal.SetInt(g.HangarGoodsType, d.State.HangarGoodsIndex)
        end
        ScriptGlobal.SetInt(g.HangarRestockAmount, d.Config.HangarRestockFillAmount)
        packed(d.Config.Natives.PACKED_BOOL, d.Config.HangarRestockReadyPacked, true)
        if d.State.HangarCustomGoods then
            c.Toast("机库补货完成，货物种类：" .. d.Lists.HangarGoods[d.State.HangarGoodsIndex+1], 4000)
        else
            c.Toast("机库补货完成，货物种类为随机", 4000)
        end
    end)
end

-- 机库立即出售。
function Asset.SellHangar()
    local d, c = context()
    return queue("机库出售", function()
        local script_hash = d.Config.Scripts.HangarSell
        if not c.IsScriptRunning(script_hash, d.Config.Natives.GET_RUNNING_SCRIPT_THREAD_COUNT) then
            c.Toast("请先启动机库航空货运出售任务", 4000)
            return
        end
        ScriptLocal.SetInt(script_hash, d.Config.Locals.HangarSellUnitCount, 0)
        ScriptLocal.SetInt(script_hash, d.Config.Locals.HangarSellDeliveredCount, 1)
        c.Toast("已执行机库航空货运立即出售", 3000)
    end)
end

-- 查询机库库存。
function Asset.QueryHangar()
    local d, c = context()
    return queue("查询机库库存", function()
        local player = GTA.GetLocalPlayerId()
        local g = d.Config.Globals
        local owned_global = g.PlayerBase + player*g.PlayerStride + g.HangarOffset
        local property_id = ScriptGlobal.GetInt(owned_global)
        if not property_id or property_id < 1 then
            c.Toast("未检测到机库", 4000)
            return
        end
        local stock_global = g.PlayerBase + player*g.PlayerStride + g.HangarStockOffset
        local stock = ScriptGlobal.GetInt(stock_global) or 0
        local name = d.Lists.HangarNames[property_id] or "未知机库"
        c.Toast("机库：" .. name .. " 库存：" .. tostring(stock), 5000)
    end)
end

function Asset.Shutdown(app)
    if app.Actions.Asset == Asset then app.Actions.Asset = nil end
    App = nil
end

return Asset
