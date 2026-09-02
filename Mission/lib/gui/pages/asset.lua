-- Mission Assistant 资产管理页面

local AssetPage = { Name = "Gui.Pages.Asset" }
local App
local PH,CH,BH,SG,GG,PG,PB = 46,42,38,10,14,14,18
local function panel(x,y,w,h,t) App.Widgets.Core.Panel(x,y,w,h,t) end

local function cargo_panel(d,a,x,y,w,opt)
    local h = PH+4*CH+4*SG+2*GG+3*BH+PB
    panel(x,y,w,h,opt.Title)
    local ix,iw = x+18, w-36
    local c = y+PH

    -- 启用无经验出售
    local v1, ch1 = App.Widgets.Toggle.Draw(
        opt.Id.."NoXp", "启用无经验出售", d.State[opt.NoXpKey], ix, c, iw, {Height=CH}
    )
    if ch1 then d.State[opt.NoXpKey]=v1; opt.SetNoXp(v1) end
    c = c+CH+SG

    -- 关闭冷却
    local v2, ch2 = App.Widgets.Toggle.Draw(
        opt.Id.."Cooldown", opt.CooldownLabel, d.State[opt.CooldownKey], ix, c, iw, {Height=CH}
    )
    if ch2 then d.State[opt.CooldownKey]=v2; opt.SetCooldown(v2) end
    c = c+CH+SG

    -- 自定义货物类型
    local v3, ch3 = App.Widgets.Toggle.Draw(
        opt.Id.."Custom", "自定义货物类型", d.State[opt.CustomKey], ix, c, iw, {Height=CH}
    )
    if ch3 then d.State[opt.CustomKey]=v3 end
    c = c+CH+GG

    -- 货物类型
    d.State[opt.GoodsIndexKey] = select(1, App.Widgets.Select.Draw(
        opt.Id.."Goods", "货物类型", d.State[opt.GoodsIndexKey],
        d.Lists[opt.GoodsList], ix, c, iw, {MaxVisibleItems=8}
    ))
    c = c+CH+GG

    -- 三个操作按钮分三行显示，避免窄面板内文字拥挤。
    if App.Widgets.Button.Draw(opt.Id.."Restock", "立即补货", ix, c, iw, BH) then opt.Restock() end
    c = c+BH+SG
    if App.Widgets.Button.Draw(opt.Id.."Sell", "立即出售", ix, c, iw, BH) then opt.Sell() end
    c = c+BH+SG
    if App.Widgets.Button.Draw(opt.Id.."Query", "查询库存", ix, c, iw, BH) then opt.Query() end

    return h
end

local function draw_content(d,a,x,y,w)
    local warehouse = {
        Title = "特殊物品仓库", Id = "AssetWh", CooldownLabel = "关闭仓库冷却",
        NoXpKey = "WarehouseNoXp", CooldownKey = "WarehouseCooldownOff",
        CustomKey = "WarehouseCustomGoods", GoodsIndexKey = "WarehouseGoodsIndex",
        GoodsList = "WarehouseGoods",
        SetNoXp = a.SetWarehouseNoXp, SetCooldown = a.SetWarehouseCooldown,
        Restock = a.RestockWarehouse, Sell = a.SellWarehouse, Query = a.QueryWarehouse
    }
    local hangar = {
        Title = "机库", Id = "AssetHg", CooldownLabel = "关闭机库冷却",
        NoXpKey = "HangarNoXp", CooldownKey = "HangarCooldownOff",
        CustomKey = "HangarCustomGoods", GoodsIndexKey = "HangarGoodsIndex",
        GoodsList = "HangarGoods",
        SetNoXp = a.SetHangarNoXp, SetCooldown = a.SetHangarCooldown,
        Restock = a.RestockHangar, Sell = a.SellHangar, Query = a.QueryHangar
    }

    if w < 620 then
        local c = y
        c = c + cargo_panel(d,a,x,c,w,warehouse) + PG
        c = c + cargo_panel(d,a,x,c,w,hangar)
        return c - y
    end

    local cw = math.floor((w-PG)*0.5)
    local rx = x+cw+PG
    local ly = y + cargo_panel(d,a,x,y,cw,warehouse)
    local ry = y + cargo_panel(d,a,rx,y,cw,hangar)
    return math.max(ly,ry) - y
end

function AssetPage.Init(app)
    App = app
    App.Gui.Pages.Asset = AssetPage
    return true
end

function AssetPage.Draw(_,x,y,w,h)
    local ctx = App.Widgets.Scroll.Begin(
        "AssetPage", x, y, w, h,
        {BackgroundColor="Content", ScrollbarBackgroundColor="Content", Padding=0, Rounding=0}
    )
    local ch = 0
    if ctx.ShouldDraw then
        ch = draw_content(App.Data.Asset, App.Actions.Asset, ctx.OriginX, ctx.OriginY, ctx.Width)
    end
    App.Widgets.Scroll.End(ctx, ch)
end

function AssetPage.Shutdown(app)
    if app.Gui.Pages.Asset == AssetPage then app.Gui.Pages.Asset = nil end
    App = nil
end

return AssetPage
