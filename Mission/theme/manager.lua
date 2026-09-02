-- Mission Assistant 主题管理器

local Manager={Name="Theme.Manager"}
local App

local defaults={
    UiMode="classic",BackgroundEnabled=false,Background="",BackgroundMode="cover",
    BackgroundOpacity=100,BackgroundScale=100,BackgroundOffsetX=0,BackgroundOffsetY=0,
    OverlayStyle="light",OverlayOpacity=42,PanelOpacity=58,WindowOpacity=100,
    AccentR=255,AccentG=104,AccentB=128,CornerRadius=12,TextScale=100,
    NavigationStyle="full",Density="standard",CursorStyle="auto",ToggleKey=0x22,GlassDefaultsApplied=false
}
local enums={
    UiMode={classic=true,glass=true},BackgroundMode={cover=true,contain=true,stretch=true,center=true},
    OverlayStyle={light=true,dark=true},NavigationStyle={icons=true,full=true},
    Density={compact=true,standard=true,comfortable=true},CursorStyle={auto=true,classic=true,glass=true}
}
local ranges={
    BackgroundOpacity={0,100},BackgroundScale={50,200},BackgroundOffsetX={-1000,1000},
    BackgroundOffsetY={-1000,1000},OverlayOpacity={0,100},PanelOpacity={0,100},WindowOpacity={0,100},
    AccentR={0,255},AccentG={0,255},AccentB={0,255},CornerRadius={0,24},TextScale={80,130},
    ToggleKey={8,254}
}
-- 可绑定热键的虚拟键码显示名（Microsoft Virtual Key Codes）。
local KEY_NAMES={
    [0x08]="退格",[0x09]="Tab",[0x0D]="回车",[0x13]="Pause",
    [0x14]="CapsLock",[0x1B]="Esc",[0x20]="空格",
    [0x21]="PgUp",[0x22]="PgDn",[0x23]="End",[0x24]="Home",
    [0x25]="←",[0x26]="↑",[0x27]="→",[0x28]="↓",
    [0x2D]="Insert",[0x2E]="Delete",
    [0x6A]="小键盘*",[0x6B]="小键盘+",[0x6C]="小键盘回车",[0x6D]="小键盘-",[0x6E]="小键盘.",[0x6F]="小键盘/",
    [0x90]="NumLock",[0x91]="ScrollLock",
    [0xBA]=";",[0xBB]="=",[0xBC]=",",[0xBD]="-",[0xBE]=".",[0xBF]="/",[0xC0]="`",
    [0xDB]="[",[0xDC]="\\",[0xDD]="]",[0xDE]="'"
}
for i=0x30,0x39 do KEY_NAMES[i]=string.char(i) end
for i=0x41,0x5A do KEY_NAMES[i]=string.char(i) end
for i=0x60,0x69 do KEY_NAMES[i]="小键盘"..string.char(i-0x60+0x30) end
for i=0x70,0x7B do KEY_NAMES[i]="F"..(i-0x70+1) end

local function copy(t)local r={}for k,v in pairs(t or{})do r[k]=type(v)=="table"and copy(v)or v end return r end
local function clamp(v,a,b)v=tonumber(v)or a;return math.max(a,math.min(v,b))end
local function mix(a,b,n)return math.floor(a+(b-a)*n+0.5)end
local function alpha(p)return math.floor(clamp(p,0,100)*2.55+0.5)end
local function scale_color_alpha(color,percentage)
    if type(color)~="table"then return end
    color[4]=math.floor((tonumber(color[4])or 0)*clamp(percentage,0,100)/100+0.5)
end
local TEXT_COLOR_KEYS={
    Text=true,TextAccent=true,TextMuted=true,TextSecondary=true,TextDisabled=true,
    ControlText=true,ControlLabel=true,ControlIcon=true,
    NavText=true,NavHoverText=true,NavActiveText=true,
    PanelTitle=true,DropdownText=true,DropdownSelectedText=true,
    Popup=true,PopupBorder=true,PopupPressed=true,PopupAccent=true,
    PopupScrollbar=true,PopupScrollbarHover=true,PopupScrollbarActive=true,
    DropdownHover=true,DropdownSelected=true,
    TooltipText=true,Danger=true,
    ToggleLabelOn=true,ToggleTrackOn=true,
    ToggleTrackOnHover=true,ToggleTrackOff=true,ToggleTrackDisabled=true,
    ToggleKnobOn=true,
    ToggleKnobOff=true,ToggleKnobDisabled=true,ToggleOff=true,ToggleKnob=true
}
local function join(a,b)return tostring(a):gsub("\\","/"):gsub("/$","").."/"..tostring(b):gsub("\\","/"):gsub("^/","")end
local function win(p)return tostring(p):gsub("/","\\")end
local function basename(p)return tostring(p):gsub("\\","/"):match("([^/]+)$")or tostring(p)end
local function extension(p)
    local value=tostring(p or""):match("%.([^%.\\/]+)$")
    return value and value:lower()or""
end
local supported_images={gif=true,png=true,jpg=true,jpeg=true,bmp=true,webp=true}
local function normalize(key,value)
    if enums[key]then value=tostring(value or"");return enums[key][value]and value or defaults[key]end
    if ranges[key]then local r=ranges[key];return math.floor(clamp(value,r[1],r[2])+0.5)end
    if key=="BackgroundEnabled"or key=="GlassDefaultsApplied"then return value==true or value=="true" or value=="1"end
    if key=="Background"then return basename(value or"")end
    return defaults[key]
end

function Manager.ToggleKeyName(vk)
    vk=tonumber(vk)or Manager.Settings.ToggleKey
    return KEY_NAMES[vk]or("VK_0x"..string.format("%02X",vk))
end
function Manager.Get(key)return Manager.Settings[key]end
function Manager.IsGlass()return Manager.Settings.UiMode=="glass"end
function Manager.DensityMultiplier()
    if not Manager.IsGlass()then return 1 end
    local d=Manager.Settings.Density;return d=="compact"and 0.92 or d=="comfortable"and 1.08 or 1
end
function Manager.TextMultiplier()return Manager.IsGlass()and Manager.Settings.TextScale/100 or 1 end
function Manager.IsIconNavigation()return Manager.IsGlass()and Manager.Settings.NavigationStyle=="icons"end
function Manager.CursorStyle()
    local style=Manager.Settings.CursorStyle
    if style=="auto"then
        if not Manager.IsGlass()then return "classic"end
        return Manager.Settings.OverlayStyle=="light"and"glass"or"classic"
    end
    return style
end

local function apply_palette()
    local theme=App.Theme.Current
    local colors=copy(Manager.BaseColors)
    local metrics=copy(Manager.BaseMetrics)
    local s=Manager.Settings;local r,g,b=s.AccentR,s.AccentG,s.AccentB
    if not Manager.IsGlass()then
        App.Theme.Current.Colors=colors
        App.Theme.Current.Metrics=metrics
        return
    end
    colors.Accent={r,g,b,245};colors.TextAccent={r,g,b,245};colors.AccentHover={mix(255,r,0.16),mix(255,g,0.16),mix(255,b,0.16),255}
    colors.AccentSoft={r,g,b,72};colors.WindowBorder={r,g,b,210};colors.GlowMiddle={r,g,b,72};colors.GlowOuter={r,g,b,24}
    colors.TitleIconFill={r,g,b,28};colors.NavIconAccent={r,g,b,145};colors.NavIconHover={r,g,b,205};colors.NavIconActive={r,g,b,245}
    colors.ControlBorderHover={r,g,b,105};colors.ControlBorderActive={r,g,b,255};colors.ControlActiveGlow={r,g,b,40}
    colors.ToggleTrackOn={r,g,b,225};colors.ToggleTrackOnHover={r,g,b,250};colors.ToggleBorderOn={r,g,b,175}
    colors.DropdownSelected={r,g,b,82};colors.ScrollbarHover={r,g,b,185}
    metrics.WindowRounding=math.min(28,s.CornerRadius+4);metrics.WindowOuterRounding=metrics.WindowRounding+2
    metrics.WindowOuterBorder=2;metrics.WindowFrameInset=1
    metrics.PanelRounding=math.min(s.CornerRadius,8);metrics.ControlRounding=math.min(s.CornerRadius,8)
    if s.Density=="compact"then
        metrics.SidebarItemHeight=44;metrics.SidebarItemGap=3;metrics.ContentPadding=26;metrics.PanelPadding=16;metrics.WidgetGap=8
    elseif s.Density=="comfortable"then
        metrics.SidebarItemHeight=52;metrics.SidebarItemGap=7;metrics.ContentPadding=36;metrics.PanelPadding=20;metrics.WidgetGap=16
    end
    if Manager.IsGlass()then
        colors.Panel[4]=alpha(s.PanelOpacity)
        if s.OverlayStyle=="light"then
            colors.Window={238,243,249,232};colors.Sidebar={255,255,255,105};colors.Header={255,255,255,82};colors.Content={255,255,255,28}
            colors.WindowFrame={255,255,255,70};colors.WindowBorder={r,g,b,175};colors.Divider={66,74,92,32}
            colors.Panel={255,255,255,alpha(s.PanelOpacity)};colors.PanelBorder={255,255,255,168};colors.Text={25,28,38,250};colors.TextMuted={74,80,96,225};colors.TextSecondary={97,103,119,220};colors.TextDisabled={122,127,140,190}
            colors.PanelTitle={30,33,44,245};colors.NavText={62,67,82,225};colors.NavHoverText={23,26,36,245};colors.NavActiveText={255,255,255,250};colors.SidebarHover={255,255,255,105};colors.SidebarActive={r,g,b,225}
            colors.Control={255,255,255,128};colors.ControlHover={255,255,255,178};colors.ControlPressed={mix(255,r,0.16),mix(255,g,0.16),mix(255,b,0.16),220};colors.ButtonPressed=colors.ControlPressed;colors.ControlActive={255,255,255,205};colors.ControlDisabled={232,235,241,105};colors.CloseHover={255,255,255,140};colors.ClosePressed={255,255,255,190}
            colors.ControlBorder={255,255,255,178};colors.ControlDisabledBorder={100,106,120,28};colors.ControlText={30,33,44,245};colors.ControlLabel={74,80,96,225};colors.ControlIcon={97,103,119,220}
            colors.ToggleHover={255,255,255,178};colors.ToggleLabelOn={30,33,44,245};colors.ToggleTrackOff={117,123,139,145};colors.ToggleTrackDisabled={117,123,139,95};colors.ToggleBorderOff={255,255,255,145};colors.ToggleKnobOff={244,246,250,240};colors.ToggleKnobDisabled={122,127,140,190}
            colors.Popup={248,250,253,248};colors.PopupBorder={255,255,255,178};colors.PopupPressed={255,255,255,205};colors.PopupAccent={r,g,b,245};colors.PopupScrollbar={65,72,90,115};colors.PopupScrollbarHover={r,g,b,185};colors.PopupScrollbarActive={r,g,b,245};colors.DropdownHover={235,240,247,250};colors.DropdownText={74,80,96,235};colors.DropdownSelectedText={22,25,34,250};colors.Scrollbar={65,72,90,115}
        else
            colors.Window={18,20,28,225};colors.Sidebar={20,22,31,210};colors.Header={24,26,36,230};colors.Content={16,18,25,190}
            colors.WindowFrame={255,255,255,22};colors.WindowBorder={r,g,b,150};colors.Divider={255,255,255,34}
            colors.Panel={31,34,45,alpha(s.PanelOpacity)};colors.PanelBorder={255,255,255,46};colors.Text={247,248,252,250};colors.TextMuted={204,208,220,235};colors.TextSecondary={166,172,190,225};colors.TextDisabled={133,138,154,205};colors.PanelTitle={239,241,248,245}
            colors.NavText={201,205,218,230};colors.NavHoverText={252,252,255,248};colors.SidebarHover={255,255,255,24}
            colors.Control={45,48,62,230};colors.ControlHover={57,61,78,240};colors.ControlPressed={r,g,b,165};colors.ButtonPressed=colors.ControlPressed;colors.ControlActive={57,61,78,240};colors.ControlDisabled={42,44,56,145};colors.ControlBorder={255,255,255,48};colors.ControlDisabledBorder={255,255,255,20};colors.CloseHover={255,255,255,28};colors.ClosePressed={255,255,255,45}
            colors.ControlText={239,241,248,245};colors.ControlLabel={204,208,220,235};colors.ControlIcon={166,172,190,225};colors.ToggleHover={57,61,78,220};colors.ToggleLabelOn={247,248,252,250};colors.ToggleTrackOff={104,109,126,185};colors.ToggleTrackDisabled={80,84,99,135};colors.ToggleBorderOff={255,255,255,38};colors.ToggleKnobOff={218,221,230,240};colors.ToggleKnobDisabled={133,138,154,190}
            colors.Popup={34,37,49,252};colors.PopupBorder={255,255,255,48};colors.PopupPressed={57,61,78,240};colors.PopupAccent={r,g,b,245};colors.PopupScrollbar={222,226,238,90};colors.PopupScrollbarHover={r,g,b,185};colors.PopupScrollbarActive={r,g,b,245};colors.DropdownHover={49,53,68,250};colors.DropdownText={204,208,220,235};colors.DropdownSelectedText={255,255,255,250};colors.Scrollbar={222,226,238,90}
        end
    end
    -- WindowOpacity affects surfaces and controls, while text keeps its opacity.
    for name,color in pairs(colors)do
        if not TEXT_COLOR_KEYS[name] then
            scale_color_alpha(color,s.WindowOpacity)
        end
    end
    theme.Colors=colors;theme.Metrics=metrics
end

local function apply_first_glass_defaults()
    if Manager.Settings.GlassDefaultsApplied then return end
    Manager.Settings.OverlayStyle="light"
    Manager.Settings.OverlayOpacity=42
    Manager.Settings.PanelOpacity=58
    Manager.Settings.AccentR=255
    Manager.Settings.AccentG=104
    Manager.Settings.AccentB=128
    Manager.Settings.NavigationStyle="full"
    Manager.Settings.Density="comfortable"
    Manager.Settings.CursorStyle="auto"
    Manager.Settings.GlassDefaultsApplied=true
end

function Manager.Set(key,value,save)
    if defaults[key]==nil then return false end
    local normalized=normalize(key,value)
    if key=="UiMode"and normalized=="glass"then apply_first_glass_defaults()end
    if key=="OverlayStyle"and normalized=="light"then
        if (tonumber(Manager.Settings.OverlayOpacity)or 0)<25 then
            Manager.Settings.OverlayOpacity=42
        end
        if (tonumber(Manager.Settings.PanelOpacity)or 0)<25 then
            Manager.Settings.PanelOpacity=58
        end
    end
    Manager.Settings[key]=normalized;apply_palette()
    if key=="Background"then Manager.BackgroundTexture=nil;Manager.BackgroundTextureId=nil end
    if save then return Manager.Save() end
    return true
end
function Manager.Reset()
    local keep=Manager.Settings.ToggleKey
    Manager.Settings=copy(defaults);Manager.BackgroundTexture=nil;Manager.BackgroundTextureId=nil
    Manager.Settings.ToggleKey=keep
    apply_palette();return Manager.Save()
end
function Manager.Save()
    local lines={}
    for key in pairs(defaults)do lines[#lines+1]=key.."="..tostring(Manager.Settings[key])end
    table.sort(lines)
    return FileMgr.WriteFileContent(Manager.ConfigPath,table.concat(lines,"\n").."\n",false)==true
end
function Manager.Load()
    if not FileMgr.DoesFileExist(Manager.ConfigPath)then return false end
    local ok,text=pcall(FileMgr.ReadFileContent,Manager.ConfigPath);if not ok or type(text)~="string"then return false end
    for line in text:gmatch("[^\r\n]+")do local k,v=line:match("^([%w_]+)=(.*)$");if k and defaults[k]~=nil then Manager.Settings[k]=normalize(k,v)end end
    return true
end

function Manager.RefreshBackgrounds()
    Manager.BackgroundTexture=nil
    Manager.BackgroundTextureId=nil
    Manager.Backgrounds={"无背景"}
    Manager.BackgroundFiles={[1]=""}
    Manager.BackgroundPaths={[1]=""}
    Manager.LastScanErrors={}

    local seen={}
    local extensions={"gif","png","jpg","jpeg","bmp","webp"}
    local sources={
        {
            Base=Manager.BackgroundDir,
            Scans={Manager.BackgroundDir,Manager.BackgroundRelative,"Lua/"..Manager.BackgroundRelative}
        },
        {
            Base=Manager.AssetsDir,
            Scans={Manager.AssetsDir,Manager.AssetsRelative,"Lua/"..Manager.AssetsRelative}
        },
        {
            Base=Manager.ThemeDir,
            Scans={Manager.ThemeDir,Manager.ThemeRelative,"Lua/"..Manager.ThemeRelative}
        }
    }

    local function resolve_path(path,source)
        local normalized=tostring(path or""):gsub("\\","/"):gsub("^%./","")
        if normalized:match("^%a:/")or normalized:sub(1,1)=="/"then
            return normalized
        end
        if normalized:sub(1,4)=="Lua/"then
            return join(App.Loader.MenuRoot,normalized)
        end
        if normalized:sub(1,8)=="Mission/"then
            return join(App.Loader.LuaRoot,normalized)
        end
        return join(source.Base,normalized)
    end

    local function accept(path,source)
        local name=basename(path)
        local lower=name:lower()
        if lower=="cursor.png"
            or lower=="cursor_glass.png"
            or lower=="official_qq_group.png"
            or not supported_images[extension(name)]
        then
            return false
        end
        local key=name:lower()
        if seen[key]then return false end
        seen[key]=true
        Manager.BackgroundFiles[#Manager.BackgroundFiles+1]=name
        Manager.BackgroundPaths[#Manager.BackgroundPaths+1]=resolve_path(path,source)
        return true
    end

    local function directory_variants(source)
        local result,used={},{}
        local function add(value)
            value=tostring(value or"")
            if value==""then return end
            for _,candidate in ipairs({value,value.."/",win(value),win(value).."\\"})do
                if not used[candidate]then used[candidate]=true;result[#result+1]=candidate end
            end
        end
        for _,value in ipairs(source.Scans)do add(value)end
        return result
    end

    local function scan(source,recursive)
        local directories=directory_variants(source)
        local found=false
        local function run_filter(filter)
            local filter_found=false
            for _,directory in ipairs(directories)do
                local ok,files=pcall(FileMgr.FindFiles,directory,filter,recursive)
                if ok and type(files)=="table"then
                    -- 兼容数组、0 起始表、{[path]=true} 以及文件描述表。
                    for key,value in pairs(files)do
                        local path=nil
                        if type(value)=="string"then
                            path=value
                        elseif type(key)=="string"then
                            path=key
                        elseif type(value)=="table"then
                            path=value.Path or value.path or value.File or value.file
                                or value.Name or value.name or value[1]
                        end
                        if path and accept(path,source)then filter_found=true;found=true end
                    end
                elseif not ok then
                    Manager.LastScanErrors[#Manager.LastScanErrors+1]=tostring(files)
                end
            end
            return filter_found
        end

        for _,all_filter in ipairs({"","*",".*","*.*"})do
            if run_filter(all_filter)then return true end
        end
        for _,format in ipairs({"%s",".%s","*.%s"})do
            local style_found=false
            for _,ext in ipairs(extensions)do
                if run_filter(string.format(format,ext))then style_found=true end
                if run_filter(string.format(format,ext:upper()))then style_found=true end
            end
            if style_found then break end
        end
        return found
    end

    for _,source in ipairs(sources)do
        if not scan(source,false)then scan(source,true)end
    end

    -- 某些 Cherax 构建的 FindFiles 对图片扩展过滤始终返回空；
    -- 对常见背景文件名使用 DoesFileExist 兜底（A、background、wallpaper 等）。
    for _,source in ipairs(sources)do
        for _,stem in ipairs({"A","a","background","Background","wallpaper","Wallpaper"})do
            for _,ext in ipairs(extensions)do
                local candidate=join(source.Base,stem.."."..ext)
                local ok,exists=pcall(FileMgr.DoesFileExist,candidate)
                if ok and exists then accept(candidate,source)end
            end
        end
    end

    local paths,names={},{}
    for index=2,#Manager.BackgroundFiles do
        local name=Manager.BackgroundFiles[index]
        names[#names+1]=name
        paths[name]=Manager.BackgroundPaths[index]
    end
    table.sort(names,function(a,b)return a:lower()<b:lower()end)
    Manager.Backgrounds={"无背景"}
    Manager.BackgroundFiles={""}
    Manager.BackgroundPaths={""}
    for _,name in ipairs(names)do
        Manager.Backgrounds[#Manager.Backgrounds+1]=name
        Manager.BackgroundFiles[#Manager.BackgroundFiles+1]=name
        Manager.BackgroundPaths[#Manager.BackgroundPaths+1]=paths[name]or join(Manager.BackgroundDir,name)
    end

    Logger.LogInfo(string.format(
        "[Mission Theme] 背景扫描完成：%d 张；目录：%s",
        Manager.BackgroundCount(),
        Manager.BackgroundDirectory()
    ))
    return Manager.Backgrounds
end
function Manager.BackgroundCount()
    return math.max(0,#(Manager.Backgrounds or{})-1)
end
function Manager.BackgroundDirectory()
    return win(Manager.BackgroundDir)
end
function Manager.BackgroundIndex()
    for i,name in ipairs(Manager.BackgroundFiles)do if name==Manager.Settings.Background then return i-1 end end
    return 0
end
function Manager.SetBackgroundIndex(index)
    local name=Manager.BackgroundFiles[(tonumber(index)or 0)+1]or"";return Manager.Set("Background",name,true)
end
function Manager.BackgroundPath()
    for index,name in ipairs(Manager.BackgroundFiles or{})do
        if name==Manager.Settings.Background then
            return Manager.BackgroundPaths and Manager.BackgroundPaths[index]
                or join(Manager.BackgroundDir,name)
        end
    end
    return join(Manager.BackgroundDir,Manager.Settings.Background)
end
local function resolve_background()
    if not Manager.Settings.BackgroundEnabled or Manager.Settings.Background==""then return nil end
    if Manager.BackgroundTexture then return Manager.BackgroundTexture end
    if not Manager.BackgroundTextureId then
        local path=win(Manager.BackgroundPath());local ok,id=pcall(Texture.LoadTextureAsync,path)
        if not ok or type(id)~="number"then return nil end;Manager.BackgroundTextureId=id
    end
    local ok,valid=pcall(Texture.IsTextureValid,Manager.BackgroundTextureId);if not ok or not valid then return nil end
    local got,obj=pcall(Texture.GetTexture,Manager.BackgroundTextureId);if got then Manager.BackgroundTexture=obj end
    return Manager.BackgroundTexture
end
function Manager.DrawBackground(x,y,w,h,radius)
    if not Manager.IsGlass()then return false end
    local obj=resolve_background();if obj then
        local ok,tex=pcall(function()return obj:GetCurrent()end);if ok and tex then
            local tw,th=obj:GetWidth(),obj:GetHeight();local mode=Manager.Settings.BackgroundMode;local scale=Manager.Settings.BackgroundScale/100
            local dw,dh=w,h
            if mode=="contain"then local q=math.min(w/tw,h/th)*scale;dw,dh=tw*q,th*q
            elseif mode=="center"then dw,dh=tw*scale,th*scale
            elseif mode=="cover"then local q=math.max(w/tw,h/th)*scale;dw,dh=tw*q,th*q
            else dw,dh=w*scale,h*scale end
            local dx=x+(w-dw)*0.5+Manager.Settings.BackgroundOffsetX;local dy=y+(h-dh)*0.5+Manager.Settings.BackgroundOffsetY
            local tint=(alpha(Manager.Settings.BackgroundOpacity)<<24)|0xFFFFFF
            local function draw_clip(cx,cy,cw,ch)
                if cw<=0 or ch<=0 then return end
                ImGui.PushClipRect(cx,cy,cx+cw,cy+ch,true)
                ImGui.AddImage(tex,dx,dy,dx+dw,dy+dh,0,0,1,1,tint)
                ImGui.PopClipRect()
            end
            local rounded=math.floor(clamp(radius or 0,0,math.min(w,h)*0.5)+0.5)
            if rounded<=0 then
                draw_clip(x,y,w,h)
            else
                draw_clip(x,y+rounded,w,h-rounded*2)
                local step=4
                for offset=0,rounded-1,step do
                    local strip=math.min(step,rounded-offset)
                    local midpoint=offset+strip*0.5
                    local distance=rounded-midpoint
                    local inset=rounded-math.sqrt(math.max(0,rounded*rounded-distance*distance))
                    draw_clip(x+inset,y+offset,w-inset*2,strip)
                    draw_clip(x+inset,y+h-offset-strip,w-inset*2,strip)
                end
            end
        end
    end
    local value=Manager.Settings.OverlayStyle=="light"and 250 or 16
    local a=math.floor(alpha(Manager.Settings.OverlayOpacity)*Manager.Settings.WindowOpacity/100+0.5)
    ImGui.AddRectFilled(x,y,x+w,y+h,value,value,value,a,radius,0)
    return true
end

function Manager.Init(app)
    App=app;Manager.Settings=copy(defaults);Manager.BaseColors=copy(App.Theme.Current.Colors);Manager.BaseMetrics=copy(App.Theme.Current.Metrics)
    Manager.ThemeRelative=App.Paths.Theme
    Manager.BackgroundRelative=join(Manager.ThemeRelative,"backgrounds")
    Manager.AssetsRelative=join(Manager.ThemeRelative,"assets")
    Manager.ThemeDir=join(App.Loader.LuaRoot,Manager.ThemeRelative)
    Manager.BackgroundDir=join(App.Loader.LuaRoot,Manager.BackgroundRelative)
    Manager.AssetsDir=join(App.Loader.LuaRoot,Manager.AssetsRelative)
    Manager.ConfigPath=join(Manager.ThemeDir,"theme.cfg")
    pcall(FileMgr.CreateDir,Manager.ThemeDir)
    pcall(FileMgr.CreateDir,win(Manager.ThemeDir))
    pcall(FileMgr.CreateDir,Manager.BackgroundDir)
    pcall(FileMgr.CreateDir,win(Manager.BackgroundDir))
    Manager.Load()
    if Manager.Settings.UiMode=="glass"then apply_first_glass_defaults()end
    Manager.RefreshBackgrounds();apply_palette()
    App.Theme.Manager=Manager;return true
end
function Manager.Shutdown(app)
    if app.Theme.Manager==Manager then app.Theme.Manager=nil end
    Manager.BackgroundTexture=nil;Manager.BackgroundTextureId=nil;App=nil
end
return Manager
