-- Mission Assistant 可切换纹理鼠标
-- 点击、输入和滚动仍由 ImGui 控件处理。

local Cursor={Name="Widgets.Cursor",Textures={}}
local App

local function join_path(base,relative)
    return tostring(base or""):gsub("\\","/"):gsub("/$","").."/"..tostring(relative or""):gsub("\\","/"):gsub("^/","")
end
local function win(path)return tostring(path or""):gsub("/","\\")end

local function submit(style,file)
    local display=join_path(App.Loader.LuaRoot,App.Paths.Assets.."/"..file)
    if not FileMgr.DoesFileExist(display)then return false,"鼠标纹理不存在："..display end
    local ok,id=pcall(Texture.LoadTextureAsync,win(display))
    if not ok or type(id)~="number"then return false,"提交鼠标纹理失败："..tostring(id)end
    Cursor.Textures[style]={Id=id,Object=nil,Path=win(display),Started=Time.GetEpocheMs(),Logged=false}
    return true
end

local function resolve(style)
    local item=Cursor.Textures[style]or Cursor.Textures.classic
    if not item then return nil end
    if item.Object then return item.Object end
    local ok,valid=pcall(Texture.IsTextureValid,item.Id)
    if ok and valid then
        local got,obj=pcall(Texture.GetTexture,item.Id)
        if got and obj then item.Object=obj;return obj end
    end
    if Time.GetEpocheMs()-item.Started>=5000 and not item.Logged then
        item.Logged=true;Logger.LogError("[Mission Cursor] 纹理未就绪："..item.Path)
    end
    return nil
end

function Cursor.Init(app)
    App=app
    local ok,err=submit("classic","cursor.png")
    if not ok then Logger.LogError("[Mission Cursor] "..tostring(err))end
    -- 玻璃光标缺失时仍允许启动，自动回退经典光标。
    local glass_ok,glass_err=submit("glass","cursor_glass.png")
    if not glass_ok then Logger.LogError("[Mission Cursor] "..tostring(glass_err))end
    App.Widgets.Cursor=Cursor
    return true
end

function Cursor.Draw()
    local ui=App.Data.State.Ui
    if not ui.Visible or not ui.DrawSoftwareCursor then return false end
    local style=App.Theme.Manager and App.Theme.Manager.CursorStyle()or"classic"
    local object=resolve(style)or resolve("classic")
    if not object then return false end
    local mx,my=ImGui.GetMousePos();if not mx or not my then return false end
    local ok,texture=pcall(function()return object:GetCurrent()end);if not ok or not texture then return false end

    local metrics=App.Theme.Current.Metrics
    local height=style=="glass"and 22 or metrics.CursorHeight
    local width=height*metrics.CursorTextureWidth/metrics.CursorTextureHeight
    local draw_x=mx-width*metrics.CursorHotspotX/metrics.CursorTextureWidth
    local draw_y=my-height*metrics.CursorHotspotY/metrics.CursorTextureHeight
    local pad=4
    local flags=ImGuiWindowFlags.NoDecoration|ImGuiWindowFlags.NoBackground|ImGuiWindowFlags.NoInputs
        |ImGuiWindowFlags.NoMove|ImGuiWindowFlags.NoSavedSettings|ImGuiWindowFlags.NoFocusOnAppearing|ImGuiWindowFlags.Tooltip

    ImGui.SetMouseCursor(ImGuiMouseCursor.None)
    ImGui.SetNextWindowPos(draw_x-pad,draw_y-pad,ImGuiCond.Always)
    ImGui.SetNextWindowSize(width+pad*2,height+pad*2,ImGuiCond.Always)
    ImGui.SetNextWindowBgAlpha(0.0)
    ImGui.PushStyleColor(ImGuiCol.WindowBg,0,0,0,0)
    ImGui.Begin("##MissionTextureCursorOverlay",true,flags)
    ImGui.AddImage(texture,draw_x,draw_y,draw_x+width,draw_y+height,0,0,1,1,0xFFFFFFFF)
    ImGui.End();ImGui.PopStyleColor(1)
    return true
end

function Cursor.Shutdown(app)
    if app.Widgets.Cursor==Cursor then app.Widgets.Cursor=nil end
    Cursor.Textures={};App=nil
end
return Cursor
