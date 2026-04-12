--[[ ================================================
     SPARTA v2 - Roblox Mobile Exploit GUI
     Compatible: Delta (iOS/Android), Synapse X, KRNL
     Author: Sparta Hub
     Keys: 37 | CM | 217
================================================ ]]--

-- ▌ STEP 1: Safe executor API detection (never crashes)
local _has = function(name) return type(_G[name]) == "function" end

local _cloneref         = _has("cloneref") and cloneref or function(x) return x end
local _newcclosure      = _has("newcclosure") and newcclosure or function(x) return x end
local _getrawmetatable  = _has("getrawmetatable") and getrawmetatable or getmetatable
local _setreadonly      = _has("setreadonly") and setreadonly or function() end
local _isreadonly       = _has("isreadonly") and isreadonly or function() return false end
local _gethui           = _has("gethui") and gethui or function() return nil end
local _protect_gui      = (_has("syn") and syn and syn.protect_gui) and syn.protect_gui or function() end
local _setclipboard     = _has("setclipboard") and setclipboard or function() end
local _getrenv          = _has("getrenv") and getrenv or function() return {} end
local _getgenv          = _has("getgenv") and getgenv or function() return _G end

-- ▌ STEP 2: Services (safe-wrapped)
local function getSvc(name)
    local ok, s = pcall(function() return game:GetService(name) end)
    if ok and s then return pcall(function() return _cloneref(s) end) and _cloneref(s) or s end
    return nil
end

local Players           = getSvc("Players")
local RunService        = getSvc("RunService")
local UserInputService  = getSvc("UserInputService")
local TweenService      = getSvc("TweenService")
local Workspace         = getSvc("Workspace") or workspace
local CoreGui           = getSvc("CoreGui")
local Lighting          = getSvc("Lighting")
local VirtualUser       = getSvc("VirtualUser")
local TeleportService   = getSvc("TeleportService")
local HttpService       = getSvc("HttpService")
local SoundService      = getSvc("SoundService")

local Camera = Workspace.CurrentCamera
local lp     = Players.LocalPlayer
local mouse  = lp:GetMouse()

-- ▌ STEP 3: Configuration
local cfg = {
    -- Aim
    SilentAim=false, AimLock=false, AimTeamCheck=true, AimVisibleOnly=false,
    FOVSize=150, Smoothness=35, FOVCircle=true, AimPart="Head",
    Prediction=false, PredictionStrength=40, Multipoint=false,
    -- Trigger
    TriggerBot=false, TriggerTeamCheck=true, TriggerVisible=true,
    TriggerPreDelay=30, TriggerPostDelay=80, TriggerBurst=false, TriggerBurstCount=3,
    TriggerRandomDelay=true, TriggerRandomRange=15, TriggerHeadOnly=false,
    -- KillAura
    KillAura=false, KillAuraTeamCheck=true, KillAuraRange=20, KillAuraRate=8,
    KillAuraClosest=true, KillAuraLowestHP=false, KillAuraVisible=false,
    KillAuraSpin=false, KillAuraSpinSpeed=15, KillAuraRandom=true,
    KillAuraDesync=false, KillAuraJitter=false,
    -- Hitbox
    HitboxExpand=false, HitboxSize=6, HeadExpand=false, HeadSize=5,
    HitboxTeamCheck=true, HitboxShowVisual=false, HitboxOpacity=50,
    -- AutoClick
    AutoClick=false, CPS=14, RandomizeCPS=false, RandomRange=5,
    HoldToClick=true, JitterAim=false, JitterStrength=3, DoubleClick=false,
    -- Speed
    SpeedHack=false, WalkSpeed=50, Sprint=false, SprintMultiplier=2,
    Noclip=false, BunnyHop=false, LongJump=false, LowGravity=false,
    GravityScale=100, SpeedBypass=false,
    -- Fly
    Fly=false, FlySpeed=60, VerticalSpeed=40, AltitudeLock=false,
    LockAltitude=20, FlyNoclip=false, AntiGravity=true,
    SmoothFly=true, CameraRelative=true, FakeWalk=false, FlyCloak=false,
    -- ESP
    PlayerESP=false, BoxESP=false, CornerBox=false, Box3D=false,
    NameESP=true, DistanceESP=true, WeaponESP=false, TeamTag=false,
    HealthBar=true, HealthText=false, ShieldBar=false, Tracers=false,
    Chams=false, SkeletonESP=false, Snapline=false, TeamColor=true,
    HealthColor=false, ESPMaxDist=3000, FadeByDistance=true,
    -- Player
    PlayerSize=false, SizeScale=100, Invisible=false, NoAccessories=false,
    NoClothing=false, SuperStrength=false, KnockbackForce=80,
    GravityHack=false, GravityValue=196, GodMode=false, RegenRate=10,
    NoFallDamage=true, InfiniteJump=false, JumpPower=100,
    NoAnimations=false, SpinPlayer=false,
    -- World
    Fullbright=false, NoFog=false, TimeOfDay=14, NoParticles=false,
    NoClouds=false, RemoveWater=false, TeleportToClick=false,
    TeleportToPlayer=false, ReachModifier=false, ReachDistance=50,
    SpectateMode=false, FreeCam=false,
    -- Weapons
    DamageMultiplier=false, DamageScale=3, OneShot=false,
    NoRecoil=false, NoSpread=false, InfiniteAmmo=false,
    InstantReload=false, FullAuto=false, BulletSpeed=2000,
    NoGravityDrop=false, BulletRange=5000, PierceCount=0,
    MeleeRange=8, MeleeSpeed=100,
    -- Network
    LagSwitch=false, LagDuration=500, LagInterval=3000,
    FakeLag=false, FakePing=100, BlockRemoteLogs=true,
    SpoofPosition=false, RemoteLogger=false, BlockDataStore=false,
    -- Rage
    RageMode=false, RageMaxSpeed=false, RageMaxHitbox=false,
    RageInstantKill=false, RageSpinBot=false, RageFakeLag=false,
    RageAimbot=false, RageSilentAim=false, RageTrigger=false,
    RageKillAura=false, RageGod=false, RageNoFall=true, RageAntiKick=true,
    -- AntiCheat
    AntiKick=true, AntiTeleport=false, AntiScriptKill=true,
    TimingJitter=true, AntiLog=true, AntiRemoteSpy=true,
    AntiScanner=false, IndexBypass=true, CacheRefs=true,
    -- Misc
    AntiAFK=true, AntiAFKInterval=60, ChatSpam=false,
    VehicleBoost=false, VehicleSpeed=500,
    Rejoin=false, UnlockAll=false, NoSwimSlow=false,
}

-- ▌ STEP 4: Jitter helper
local function jit(base)
    return (base or 0.016) * (0.85 + math.random() * 0.3)
end

-- ▌ STEP 5: Character cache
local _char, _hrp, _hum = nil, nil, nil
local function refreshCache()
    _char = lp.Character
    if _char then
        _hrp = _char:FindFirstChild("HumanoidRootPart")
        _hum = _char:FindFirstChildOfClass("Humanoid")
    else
        _hrp, _hum = nil, nil
    end
end
pcall(refreshCache)

-- ▌ STEP 6: Profiles
local profiles = {}
for k, v in pairs(cfg) do profiles[k] = v end

local presets = {
    Default  = {},
    Rage     = {SpeedHack=true,WalkSpeed=200,HitboxExpand=true,HitboxSize=20,GodMode=true,SilentAim=true,KillAura=true,KillAuraRange=60},
    Legit    = {SilentAim=true,FOVSize=80,Smoothness=80,HitboxExpand=true,HitboxSize=3,AntiKick=true},
    Spinbot  = {KillAura=true,KillAuraSpin=true,KillAuraSpinSpeed=30,KillAuraRange=40,GodMode=true},
    Stealth  = {SilentAim=true,FOVSize=60,Smoothness=90,TimingJitter=true,AntiRemoteSpy=true},
}
for k, v in pairs(cfg) do presets.Default[k] = v end

local function applyPreset(name)
    local p = presets[name]
    if not p then return end
    for k, v in pairs(p) do cfg[k] = v end
end
local function exportCfg()
    local ok, j = pcall(function() return HttpService:JSONEncode(cfg) end)
    if ok then pcall(_setclipboard, j) end
end

-- ▌ STEP 7: Color helpers
local rgb  = Color3.fromRGB
local lerp = function(a,b,t) return a+(b-a)*t end

local CHROMA = {
    rgb(255,0,60),rgb(255,100,0),rgb(255,220,0),
    rgb(0,230,80),rgb(0,180,255),rgb(100,0,255),rgb(220,0,255)
}
local _ci, _cf = 1, 0
local function getChroma(off, t)
    local n=#CHROMA; local i=(((_ci-1)+(off or 0))%n)+1; local j=(i%n)+1
    local f=t or _cf; local a,b=CHROMA[i],CHROMA[j]
    return Color3.new(lerp(a.R,b.R,f),lerp(a.G,b.G,f),lerp(a.B,b.B,f))
end

-- ▌ STEP 8: GUI construction helpers
local function tw(obj,props,dur,sty,dir)
    return TweenService:Create(obj,TweenInfo.new(dur or 0.18,sty or Enum.EasingStyle.Quint,dir or Enum.EasingDirection.Out),props)
end

local function corner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function stroke(p,col,t,tr)
    local s=Instance.new("UIStroke",p); s.Color=col or rgb(60,60,80)
    s.Thickness=t or 1; s.Transparency=tr or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; return s
end
local function pad(p,t,b,l,r)
    local u=Instance.new("UIPadding",p)
    u.PaddingTop=UDim.new(0,t or 0); u.PaddingBottom=UDim.new(0,b or 0)
    u.PaddingLeft=UDim.new(0,l or 0); u.PaddingRight=UDim.new(0,r or 0)
end
local function listlayout(p,sp,so,fd)
    local l=Instance.new("UIListLayout",p)
    l.Padding=UDim.new(0,sp or 4)
    l.SortOrder=so or Enum.SortOrder.LayoutOrder
    l.FillDirection=fd or Enum.FillDirection.Vertical
    return l
end

local function mkFrame(parent, bg, pos, sz, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = bg or rgb(14,14,22)
    f.BorderSizePixel = 0
    if pos then f.Position = pos end
    if sz  then f.Size = sz end
    if props then for k,v in pairs(props) do pcall(function() f[k]=v end) end end
    f.Parent = parent
    return f
end

local function mkLabel(parent, txt, sz, font, col, pos, size, xa, ya)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1; l.BorderSizePixel = 0
    l.Text = txt or ""; l.TextSize = sz or 11
    l.Font = font or Enum.Font.GothamMedium
    l.TextColor3 = col or rgb(210,210,225)
    if pos  then l.Position = pos end
    if size then l.Size = size end
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.TextYAlignment = ya or Enum.TextYAlignment.Center
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.RichText = false
    l.Parent = parent
    return l
end

local function mkBtn(parent, txt, sz, font, col, bg, pos, size)
    local b = Instance.new("TextButton")
    b.BackgroundTransparency = bg ~= nil and 0 or 1
    if bg then b.BackgroundColor3 = bg end
    b.BorderSizePixel = 0; b.AutoButtonColor = false
    b.Text = txt or ""; b.TextSize = sz or 11
    b.Font = font or Enum.Font.GothamSemibold
    b.TextColor3 = col or rgb(210,210,225)
    if pos  then b.Position = pos end
    if size then b.Size = size end
    b.Parent = parent
    return b
end

local function mkScroll(parent, pos, sz)
    local sf = Instance.new("ScrollingFrame")
    sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 3
    sf.ScrollBarImageColor3 = rgb(45,45,70)
    sf.CanvasSize = UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    if pos then sf.Position = pos end
    if sz  then sf.Size = sz end
    sf.Parent = parent
    return sf
end

-- Toggle widget
local function mkToggle(parent, pos, default, onChange)
    local W, H = 36, 20
    local ON_COL  = rgb(59,130,246)
    local OFF_COL = rgb(32,32,52)
    local thumbSz = H - 6
    local onPos   = UDim2.new(1,-(thumbSz+3),0.5,-(thumbSz/2))
    local offPos  = UDim2.new(0,3,0.5,-(thumbSz/2))

    local track = mkFrame(parent, default and ON_COL or OFF_COL,
        pos or UDim2.new(1,-(W+8),0.5,-(H/2)), UDim2.new(0,W,0,H))
    corner(track, H)

    local thumb = mkFrame(track, rgb(255,255,255),
        default and onPos or offPos, UDim2.new(0,thumbSz,0,thumbSz))
    corner(thumb, thumbSz)

    local hit = mkBtn(track,"",0,nil,nil,nil,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0))
    hit.BackgroundTransparency = 1

    local state = default == true
    hit.MouseButton1Click:Connect(function()
        state = not state
        if state then
            tw(track,{BackgroundColor3=ON_COL}):Play()
            tw(thumb,{Position=onPos}):Play()
        else
            tw(track,{BackgroundColor3=OFF_COL}):Play()
            tw(thumb,{Position=offPos}):Play()
        end
        pcall(onChange, state)
    end)
    return track, function() return state end
end

-- Slider widget
local function mkSlider(parent, pos, sz, mn, mx, def, suf, onChange)
    local ctn = mkFrame(parent, nil, pos, sz, {BackgroundTransparency=1})
    local TW = sz.X.Offset - 54
    local trackH = 5

    local track = mkFrame(ctn, rgb(32,32,52),
        UDim2.new(0,0,0.5,-(trackH/2)), UDim2.new(0,TW,0,trackH))
    corner(track, trackH)

    local pct0 = math.clamp((def-mn)/(mx-mn),0,1)
    local fill = mkFrame(track, rgb(59,130,246), UDim2.new(0,0,0,0), UDim2.new(pct0,0,1,0))
    corner(fill, trackH)

    local tSz = 13
    local thumb = mkFrame(track, rgb(240,240,255),
        UDim2.new(pct0,-tSz/2,0.5,-tSz/2), UDim2.new(0,tSz,0,tSz))
    corner(thumb, tSz)
    stroke(thumb, rgb(59,130,246), 1.5)

    local valLbl = mkLabel(ctn, tostring(def)..(suf or ""), 10, Enum.Font.GothamBold, rgb(59,130,246),
        UDim2.new(0,TW+4,0,0), UDim2.new(0,50,1,0))

    local value, dragging = def, false

    local function update(absX)
        local tp = track.AbsolutePosition.X
        local ts = track.AbsoluteSize.X
        local p  = math.clamp((absX-tp)/ts,0,1)
        value = math.round(mn + p*(mx-mn))
        fill.Size = UDim2.new(p,0,1,0)
        thumb.Position = UDim2.new(p,-tSz/2,0.5,-tSz/2)
        valLbl.Text = tostring(value)..(suf or "")
        pcall(onChange, value)
    end

    track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true; update(i.Position.X)
        end
    end)
    thumb.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=true
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    return ctn
end

-- Card (toggle or slider)
local function mkCard(parent, order, title, desc, ctype, accentCol, togDef, slMn, slMx, slDf, slSuf, cfgKey)
    local hasDesc = desc and desc ~= ""
    local cardH = ctype == "slider" and 56 or (hasDesc and 46 or 36)

    local card = mkFrame(parent, rgb(16,16,26), nil, UDim2.new(1,-8,0,cardH), {LayoutOrder=order})
    corner(card, 9)
    stroke(card, rgb(28,28,44), 1)

    local xOff = 10
    if ctype == "toggle" and accentCol then
        local bar = mkFrame(card, accentCol, UDim2.new(0,8,0.18,0), UDim2.new(0,2,0.64,0))
        corner(bar, 4)
        xOff = 16
    end

    mkLabel(card, title, 11, Enum.Font.GothamSemibold, rgb(215,215,230),
        UDim2.new(0,xOff, 0, hasDesc and 6 or 0),
        UDim2.new(1,-72, hasDesc and 0 or 1, hasDesc and 0 or 0))

    if hasDesc then
        mkLabel(card, desc, 9, Enum.Font.Gotham, rgb(65,65,95),
            UDim2.new(0,xOff,0,21), UDim2.new(1,-72,0,14))
    end

    if ctype == "toggle" then
        mkToggle(card, nil, togDef, function(v)
            if cfgKey then cfg[cfgKey] = v end
        end)
    elseif ctype == "slider" then
        mkSlider(card,
            UDim2.new(0,xOff,0,34), UDim2.new(0,card.AbsoluteSize.X - xOff - 8, 0, 20),
            slMn, slMx, slDf, slSuf,
            function(v) if cfgKey then cfg[cfgKey] = v end end
        )
    end
    return card
end

local function mkSection(parent, order, title, col)
    local row = mkFrame(parent, nil, nil, UDim2.new(1,-8,0,16), {BackgroundTransparency=1, LayoutOrder=order})
    if col then
        local dot = mkFrame(row, col, UDim2.new(0,3,0.5,-4), UDim2.new(0,8,0,8))
        corner(dot, 8)
    end
    local xO = col and 16 or 5
    mkLabel(row, title:upper(), 8, Enum.Font.GothamBold, rgb(50,50,72), UDim2.new(0,xO,0,0), UDim2.new(1,-xO,1,0))
    return row
end

local function mkBadge(parent, order, text, col)
    local c = col or rgb(59,130,246)
    local row = mkFrame(parent, rgb(13,19,36), nil, UDim2.new(1,-8,0,22), {LayoutOrder=order})
    corner(row, 7)
    stroke(row, rgb(30,50,95), 1)
    mkLabel(row, text, 9, Enum.Font.Gotham, rgb(80,130,230), UDim2.new(0,8,0,0), UDim2.new(1,-8,1,0))
    return row
end

local function mkWarn(parent, order, text)
    local row = mkFrame(parent, rgb(28,22,10), nil, UDim2.new(1,-8,0,22), {LayoutOrder=order})
    corner(row, 7)
    stroke(row, rgb(70,50,15), 1)
    mkLabel(row, "⚠  "..text, 9, Enum.Font.GothamMedium, rgb(200,155,55), UDim2.new(0,8,0,0), UDim2.new(1,-8,1,0))
    return row
end

-- ▌ STEP 9: Create GUI — parent safely for Delta iOS
local gui = Instance.new("ScreenGui")
gui.Name = "Sparta_" .. tostring(math.random(10000,99999))
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999

pcall(_protect_gui, gui)

local guiParented = false
-- Try gethui first (executor protected container)
if not guiParented then
    local h = pcall(function() local hui = _gethui(); if hui then gui.Parent = hui; guiParented = true end end)
end
-- Try CoreGui
if not guiParented then
    pcall(function() gui.Parent = CoreGui; guiParented = gui.Parent == CoreGui end)
end
-- Fallback: PlayerGui (always works on Delta)
if not guiParented then
    gui.Parent = lp:WaitForChild("PlayerGui", 10)
end

-- ▌ STEP 10: Key screen
local LOCK = mkFrame(gui, rgb(5,5,10), UDim2.new(0,0,0,0), UDim2.new(1,0,1,0))

local KF = mkFrame(LOCK, rgb(12,12,20),
    UDim2.new(0.5,-162,0.5,-130), UDim2.new(0,324,0,246))
corner(KF, 14)
stroke(KF, rgb(30,30,52), 1.5)

-- Titlebar
local KT = mkFrame(KF, rgb(7,7,13), UDim2.new(0,0,0,0), UDim2.new(1,0,0,36))
corner(KT, 14)
mkFrame(KF, rgb(7,7,13), UDim2.new(0,0,0,20), UDim2.new(1,0,0,16))

local function macDot(parent, x, col)
    local f = mkFrame(parent, col, UDim2.new(0,x,0.5,-7), UDim2.new(0,14,0,14))
    corner(f, 14)
    local b = mkBtn(f,"",0,nil,nil,nil,UDim2.new(0,0,0,0),UDim2.new(1,0,1,0))
    b.BackgroundTransparency = 1
    return f, b
end

local _, kRedBtn   = macDot(KT, 13, rgb(255,95,87))
local _, kOrgBtn   = macDot(KT, 33, rgb(254,188,46))
local _, kGrnBtn   = macDot(KT, 53, rgb(40,200,64))

mkLabel(KT, "Sparta  ·  Key System", 11, Enum.Font.GothamMedium,
    rgb(75,75,105), UDim2.new(0,78,0,0), UDim2.new(1,-80,1,0))

-- Key body
local keyBody = mkFrame(KF, nil, UDim2.new(0,0,0,36), UDim2.new(1,0,1,-36), {BackgroundTransparency=1})

mkLabel(keyBody, "Unlock Sparta", 15, Enum.Font.GothamBold,
    rgb(215,215,230), UDim2.new(0,0,0,16), UDim2.new(1,0,0,24), Enum.TextXAlignment.Center)
mkLabel(keyBody, "Enter one of the valid passcodes below", 10, Enum.Font.Gotham,
    rgb(60,60,88), UDim2.new(0,0,0,42), UDim2.new(1,0,0,16), Enum.TextXAlignment.Center)

local keyBox = Instance.new("TextBox")
keyBox.Position = UDim2.new(0,16,0,68)
keyBox.Size = UDim2.new(1,-32,0,44)
keyBox.BackgroundColor3 = rgb(20,20,34)
keyBox.TextColor3 = rgb(220,220,240)
keyBox.Font = Enum.Font.Code
keyBox.TextSize = 16
keyBox.PlaceholderText = "Key..."
keyBox.PlaceholderColor3 = rgb(55,55,80)
keyBox.Text = ""
keyBox.BorderSizePixel = 0
keyBox.ClearTextOnFocus = false
keyBox.TextXAlignment = Enum.TextXAlignment.Center
keyBox.Parent = keyBody
corner(keyBox, 10)
local keyStroke = stroke(keyBox, rgb(38,38,62), 1.5)

local keyErr = mkLabel(keyBody, "", 10, Enum.Font.GothamSemibold,
    rgb(255,70,70), UDim2.new(0,0,0,118), UDim2.new(1,0,0,14), Enum.TextXAlignment.Center)

local subBtn = mkBtn(keyBody, "Unlock →", 13, Enum.Font.GothamBold,
    rgb(160,160,200), rgb(22,22,40), UDim2.new(0,16,0,138), UDim2.new(1,-32,0,44))
corner(subBtn, 10)
stroke(subBtn, rgb(45,45,72), 1)

-- Dot hints
mkLabel(keyBody, "Keys:  37  ·  CM  ·  217", 9, Enum.Font.Code,
    rgb(45,45,65), UDim2.new(0,0,0,188), UDim2.new(1,0,0,14), Enum.TextXAlignment.Center)

-- ▌ STEP 11: Main window (hidden until key entered)
local ROOT = mkFrame(gui, rgb(11,11,18),
    UDim2.new(0,16,0,48), UDim2.new(0,510,0,560), {Visible=false})
corner(ROOT, 14)
local rootStroke = stroke(ROOT, rgb(239,68,68), 1.5)

-- Titlebar
local TB = mkFrame(ROOT, rgb(6,6,11), UDim2.new(0,0,0,0), UDim2.new(1,0,0,36))
corner(TB, 14)
mkFrame(ROOT, rgb(6,6,11), UDim2.new(0,0,0,20), UDim2.new(1,0,0,16))

local _, dotRedBtn  = macDot(TB, 13, rgb(255,95,87))
local _, dotOrgBtn  = macDot(TB, 33, rgb(254,188,46))
local _, dotGrnBtn  = macDot(TB, 53, rgb(40,200,64))

local chromaLbl = mkLabel(TB, "Sparta", 12, Enum.Font.GothamBold,
    rgb(239,68,68), UDim2.new(0,76,0,0), UDim2.new(0,55,1,0))
mkLabel(TB, "|", 12, nil, rgb(38,38,58), UDim2.new(0,133,0,0), UDim2.new(0,12,1,0), Enum.TextXAlignment.Center)
local tabTitleLbl = mkLabel(TB, "Aim Assist", 11, Enum.Font.GothamSemibold,
    rgb(239,68,68), UDim2.new(0,147,0,0), UDim2.new(0,130,1,0))
mkLabel(TB, "|", 12, nil, rgb(38,38,58), UDim2.new(1,-66,0,0), UDim2.new(0,12,1,0), Enum.TextXAlignment.Center)
mkLabel(TB, "v2.0", 10, Enum.Font.Code, rgb(40,40,62), UDim2.new(1,-56,0,0), UDim2.new(0,52,1,0), Enum.TextXAlignment.Right)

-- Body
local BODY = mkFrame(ROOT, nil, UDim2.new(0,0,0,36), UDim2.new(1,0,1,-36), {BackgroundTransparency=1})

-- Sidebar
local SIDEBAR = mkFrame(BODY, rgb(7,7,13), UDim2.new(0,0,0,0), UDim2.new(0,158,1,0))
corner(SIDEBAR, 14)
-- Clip bottom-right round corners
mkFrame(SIDEBAR, rgb(7,7,13), UDim2.new(1,-12,0,0), UDim2.new(0,12,1,0))
mkFrame(SIDEBAR, rgb(11,11,18), UDim2.new(1,-1,0,0), UDim2.new(0,1,1,0))

-- Search bar
local searchF = mkFrame(SIDEBAR, rgb(17,17,28),
    UDim2.new(0,7,0,8), UDim2.new(1,-14,0,24))
corner(searchF, 6)
mkLabel(searchF, "  🔍  Search...", 9, Enum.Font.Gotham,
    rgb(45,45,65), UDim2.new(0,0,0,0), UDim2.new(1,0,1,0))

mkLabel(SIDEBAR, "FEATURES", 7.5, Enum.Font.GothamBold,
    rgb(38,38,58), UDim2.new(0,10,0,37), UDim2.new(1,-10,0,12))

local tabListSF = mkScroll(SIDEBAR, UDim2.new(0,5,0,52), UDim2.new(1,-10,1,-110))
listlayout(tabListSF, 2)

-- Content area
local CONTENT = mkFrame(BODY, nil, UDim2.new(0,158,0,0), UDim2.new(1,-158,1,0), {BackgroundTransparency=1, ClipsDescendants=true})

-- Config section at bottom of sidebar
local cfgBtn = mkBtn(SIDEBAR, "⚙  Config & Profiles", 10, Enum.Font.GothamMedium,
    rgb(65,65,95), rgb(13,13,22), UDim2.new(0,7,1,-68), UDim2.new(1,-14,0,28))
corner(cfgBtn, 8)
stroke(cfgBtn, rgb(25,25,40), 1)

local cfgDrop = mkFrame(SIDEBAR, rgb(13,13,22), UDim2.new(0,7,1,-210), UDim2.new(1,-14,0,138))
corner(cfgDrop, 8)
stroke(cfgDrop, rgb(25,25,42), 1)
cfgDrop.Visible = false
listlayout(cfgDrop, 3)
pad(cfgDrop, 5,5,5,5)

local PRESET_COLS = {Default=rgb(59,130,246),Rage=rgb(239,68,68),Legit=rgb(34,197,94),Spinbot=rgb(168,85,247),Stealth=rgb(99,102,241)}
local selectedPreset = "Default"
local presetBtns = {}

for idx, pname in ipairs({"Default","Rage","Legit","Spinbot","Stealth"}) do
    local pc = PRESET_COLS[pname]
    local pb = mkBtn(cfgDrop,"", 0, nil, nil, nil, nil, UDim2.new(1,0,0,22))
    pb.LayoutOrder = idx
    pb.BackgroundTransparency = pname==selectedPreset and 0 or 1
    pb.BackgroundColor3 = rgb(20,20,36)
    corner(pb, 5)
    local dot = mkFrame(pb, pc, UDim2.new(0,5,0.5,-4), UDim2.new(0,8,0,8))
    corner(dot, 8)
    mkLabel(pb, pname, 10, Enum.Font.GothamMedium, pname==selectedPreset and pc or rgb(68,68,98),
        UDim2.new(0,19,0,0), UDim2.new(1,-19,1,0))
    presetBtns[pname] = pb
    pb.MouseButton1Click:Connect(function()
        selectedPreset = pname
        for n2, b2 in pairs(presetBtns) do
            local active = n2==pname
            b2.BackgroundTransparency = active and 0 or 1
            local lbl = b2:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3 = active and PRESET_COLS[n2] or rgb(68,68,98) end
        end
        applyPreset(pname)
    end)
end

local cfgActRow = mkFrame(cfgDrop, nil, nil, UDim2.new(1,0,0,24), {BackgroundTransparency=1, LayoutOrder=10})
listlayout(cfgActRow, 4, nil, Enum.FillDirection.Horizontal)

local function smallBtn(parent, txt, col, order, fn)
    local b = mkBtn(parent, txt, 9, Enum.Font.GothamBold, col, rgb(17,17,30), nil, UDim2.new(0.33,0,1,0))
    b.LayoutOrder = order; corner(b, 5); stroke(b, rgb(28,28,46), 1)
    b.MouseButton1Click:Connect(fn or function() end); return b
end

local saveBtnR = smallBtn(cfgActRow,"Save",rgb(34,197,94),1,function()
    for k,v in pairs(cfg) do presets[selectedPreset][k]=v end
    saveBtnR.Text="✓"; task.delay(1.2, function() saveBtnR.Text="Save" end)
end)
smallBtn(cfgActRow,"Load",rgb(59,130,246),2,function() applyPreset(selectedPreset) end)
smallBtn(cfgActRow,"Copy",rgb(168,85,247),3, exportCfg)

local cfgOpen = false
cfgBtn.MouseButton1Click:Connect(function()
    cfgOpen = not cfgOpen
    cfgDrop.Visible = cfgOpen
    cfgBtn.Position = cfgOpen and UDim2.new(0,7,1,-210+142) or UDim2.new(0,7,1,-68)
    tabListSF.Size = cfgOpen and UDim2.new(1,-10,1,-270) or UDim2.new(1,-10,1,-110)
end)

-- ▌ STEP 12: Tabs definition
local TABS = {
    {id="aim",        label="Aim Assist",  col=rgb(239,68,68)  },
    {id="triggerbot", label="Trigger Bot", col=rgb(6,182,212)  },
    {id="killaura",   label="Kill Aura",   col=rgb(220,38,38)  },
    {id="hitbox",     label="Hitbox",      col=rgb(249,115,22) },
    {id="autoclick",  label="Auto Click",  col=rgb(234,179,8)  },
    {id="speed",      label="Speed",       col=rgb(34,197,94)  },
    {id="fly",        label="Fly",         col=rgb(59,130,246) },
    {id="esp",        label="ESP",         col=rgb(168,85,247) },
    {id="player",     label="Player",      col=rgb(139,92,246) },
    {id="world",      label="World",       col=rgb(20,184,166) },
    {id="weapons",    label="Weapons",     col=rgb(245,158,11) },
    {id="network",    label="Network",     col=rgb(99,102,241) },
    {id="rage",       label="Rage Mode",   col=rgb(185,28,28)  },
    {id="anticheat",  label="Anti-Cheat",  col=rgb(16,185,129) },
    {id="misc",       label="Misc",        col=rgb(236,72,153) },
}

local activeTabId = "aim"
local tabBtns  = {}
local pages    = {}

-- Sidebar tab buttons
for i, tab in ipairs(TABS) do
    local active = tab.id == activeTabId
    local row = mkBtn(tabListSF,"",0,nil,nil,
        active and rgb(20,20,36) or nil, nil, UDim2.new(1,0,0,28))
    row.BackgroundTransparency = active and 0 or 1
    row.LayoutOrder = i
    corner(row, 8)

    local dot = mkFrame(row, tab.col, UDim2.new(0,8,0.5,-5), UDim2.new(0,10,0,10))
    corner(dot, 4)
    mkLabel(row, tab.label, 10, Enum.Font.GothamMedium,
        active and rgb(215,215,235) or rgb(75,75,105),
        UDim2.new(0,24,0,0), UDim2.new(1,-32,1,0))

    tabBtns[tab.id] = row
end

-- Page creation helper
local function newPage(id)
    local sf = mkScroll(CONTENT, UDim2.new(0,0,0,0), UDim2.new(1,0,1,0))
    sf.Visible = id == activeTabId
    listlayout(sf, 4)
    pad(sf, 6, 8, 5, 5)
    pages[id] = sf
    return sf
end

local function switchTab(id)
    for _, tab in ipairs(TABS) do
        local row = tabBtns[tab.id]
        if not row then continue end
        local active = tab.id == id
        row.BackgroundTransparency = active and 0 or 1
        row.BackgroundColor3 = rgb(20,20,36)
        local lbl = row:FindFirstChildOfClass("TextLabel")
        if lbl then lbl.TextColor3 = active and rgb(215,215,235) or rgb(75,75,105) end
        if active then
            tabTitleLbl.Text = tab.label
            tabTitleLbl.TextColor3 = tab.col
            rootStroke.Color = tab.col
        end
    end
    for tid, pg in pairs(pages) do
        pg.Visible = tid == id
        if tid == id then pg.CanvasPosition = Vector2.new(0,0) end
    end
    activeTabId = id
end

for _, tab in ipairs(TABS) do
    local id = tab.id
    tabBtns[id].MouseButton1Click:Connect(function() switchTab(id) end)
end

-- ▌ STEP 13: Build all tab pages
-- Helper shortcuts
local function S(p,n,t,c) n=n+1; mkSection(p,n,t,c); return n end
local function B(p,n,t,c) n=n+1; mkBadge(p,n,t,c); return n end
local function W(p,n,t)   n=n+1; mkWarn(p,n,t); return n end
local function C(p,n,title,desc,ty,ac,def,a,b,d,e,k)
    n=n+1
    local card = newPage and mkCard(p,n,title,desc,ty,ac,def,a,b,d,e,k) and mkCard(p,n,title,desc,ty,ac,def,a,b,d,e,k)
    mkCard(p,n,title,desc,ty,ac,def,a,b,d,e,k)
    return n
end

-- Fix C helper (was wrong)
local function Card(p,n,title,desc,ty,ac,def,a,b,d,e,k)
    n=n+1; mkCard(p,n,title,desc,ty,ac,def,a,b,d,e,k); return n
end

-- AIM
do local p=newPage("aim"); local n=0
    n=S(p,n,"Targeting",rgb(239,68,68))
    n=Card(p,n,"Silent Aim","Warp bullets silently to nearest head","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"SilentAim")
    n=Card(p,n,"Aim Lock","Smooth camera snap onto target","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"AimLock")
    n=Card(p,n,"Team Check","Never target your teammates","toggle",rgb(239,68,68),true,nil,nil,nil,nil,"AimTeamCheck")
    n=Card(p,n,"Visible Only","Skip enemies behind solid walls","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"AimVisibleOnly")
    n=Card(p,n,"Multipoint","Check head, torso, and HRP per target","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"Multipoint")
    n=S(p,n,"FOV & Smoothing",rgb(239,68,68))
    n=B(p,n,"Head-priority · 0.2s tick · Camera smooth",rgb(239,68,68))
    n=Card(p,n,"FOV Radius","Targeting circle radius","slider",nil,nil,10,500,150,"px","FOVSize")
    n=Card(p,n,"Smoothness","Camera lerp speed (higher = faster)","slider",nil,nil,1,100,35,"%","Smoothness")
    n=Card(p,n,"FOV Circle","Render targeting radius on screen","toggle",rgb(239,68,68),true,nil,nil,nil,nil,"FOVCircle")
    n=S(p,n,"Prediction",rgb(239,68,68))
    n=Card(p,n,"Velocity Predict","Lead moving targets","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"Prediction")
    n=Card(p,n,"Prediction Strength","How far ahead to compensate","slider",nil,nil,0,100,40,"%","PredictionStrength")
end

-- TRIGGER BOT
do local p=newPage("triggerbot"); local n=0
    n=S(p,n,"Trigger Bot",rgb(6,182,212))
    n=B(p,n,"Auto-fires when crosshair is over an enemy",rgb(6,182,212))
    n=Card(p,n,"Trigger Bot","Fire on crosshair contact with enemy","toggle",rgb(6,182,212),false,nil,nil,nil,nil,"TriggerBot")
    n=Card(p,n,"Team Check","Skip teammates","toggle",rgb(6,182,212),true,nil,nil,nil,nil,"TriggerTeamCheck")
    n=Card(p,n,"Visible Check","Only fire on visible enemies","toggle",rgb(6,182,212),true,nil,nil,nil,nil,"TriggerVisible")
    n=Card(p,n,"Head Only","Only trigger on head detection","toggle",rgb(6,182,212),false,nil,nil,nil,nil,"TriggerHeadOnly")
    n=S(p,n,"Timing",rgb(6,182,212))
    n=Card(p,n,"Pre-fire Delay","Delay before first shot (ms)","slider",nil,nil,0,500,30,"ms","TriggerPreDelay")
    n=Card(p,n,"Post-fire Delay","Cooldown after each shot (ms)","slider",nil,nil,0,500,80,"ms","TriggerPostDelay")
    n=Card(p,n,"Burst Fire","Fire in short bursts","toggle",rgb(6,182,212),false,nil,nil,nil,nil,"TriggerBurst")
    n=Card(p,n,"Burst Count","Shots per burst","slider",nil,nil,1,10,3," sh","TriggerBurstCount")
    n=S(p,n,"Humanize",rgb(6,182,212))
    n=Card(p,n,"Randomize Delay","Human-like timing variance","toggle",rgb(6,182,212),true,nil,nil,nil,nil,"TriggerRandomDelay")
    n=Card(p,n,"Random Range","Delay variance range","slider",nil,nil,1,50,15,"%","TriggerRandomRange")
end

-- KILL AURA
do local p=newPage("killaura"); local n=0
    n=S(p,n,"Kill Aura",rgb(220,38,38))
    n=B(p,n,"Automatically attacks nearby enemies in range",rgb(220,38,38))
    n=Card(p,n,"Kill Aura","Auto-swing at players in range","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAura")
    n=Card(p,n,"Team Check","Never attack teammates","toggle",rgb(220,38,38),true,nil,nil,nil,nil,"KillAuraTeamCheck")
    n=Card(p,n,"Range","Attack radius in studs","slider",nil,nil,4,80,20," st","KillAuraRange")
    n=Card(p,n,"Attack Rate","Swings per second","slider",nil,nil,1,30,8,"/s","KillAuraRate")
    n=S(p,n,"Targeting",rgb(220,38,38))
    n=Card(p,n,"Closest First","Target nearest player","toggle",rgb(220,38,38),true,nil,nil,nil,nil,"KillAuraClosest")
    n=Card(p,n,"Lowest HP First","Target weakest player","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraLowestHP")
    n=Card(p,n,"Visible Only","Only attack visible enemies","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraVisible")
    n=S(p,n,"Spinbot",rgb(220,38,38))
    n=Card(p,n,"Spin Attack","Rotate while attacking","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraSpin")
    n=Card(p,n,"Spin Speed","Rotation speed","slider",nil,nil,1,60,15," sp","KillAuraSpinSpeed")
    n=S(p,n,"Bypass",rgb(220,38,38))
    n=Card(p,n,"Randomize Timing","Human-like variance","toggle",rgb(220,38,38),true,nil,nil,nil,nil,"KillAuraRandom")
    n=Card(p,n,"Desync","Body-aim desync on swing","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraDesync")
    n=Card(p,n,"Jitter","Micro-movement per swing","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraJitter")
end

-- HITBOX
do local p=newPage("hitbox"); local n=0
    n=S(p,n,"Body Expansion",rgb(249,115,22))
    n=Card(p,n,"Hitbox Expander","Inflate all enemy body hitboxes","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxExpand")
    n=Card(p,n,"Body Size","Body scale multiplier","slider",nil,nil,1,30,6,"×","HitboxSize")
    n=Card(p,n,"Head Expand","Inflate head hitbox separately","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HeadExpand")
    n=Card(p,n,"Head Size","Head scale multiplier","slider",nil,nil,1,25,5,"×","HeadSize")
    n=S(p,n,"Selective",rgb(249,115,22))
    n=Card(p,n,"Team Check","Skip your teammates","toggle",rgb(249,115,22),true,nil,nil,nil,nil,"HitboxTeamCheck")
    n=S(p,n,"Visual",rgb(249,115,22))
    n=Card(p,n,"Show Hitboxes","Render expanded parts visually","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxShowVisual")
    n=Card(p,n,"Hitbox Opacity","Transparency of shown boxes","slider",nil,nil,0,100,50,"%","HitboxOpacity")
end

-- AUTO CLICK
do local p=newPage("autoclick"); local n=0
    n=S(p,n,"Auto Click",rgb(234,179,8))
    n=Card(p,n,"Auto Click","Automatically fire at set CPS","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"AutoClick")
    n=Card(p,n,"CPS","Clicks per second","slider",nil,nil,1,60,14," cps","CPS")
    n=Card(p,n,"Hold to Click","Only fire while touch is held","toggle",rgb(234,179,8),true,nil,nil,nil,nil,"HoldToClick")
    n=S(p,n,"Humanize",rgb(234,179,8))
    n=Card(p,n,"Randomize CPS","Vary timing for human-like pattern","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"RandomizeCPS")
    n=Card(p,n,"Random Range","CPS variance","slider",nil,nil,1,30,5,"%","RandomRange")
    n=Card(p,n,"Double Click","Send two clicks per interval","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"DoubleClick")
    n=S(p,n,"Recoil",rgb(234,179,8))
    n=Card(p,n,"Jitter Aim","Micro-shake per click","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"JitterAim")
    n=Card(p,n,"Jitter Strength","Shake intensity in pixels","slider",nil,nil,1,15,3,"px","JitterStrength")
end

-- SPEED
do local p=newPage("speed"); local n=0
    n=S(p,n,"Movement",rgb(34,197,94))
    n=Card(p,n,"Speed Hack","Override WalkSpeed immediately","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"SpeedHack")
    n=Card(p,n,"Walk Speed","Target walk speed","slider",nil,nil,16,500,50," ws","WalkSpeed")
    n=Card(p,n,"Sprint","Hold sprint for boosted speed","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"Sprint")
    n=Card(p,n,"Sprint Multiplier","Speed while sprinting","slider",nil,nil,1,10,2,"×","SprintMultiplier")
    n=S(p,n,"Physics",rgb(34,197,94))
    n=Card(p,n,"Noclip","Phase through all walls","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"Noclip")
    n=Card(p,n,"Bunny Hop","Auto-jump at velocity peak","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"BunnyHop")
    n=Card(p,n,"Long Jump","Extended horizontal jump","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"LongJump")
    n=Card(p,n,"Low Gravity","Reduce character gravity","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"LowGravity")
    n=Card(p,n,"Gravity Scale","Character gravity %","slider",nil,nil,10,200,100,"%","GravityScale")
end

-- FLY
do local p=newPage("fly"); local n=0
    n=S(p,n,"Flight",rgb(59,130,246))
    n=Card(p,n,"Fly","Freely levitate and move in 3D","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"Fly")
    n=Card(p,n,"Fly Speed","Horizontal flight speed","slider",nil,nil,1,400,60," sp","FlySpeed")
    n=Card(p,n,"Vertical Speed","Up/Down speed","slider",nil,nil,1,250,40," sp","VerticalSpeed")
    n=S(p,n,"Altitude",rgb(59,130,246))
    n=Card(p,n,"Altitude Lock","Lock to a fixed height","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"AltitudeLock")
    n=Card(p,n,"Lock Height","Target altitude in studs","slider",nil,nil,0,500,20," st","LockAltitude")
    n=S(p,n,"Options",rgb(59,130,246))
    n=Card(p,n,"Noclip While Flying","Phase through walls","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"FlyNoclip")
    n=Card(p,n,"Anti-Gravity","Hover when idle","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"AntiGravity")
    n=Card(p,n,"Smooth Fly","Eased acceleration curve","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"SmoothFly")
    n=Card(p,n,"Camera Relative","Move relative to camera","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"CameraRelative")
    n=S(p,n,"Stealth",rgb(59,130,246))
    n=Card(p,n,"Cloak","Invisible while flying","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"FlyCloak")
    n=S(p,n,"Controls",rgb(59,130,246))
    n=B(p,n,"Thumbstick = move  ·  Jump = rise  ·  Crouch = fall",rgb(59,130,246))
end

-- ESP
do local p=newPage("esp"); local n=0
    n=S(p,n,"Player Boxes",rgb(168,85,247))
    n=Card(p,n,"Player ESP","Enable all player overlays","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"PlayerESP")
    n=Card(p,n,"Box ESP","Solid 2D bounding box","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"BoxESP")
    n=Card(p,n,"Corner Box","Stylized L-corner boxes","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"CornerBox")
    n=Card(p,n,"3D Box","Full 3D wireframe box","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Box3D")
    n=S(p,n,"Labels",rgb(168,85,247))
    n=Card(p,n,"Name ESP","Player names above heads","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"NameESP")
    n=Card(p,n,"Distance","Stud distance below name","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"DistanceESP")
    n=Card(p,n,"Weapon Name","Show equipped weapon","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"WeaponESP")
    n=S(p,n,"Health",rgb(168,85,247))
    n=Card(p,n,"Health Bar","Gradient HP bar beside box","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"HealthBar")
    n=Card(p,n,"Health Text","Exact HP number","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"HealthText")
    n=S(p,n,"Overlays",rgb(168,85,247))
    n=Card(p,n,"Tracers","Line from screen edge to feet","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Tracers")
    n=Card(p,n,"Chams","Solid through-wall highlight","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Chams")
    n=Card(p,n,"Skeleton","Bone wireframe rendering","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"SkeletonESP")
    n=Card(p,n,"Snapline","Line from crosshair to target","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Snapline")
    n=S(p,n,"Colors & Range",rgb(168,85,247))
    n=Card(p,n,"Team Color","Color by team","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"TeamColor")
    n=Card(p,n,"Health Color","Box color by HP","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"HealthColor")
    n=Card(p,n,"Max Distance","Render cutoff","slider",nil,nil,50,8000,3000," st","ESPMaxDist")
    n=Card(p,n,"Fade by Distance","Reduce opacity at range","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"FadeByDistance")
end

-- PLAYER
do local p=newPage("player"); local n=0
    n=S(p,n,"Character",rgb(139,92,246))
    n=Card(p,n,"Resize Player","Scale your character size","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"PlayerSize")
    n=Card(p,n,"Size Scale","Character scale %","slider",nil,nil,10,500,100,"%","SizeScale")
    n=Card(p,n,"Invisible","Make character invisible","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"Invisible")
    n=Card(p,n,"No Accessories","Remove all hats","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"NoAccessories")
    n=Card(p,n,"Spin Player","Infinitely rotate character","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"SpinPlayer")
    n=Card(p,n,"No Animations","Freeze animations","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"NoAnimations")
    n=S(p,n,"Physics",rgb(139,92,246))
    n=Card(p,n,"Gravity Override","Change world gravity","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"GravityHack")
    n=Card(p,n,"Gravity Value","Workspace gravity","slider",nil,nil,1,400,196," g","GravityValue")
    n=S(p,n,"Health & Movement",rgb(139,92,246))
    n=Card(p,n,"God Mode","Lock health at max forever","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"GodMode")
    n=Card(p,n,"HP Regen Rate","Passive regen/s","slider",nil,nil,0,200,10," hp","RegenRate")
    n=Card(p,n,"No Fall Damage","Survive any drop","toggle",rgb(139,92,246),true,nil,nil,nil,nil,"NoFallDamage")
    n=Card(p,n,"Infinite Jump","Re-jump mid-air","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"InfiniteJump")
    n=Card(p,n,"Jump Power","Jump force","slider",nil,nil,50,1000,100," jp","JumpPower")
end

-- WORLD
do local p=newPage("world"); local n=0
    n=S(p,n,"Lighting",rgb(20,184,166))
    n=Card(p,n,"Fullbright","Remove all shadows and darkness","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"Fullbright")
    n=Card(p,n,"No Fog","Clear all world fog","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"NoFog")
    n=Card(p,n,"Time of Day","World clock (0–24)","slider",nil,nil,0,24,14,"h","TimeOfDay")
    n=Card(p,n,"No Particles","Disable particle effects","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"NoParticles")
    n=S(p,n,"Teleport",rgb(20,184,166))
    n=Card(p,n,"Teleport to Click","Teleport on screen tap","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"TeleportToClick")
    n=Card(p,n,"Reach Modifier","Extend arm reach","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"ReachModifier")
    n=Card(p,n,"Reach Distance","Arm reach in studs","slider",nil,nil,4,500,50," st","ReachDistance")
    n=S(p,n,"Camera",rgb(20,184,166))
    n=Card(p,n,"Free Cam","Detach camera from character","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"FreeCam")
end

-- WEAPONS
do local p=newPage("weapons"); local n=0
    n=S(p,n,"Damage",rgb(245,158,11))
    n=B(p,n,"Hooks weapon remote events where detected",rgb(245,158,11))
    n=Card(p,n,"Damage Multiplier","Scale outgoing damage","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"DamageMultiplier")
    n=Card(p,n,"Damage Scale","Damage multiplier","slider",nil,nil,1,50,3,"×","DamageScale")
    n=Card(p,n,"One Shot","Kill in single hit","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"OneShot")
    n=S(p,n,"Accuracy",rgb(245,158,11))
    n=Card(p,n,"No Recoil","Remove weapon kick","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"NoRecoil")
    n=Card(p,n,"No Spread","Perfect accuracy","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"NoSpread")
    n=S(p,n,"Ammo",rgb(245,158,11))
    n=Card(p,n,"Infinite Ammo","Never run out","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"InfiniteAmmo")
    n=Card(p,n,"Instant Reload","Reload instantly","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"InstantReload")
    n=Card(p,n,"Full Auto","Force semi-auto → full auto","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"FullAuto")
    n=S(p,n,"Ballistics",rgb(245,158,11))
    n=Card(p,n,"Bullet Speed","Projectile velocity","slider",nil,nil,100,20000,2000," v","BulletSpeed")
    n=Card(p,n,"No Gravity Drop","Disable bullet gravity","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"NoGravityDrop")
    n=Card(p,n,"Melee Range","Melee reach in studs","slider",nil,nil,4,100,8," st","MeleeRange")
end

-- NETWORK
do local p=newPage("network"); local n=0
    n=S(p,n,"Lag Switch",rgb(99,102,241))
    n=W(p,n,"Lag switch may cause desync kicks on some games")
    n=Card(p,n,"Lag Switch","Freeze outgoing packets","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"LagSwitch")
    n=Card(p,n,"Lag Duration","Duration per burst (ms)","slider",nil,nil,100,5000,500,"ms","LagDuration")
    n=Card(p,n,"Lag Interval","Time between bursts (ms)","slider",nil,nil,500,30000,3000,"ms","LagInterval")
    n=Card(p,n,"Fake Lag","Simulate high ping","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"FakeLag")
    n=S(p,n,"Protection",rgb(99,102,241))
    n=Card(p,n,"Block Remote Logs","Drop suspicious server calls","toggle",rgb(99,102,241),true,nil,nil,nil,nil,"BlockRemoteLogs")
    n=Card(p,n,"Remote Logger","Log all remote events","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"RemoteLogger")
end

-- RAGE
do local p=newPage("rage"); local n=0
    n=S(p,n,"Rage Activation",rgb(185,28,28))
    n=W(p,n,"Rage Mode disables stealth — expect detection")
    n=Card(p,n,"Rage Mode","Enable all rage features","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageMode")
    n=S(p,n,"Movement",rgb(185,28,28))
    n=Card(p,n,"Max Speed","WalkSpeed = 200","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageMaxSpeed")
    n=Card(p,n,"Max Hitbox","Hitbox × 20","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageMaxHitbox")
    n=Card(p,n,"Spin Bot","360° body rotation","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageSpinBot")
    n=S(p,n,"Combat",rgb(185,28,28))
    n=Card(p,n,"Snap Aimbot","Instant head-snap aim","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageAimbot")
    n=Card(p,n,"Max Silent Aim","Max-range silent aim","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageSilentAim")
    n=Card(p,n,"Kill Aura 80st","80-stud kill aura","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageKillAura")
    n=Card(p,n,"One-Shot Kill","Instant kill on any hit","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageInstantKill")
    n=S(p,n,"Defense",rgb(185,28,28))
    n=Card(p,n,"God Mode","Invincible","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageGod")
    n=Card(p,n,"No Fall Damage","Survive any fall","toggle",rgb(185,28,28),true,nil,nil,nil,nil,"RageNoFall")
    n=Card(p,n,"Anti-Kick","Block all kicks","toggle",rgb(185,28,28),true,nil,nil,nil,nil,"RageAntiKick")
end

-- ANTI-CHEAT
do local p=newPage("anticheat"); local n=0
    n=S(p,n,"Index Protection",rgb(16,185,129))
    n=B(p,n,"Shields against indexInstance detector & AC systems",rgb(16,185,129))
    n=Card(p,n,"Index Bypass","Hook __index to mask reads","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"IndexBypass")
    n=Card(p,n,"Cache Refs","Store instances to reduce indexing","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"CacheRefs")
    n=S(p,n,"Anti-Kick",rgb(16,185,129))
    n=Card(p,n,"Anti-Kick","Block LocalPlayer:Kick() calls","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiKick")
    n=Card(p,n,"Anti-Teleport","Block unwanted teleports","toggle",rgb(16,185,129),false,nil,nil,nil,nil,"AntiTeleport")
    n=Card(p,n,"Anti-Script-Kill","Protect from termination","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiScriptKill")
    n=S(p,n,"Detection Bypass",rgb(16,185,129))
    n=Card(p,n,"Timing Jitter","Randomize heartbeat intervals","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"TimingJitter")
    n=Card(p,n,"Anti-Log","Suppress AC console output","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiLog")
    n=Card(p,n,"Anti-RemoteSpy","Obfuscate remote signatures","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiRemoteSpy")
    n=Card(p,n,"Anti-Scanner","Detect and disable AC scripts","toggle",rgb(16,185,129),false,nil,nil,nil,nil,"AntiScanner")
end

-- MISC
do local p=newPage("misc"); local n=0
    n=S(p,n,"Player QoL",rgb(236,72,153))
    n=Card(p,n,"Anti AFK","Auto-move to prevent idle kick","toggle",rgb(236,72,153),true,nil,nil,nil,nil,"AntiAFK")
    n=Card(p,n,"AFK Interval","Seconds between AFK prevention","slider",nil,nil,10,300,60,"s","AntiAFKInterval")
    n=S(p,n,"Movement",rgb(236,72,153))
    n=Card(p,n,"No Swim Slow","Swim at full walk speed","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoSwimSlow")
    n=Card(p,n,"Vehicle Boost","Override vehicle MaxSpeed","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"VehicleBoost")
    n=Card(p,n,"Vehicle Speed","Vehicle max speed %","slider",nil,nil,100,5000,500,"%","VehicleSpeed")
    n=S(p,n,"World",rgb(236,72,153))
    n=Card(p,n,"Fullbright","Remove shadows","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"Fullbright")
    n=Card(p,n,"No Fog","Clear world fog","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoFog")
    n=S(p,n,"Utility",rgb(236,72,153))
    n=Card(p,n,"Rejoin","Leave and rejoin current game","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"Rejoin")
    n=Card(p,n,"Unlock All","Unlock all locked doors","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"UnlockAll")
    n=Card(p,n,"No Animations","Freeze character animations","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoAnimations")
end

-- ▌ STEP 14: Window controls
local guiMinimized, sidebarOpen = false, true

dotRedBtn.MouseButton1Click:Connect(function()
    pcall(function() gui:Destroy() end)
end)

dotOrgBtn.MouseButton1Click:Connect(function()
    guiMinimized = not guiMinimized
    if guiMinimized then
        task.spawn(function()
            tw(BODY, {Size=UDim2.new(1,0,0,0)}, 0.18, Enum.EasingStyle.Quint):Play()
            task.wait(0.17)
            BODY.Visible = false
            tw(ROOT, {Size=UDim2.new(0,510,0,36)}, 0.14):Play()
        end)
    else
        task.spawn(function()
            tw(ROOT, {Size=UDim2.new(0,510,0,560)}, 0.2, Enum.EasingStyle.Quint):Play()
            task.wait(0.1)
            BODY.Visible = true
            BODY.Size = UDim2.new(1,0,0,0)
            tw(BODY, {Size=UDim2.new(1,0,1,-36)}, 0.18, Enum.EasingStyle.Quint):Play()
        end)
    end
end)

dotGrnBtn.MouseButton1Click:Connect(function()
    sidebarOpen = not sidebarOpen
    SIDEBAR.Visible = sidebarOpen
    CONTENT.Position = sidebarOpen and UDim2.new(0,158,0,0) or UDim2.new(0,0,0,0)
    CONTENT.Size = sidebarOpen and UDim2.new(1,-158,1,0) or UDim2.new(1,0,1,0)
end)

-- Dragging
local _drag, _dstart, _dpos = false, nil, nil
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        _drag = true; _dstart = i.Position; _dpos = ROOT.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if _drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        if _dstart and _dpos then
            local d = i.Position - _dstart
            ROOT.Position = UDim2.new(_dpos.X.Scale, _dpos.X.Offset+d.X, _dpos.Y.Scale, _dpos.Y.Offset+d.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        _drag = false
    end
end)

-- ▌ STEP 15: Key system logic
local VALID_KEYS = {["37"]=true, ["cm"]=true, ["217"]=true}
local keyCollapsed = false

local function tryUnlock()
    local raw = (keyBox.Text:match("^%s*(.-)%s*$") or ""):lower()
    if VALID_KEYS[raw] then
        tw(LOCK, {BackgroundTransparency=1}, 0.4):Play()
        task.delay(0.4, function()
            LOCK.Visible = false
            ROOT.Visible = true
        end)
    else
        keyErr.Text = "Invalid key — try: 37  CM  217"
        keyStroke.Color = rgb(180,30,30)
        -- Shake
        for _ = 1, 3 do
            tw(KF, {Position=UDim2.new(0.5,-170,0.5,-130)}, 0.04):Play(); task.wait(0.05)
            tw(KF, {Position=UDim2.new(0.5,-154,0.5,-130)}, 0.04):Play(); task.wait(0.05)
        end
        KF.Position = UDim2.new(0.5,-162,0.5,-130)
        task.delay(1.5, function()
            keyErr.Text = ""
            keyStroke.Color = rgb(38,38,62)
        end)
    end
end

subBtn.MouseButton1Click:Connect(tryUnlock)
keyBox.FocusLost:Connect(function(enter) if enter then tryUnlock() end end)

kRedBtn.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)
kOrgBtn.MouseButton1Click:Connect(function()
    keyCollapsed = not keyCollapsed
    if keyCollapsed then
        task.spawn(function()
            tw(keyBody, {Size=UDim2.new(1,0,0,0)}, 0.16):Play(); task.wait(0.14)
            keyBody.Visible = false
            tw(KF, {Size=UDim2.new(0,324,0,36)}, 0.12):Play()
        end)
    else
        task.spawn(function()
            tw(KF, {Size=UDim2.new(0,324,0,246)}, 0.18):Play(); task.wait(0.08)
            keyBody.Visible = true; keyBody.Size = UDim2.new(1,0,0,0)
            tw(keyBody, {Size=UDim2.new(1,0,1,-36)}, 0.15):Play()
        end)
    end
end)
kGrnBtn.MouseButton1Click:Connect(function() end)

-- ▌ STEP 16: Drawing helpers (safe, Delta-compatible)
local drawingOK = pcall(function() local t=Drawing.new("Square"); t:Remove() end)

local function newDraw(dtype, props)
    if not drawingOK then return {Visible=false, Remove=function()end} end
    local ok, d = pcall(Drawing.new, dtype)
    if not ok or not d then return {Visible=false, Remove=function()end} end
    d.Visible = false
    for k,v in pairs(props or {}) do pcall(function() d[k]=v end) end
    return d
end

local function hideDraw(d)
    if d and type(d.Visible) == "boolean" then
        pcall(function() d.Visible = false end)
    end
end

-- ▌ STEP 17: ESP store
local espStore = {}

local function getESPColor(plr)
    if cfg.TeamColor then
        if plr.Team and lp.Team and plr.Team == lp.Team then
            return Color3.new(0.2,1,0.4)
        end
    end
    return Color3.new(1,0.25,0.25)
end

local function w2v(pos)
    local ok, sp, vis, z = pcall(function()
        return Camera:WorldToViewportPoint(pos)
    end)
    if not ok then return Vector2.new(), false, 0 end
    return Vector2.new(sp.X, sp.Y), vis, z
end

local function getOrMakeESP(name)
    if espStore[name] then return espStore[name] end
    local obj = {
        box    = newDraw("Square", {Thickness=1.5, Filled=false}),
        cTL    = newDraw("Line",   {Thickness=2}),
        cTR    = newDraw("Line",   {Thickness=2}),
        cBL    = newDraw("Line",   {Thickness=2}),
        cBR    = newDraw("Line",   {Thickness=2}),
        cTLv   = newDraw("Line",   {Thickness=2}),
        cTRv   = newDraw("Line",   {Thickness=2}),
        cBLv   = newDraw("Line",   {Thickness=2}),
        cBRv   = newDraw("Line",   {Thickness=2}),
        name   = newDraw("Text",   {Size=13, Center=true, Outline=true, OutlineColor=Color3.new()}),
        dist   = newDraw("Text",   {Size=10, Center=true, Outline=true, OutlineColor=Color3.new()}),
        hpBg   = newDraw("Square", {Filled=true, Color=Color3.new()}),
        hpFill = newDraw("Square", {Filled=true}),
        tracer = newDraw("Line",   {Thickness=1}),
        snap   = newDraw("Line",   {Thickness=1, Color=Color3.new(1,1,0)}),
        bones  = {},
    }
    local BONE_PAIRS = {
        {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
        {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
        {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
        {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
        {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    }
    for _,pair in ipairs(BONE_PAIRS) do
        table.insert(obj.bones, {line=newDraw("Line",{Thickness=1}), a=pair[1], b=pair[2]})
    end
    espStore[name] = obj
    return obj
end

local function hideESP(obj)
    if not obj then return end
    for k,v in pairs(obj) do
        if k == "bones" then
            for _,bone in ipairs(v) do pcall(function() bone.line.Visible=false end) end
        elseif type(v)=="userdata" or type(v)=="table" then
            pcall(function() v.Visible=false end)
        end
    end
end

local function clearESP()
    for _,obj in pairs(espStore) do hideESP(obj) end
    espStore = {}
end

-- ▌ STEP 18: Aim target finder
local aimTarget = nil

local function findTarget()
    local hrp = _hrp
    if not hrp then return nil end
    local vp = Camera.ViewportSize
    local center = Vector2.new(vp.X/2, vp.Y/2)
    local bestPart, bestDist = nil, cfg.FOVSize
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == lp then continue end
        if cfg.AimTeamCheck and lp.Team and plr.Team and plr.Team == lp.Team then continue end
        local char = plr.Character
        if not char then continue end
        local phum = char:FindFirstChildOfClass("Humanoid")
        if not phum or phum.Health <= 0 then continue end
        local parts = cfg.Multipoint and {"Head","UpperTorso","HumanoidRootPart"} or {cfg.AimPart or "Head","HumanoidRootPart"}
        for _, pn in ipairs(parts) do
            local part = char:FindFirstChild(pn)
            if not part then continue end
            local tpos = part.Position
            if cfg.Prediction then
                local phrp2 = char:FindFirstChild("HumanoidRootPart")
                if phrp2 then
                    local ok2, vel = pcall(function() return phrp2.Velocity end)
                    if ok2 then tpos = tpos + vel*(cfg.PredictionStrength/500) end
                end
            end
            if cfg.AimVisibleOnly then
                local rp = RaycastParams.new()
                rp.FilterDescendantsInstances = {_char, char}
                rp.FilterType = Enum.RaycastFilterType.Exclude
                local res = Workspace:Raycast(Camera.CFrame.Position,(tpos-Camera.CFrame.Position).Unit*5000,rp)
                if res then continue end
            end
            local sp, onScreen, z = w2v(tpos)
            if not onScreen or z < 0 then continue end
            local d = (sp-center).Magnitude
            if d < bestDist then bestDist=d; bestPart=part end
        end
    end
    return bestPart
end

-- ▌ STEP 19: Feature state
local flyBV, flyBG, flyVel = nil, nil, Vector3.new()
local spinAngle = 0
local _godConn, _jumpConn, _fallConn = nil, nil, nil
local fovCircle = newDraw("Circle", {NumSides=80, Thickness=1.2, Filled=false, Color=Color3.new(1,1,1), Transparency=0.6})
local timers = {aim=0, click=0, trigger=0, aura=0, afk=0, cache=0}

local function stopFly()
    pcall(function() if flyBV then flyBV:Destroy() end end)
    pcall(function() if flyBG then flyBG:Destroy() end end)
    flyBV, flyBG = nil, nil; flyVel = Vector3.new()
    local h = _hum; if h then pcall(function() h.PlatformStand=false end) end
end

local function startFly()
    stopFly()
    local hrp = _hrp; local hum = _hum
    if not hrp or not hum then return end
    pcall(function() hum.PlatformStand = true end)
    flyBV = Instance.new("BodyVelocity"); flyBV.MaxForce=Vector3.new(1e9,1e9,1e9); flyBV.Velocity=Vector3.new()
    flyBV.Name="SpartaBV"; flyBV.Parent=hrp
    flyBG = Instance.new("BodyGyro"); flyBG.MaxTorque=Vector3.new(1e9,1e9,1e9); flyBG.P=6e4; flyBG.D=800
    flyBG.CFrame=hrp.CFrame; flyBG.Name="SpartaBG"; flyBG.Parent=hrp
end

-- ▌ STEP 20: Main heartbeat loop (all features)
local _hbMain = RunService.Heartbeat:Connect(function(dt)
    -- Chroma animation
    _cf = _cf + dt/0.2
    if _cf >= 1 then _cf=_cf-1; _ci=(_ci%#CHROMA)+1 end
    pcall(function() rootStroke.Color=getChroma() end)
    pcall(function() chromaLbl.TextColor3=getChroma(1) end)

    -- Cache refresh (every 0.5s)
    timers.cache = timers.cache + dt
    if timers.cache >= 0.5 then timers.cache=0; pcall(refreshCache) end

    local char = _char; local hrp = _hrp; local hum = _hum

    -- ── Aim ──────────────────────────────────────────────
    timers.aim = timers.aim + dt
    if timers.aim >= jit(0.15) then
        timers.aim = 0
        pcall(function()
            local part = findTarget(); aimTarget = part
            if cfg.AimLock and part then
                local smooth = math.clamp(1-(cfg.Smoothness/100)*0.96, 0.02, 1)
                local tCF = CFrame.new(Camera.CFrame.Position, part.Position)
                Camera.CFrame = Camera.CFrame:Lerp(tCF, smooth)
            end
        end)
    end

    -- FOV circle
    pcall(function()
        if fovCircle and cfg.FOVCircle and (cfg.SilentAim or cfg.AimLock) then
            fovCircle.Visible = true
            fovCircle.Radius  = cfg.FOVSize
            fovCircle.Position = Camera.ViewportSize/2
        elseif fovCircle then
            fovCircle.Visible = false
        end
    end)

    if not char or not hrp or not hum then return end

    -- ── God Mode ─────────────────────────────────────────
    if cfg.GodMode or (cfg.RageMode and cfg.RageGod) then
        if not _godConn then
            pcall(function()
                hum.MaxHealth = math.huge; hum.Health = math.huge
                _godConn = hum.HealthChanged:Connect(function()
                    pcall(function() hum.Health=hum.MaxHealth end)
                end)
            end)
        end
    else
        if _godConn then pcall(function() _godConn:Disconnect() end); _godConn=nil end
    end

    -- ── Infinite Jump ────────────────────────────────────
    if cfg.InfiniteJump then
        if not _jumpConn then
            _jumpConn = hum.StateChanged:Connect(function(_, new)
                if new==Enum.HumanoidStateType.Freefall and cfg.InfiniteJump then
                    task.wait(0.08)
                    pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
                end
            end)
        end
    else
        if _jumpConn then pcall(function() _jumpConn:Disconnect() end); _jumpConn=nil end
    end

    -- ── No Fall Damage ───────────────────────────────────
    local noFall = cfg.NoFallDamage or (cfg.RageMode and cfg.RageNoFall)
    if noFall then
        if not _fallConn then
            local lastHp = hum.Health
            _fallConn = hum.HealthChanged:Connect(function(hp)
                local diff = lastHp - hp; lastHp = hp
                if diff > hum.MaxHealth*0.07 then
                    pcall(function() hum.Health = hum.Health + diff end)
                end
            end)
        end
    else
        if _fallConn then pcall(function() _fallConn:Disconnect() end); _fallConn=nil end
    end

    -- ── Speed ────────────────────────────────────────────
    if cfg.SpeedHack or (cfg.RageMode and cfg.RageMaxSpeed) then
        local ws = (cfg.RageMode and cfg.RageMaxSpeed) and 200 or cfg.WalkSpeed
        pcall(function() hum.WalkSpeed = ws end)
    end

    -- ── Noclip ───────────────────────────────────────────
    if cfg.Noclip then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.CanCollide then
                pcall(function() p.CanCollide = false end)
            end
        end
    end

    -- ── Bunny Hop ────────────────────────────────────────
    if cfg.BunnyHop then
        if hum.FloorMaterial ~= Enum.Material.Air then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end

    -- ── Gravity ──────────────────────────────────────────
    if cfg.GravityHack then
        pcall(function() Workspace.Gravity = cfg.GravityValue end)
    end

    -- ── No Animations ────────────────────────────────────
    if cfg.NoAnimations then
        pcall(function()
            for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
                t:Stop(0)
            end
        end)
    end

    -- ── Invisible ────────────────────────────────────────
    if cfg.Invisible then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                pcall(function() p.LocalTransparencyModifier = 1 end)
            end
        end
    end

    -- ── Hitbox ───────────────────────────────────────────
    if cfg.HitboxExpand or (cfg.RageMode and cfg.RageMaxHitbox) then
        local bSz = (cfg.RageMode and cfg.RageMaxHitbox) and 20 or cfg.HitboxSize
        local hSz = (cfg.RageMode and cfg.RageMaxHitbox) and 20 or cfg.HeadSize
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr==lp then continue end
            if cfg.HitboxTeamCheck and lp.Team and plr.Team and plr.Team==lp.Team then continue end
            local pc = plr.Character
            if not pc then continue end
            local phrp2 = pc:FindFirstChild("HumanoidRootPart")
            if phrp2 then pcall(function() phrp2.Size=Vector3.new(bSz,bSz,bSz); phrp2.Transparency=0.999 end) end
            if cfg.HeadExpand then
                local ph = pc:FindFirstChild("Head")
                if ph then pcall(function() ph.Size=Vector3.new(hSz,hSz,hSz); ph.Transparency=0.999 end) end
            end
        end
    end

    -- ── Fly ──────────────────────────────────────────────
    if cfg.Fly then
        if not flyBV or not flyBG then startFly() end
        if flyBV and flyBG then
            pcall(function()
                hum.PlatformStand = true
                local camCF = Camera.CFrame
                local md = hum.MoveDirection
                local movDir = Vector3.new()
                if md.Magnitude > 0.05 then
                    if cfg.CameraRelative then
                        local fwd = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
                        local rgt = Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
                        if fwd.Magnitude>0.01 then fwd=fwd.Unit end
                        if rgt.Magnitude>0.01 then rgt=rgt.Unit end
                        movDir = (fwd*-md.Z + rgt*md.X)
                        if movDir.Magnitude>0.01 then movDir=movDir.Unit end
                    else movDir = md end
                end
                local ud = 0
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then ud=1 end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then ud=-1 end
                if hum.Jump then ud=math.max(ud,0.8) end

                local tVel = movDir*cfg.FlySpeed + Vector3.new(0,ud*cfg.VerticalSpeed,0)

                if cfg.AltitudeLock and ud==0 and movDir.Magnitude<0.05 then
                    local diff = cfg.LockAltitude - hrp.Position.Y
                    tVel = Vector3.new(0,math.clamp(diff*3,-cfg.VerticalSpeed,cfg.VerticalSpeed),0)
                end

                if cfg.SmoothFly then
                    local f = math.clamp(dt*9,0,1)
                    flyVel = Vector3.new(lerp(flyVel.X,tVel.X,f),lerp(flyVel.Y,tVel.Y,f),lerp(flyVel.Z,tVel.Z,f))
                else flyVel = tVel end

                if cfg.AntiGravity and tVel.Magnitude < 0.5 then
                    flyVel = Vector3.new(flyVel.X*0.85, 0, flyVel.Z*0.85)
                end

                flyBV.Velocity = flyVel
                flyBG.CFrame = camCF
            end)
        end
    else
        if flyBV or flyBG then stopFly() end
    end

    -- ── Fullbright / Lighting ─────────────────────────────
    if cfg.Fullbright then
        pcall(function()
            Lighting.Brightness=2; Lighting.GlobalShadows=false
            Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1)
            Lighting.FogEnd=1e8; Lighting.ClockTime=cfg.TimeOfDay
        end)
    elseif cfg.NoFog then
        pcall(function() Lighting.FogEnd=1e8 end)
    end

    -- ── Auto Click ───────────────────────────────────────
    timers.click = timers.click + dt
    if cfg.AutoClick then
        local cps = cfg.CPS
        if cfg.RandomizeCPS then cps=cps*(0.85+math.random()*0.3) end
        if timers.click >= 1/math.max(cps,0.5) then
            timers.click = 0
            if cfg.JitterAim then
                pcall(function()
                    Camera.CFrame = Camera.CFrame * CFrame.Angles(
                        (math.random()-0.5)*math.rad(cfg.JitterStrength*0.12),
                        (math.random()-0.5)*math.rad(cfg.JitterStrength*0.12), 0)
                end)
            end
            pcall(function()
                VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), Camera.CFrame)
            end)
        end
    end

    -- ── Kill Aura ────────────────────────────────────────
    timers.aura = timers.aura + dt
    local auraOn = cfg.KillAura or (cfg.RageMode and cfg.RageKillAura)
    if auraOn then
        local rate = (cfg.RageMode and cfg.RageKillAura) and 20 or cfg.KillAuraRate
        local interval = (1/math.max(rate,0.5)) * (cfg.KillAuraRandom and (0.8+math.random()*0.4) or 1)
        if timers.aura >= interval then
            timers.aura = 0
            pcall(function()
                local range = (cfg.RageMode and cfg.RageKillAura) and 80 or cfg.KillAuraRange
                local best, bestScore = nil, math.huge
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr==lp then continue end
                    if cfg.KillAuraTeamCheck and lp.Team and plr.Team and plr.Team==lp.Team then continue end
                    local pc = plr.Character
                    if not pc then continue end
                    local ph = pc:FindFirstChildOfClass("Humanoid")
                    if not ph or ph.Health<=0 then continue end
                    local pp = pc:FindFirstChild("HumanoidRootPart")
                    if not pp then continue end
                    local d = (pp.Position-hrp.Position).Magnitude
                    if d>range then continue end
                    local score = cfg.KillAuraLowestHP and ph.Health or d
                    if score < bestScore then bestScore=score; best=plr end
                end
                if best then
                    if cfg.KillAuraSpin or (cfg.RageMode and cfg.RageSpinBot) then
                        spinAngle = spinAngle + cfg.KillAuraSpinSpeed
                        hrp.CFrame = CFrame.new(hrp.Position)*CFrame.Angles(0,math.rad(spinAngle),0)
                    end
                    local bc = best.Character
                    if bc then
                        local bp = bc:FindFirstChild("HumanoidRootPart")
                        if bp then
                            hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(bp.Position.X,hrp.Position.Y,bp.Position.Z))
                            VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), Camera.CFrame)
                        end
                    end
                end
            end)
        end
    end

    -- ── Trigger Bot ──────────────────────────────────────
    timers.trigger = timers.trigger + dt
    if cfg.TriggerBot and timers.trigger >= jit(0.05) then
        timers.trigger = 0
        pcall(function()
            local rp = RaycastParams.new()
            rp.FilterDescendantsInstances = {char}
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local ray = Workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector*2000, rp)
            if not ray then return end
            local hitChar = ray.Instance.Parent
            local ph = hitChar:FindFirstChildOfClass("Humanoid")
            if not ph or ph.Health<=0 then return end
            local hitPlr = Players:GetPlayerFromCharacter(hitChar)
            if not hitPlr or hitPlr==lp then return end
            if cfg.TriggerTeamCheck and lp.Team and hitPlr.Team and hitPlr.Team==lp.Team then return end
            if cfg.TriggerHeadOnly and ray.Instance.Name~="Head" then return end
            local pre = (cfg.TriggerPreDelay/1000) * (cfg.TriggerRandomDelay and (0.85+math.random()*0.3) or 1)
            task.delay(pre, function()
                if not cfg.TriggerBot then return end
                VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), Camera.CFrame)
                if cfg.TriggerBurst then
                    for i=2,cfg.TriggerBurstCount do
                        task.delay((cfg.TriggerPostDelay/1000)*i, function()
                            if not cfg.TriggerBot then return end
                            VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), Camera.CFrame)
                        end)
                    end
                end
            end)
        end)
    end

    -- ── AFK prevention ───────────────────────────────────
    timers.afk = timers.afk + dt
    if cfg.AntiAFK and timers.afk >= cfg.AntiAFKInterval then
        timers.afk = 0
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
            task.wait(0.35)
            VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
        end)
    end

    -- ── Utility ──────────────────────────────────────────
    if cfg.Rejoin then
        cfg.Rejoin = false
        pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
    end
end)

-- ▌ STEP 21: ESP render loop
local _rsESP = RunService.RenderStepped:Connect(function()
    if not cfg.PlayerESP then clearESP(); return end
    local hrp = _hrp
    if not hrp then return end
    local vp = Camera.ViewportSize
    local rendered = {}
    local cX = vp.X/2

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr==lp then continue end
        local pc = plr.Character
        if not pc then continue end
        local ph = pc:FindFirstChildOfClass("Humanoid")
        if not ph then continue end
        local pp = pc:FindFirstChild("HumanoidRootPart")
        if not pp then continue end
        local dist = (pp.Position-hrp.Position).Magnitude
        if dist > cfg.ESPMaxDist then continue end

        local head = pc:FindFirstChild("Head")
        local topPos = head and (head.Position+Vector3.new(0,head.Size.Y/2,0)) or pp.Position+Vector3.new(0,3.5,0)
        local botPos = pp.Position-Vector3.new(0,3.2,0)
        local topSP, topVis, topZ = w2v(topPos)
        local botSP = w2v(botPos)
        if not topVis or topZ<0 then continue end

        rendered[plr.Name] = true
        local obj = getOrMakeESP(plr.Name)
        local espCol = getESPColor(plr)
        local alpha = cfg.FadeByDistance and math.clamp(1-dist/cfg.ESPMaxDist,0.2,1) or 1
        if cfg.HealthColor and ph then
            espCol = Color3.fromHSV(math.clamp(ph.Health/math.max(ph.MaxHealth,1),0,1)*0.33,1,1)
        end

        local bW = math.clamp(60*(1-dist/5000),14,80)
        local bX,bY,bH = topSP.X-bW/2, topSP.Y, math.abs(botSP.Y-topSP.Y)

        -- Box
        if cfg.BoxESP and obj.box then
            pcall(function()
                obj.box.Visible=true; obj.box.Color=espCol; obj.box.Transparency=1-alpha
                obj.box.Position=Vector2.new(bX,bY); obj.box.Size=Vector2.new(bW,bH)
            end)
        elseif obj.box then pcall(function() obj.box.Visible=false end) end

        -- Corner box
        if cfg.CornerBox then
            local cL = math.max(bW*0.22, 6)
            local corners = {
                {obj.cTL,  Vector2.new(bX,bY),       Vector2.new(bX+cL,bY)},
                {obj.cTLv, Vector2.new(bX,bY),       Vector2.new(bX,bY+cL)},
                {obj.cTR,  Vector2.new(bX+bW,bY),    Vector2.new(bX+bW-cL,bY)},
                {obj.cTRv, Vector2.new(bX+bW,bY),    Vector2.new(bX+bW,bY+cL)},
                {obj.cBL,  Vector2.new(bX,bY+bH),    Vector2.new(bX+cL,bY+bH)},
                {obj.cBLv, Vector2.new(bX,bY+bH),    Vector2.new(bX,bY+bH-cL)},
                {obj.cBR,  Vector2.new(bX+bW,bY+bH), Vector2.new(bX+bW-cL,bY+bH)},
                {obj.cBRv, Vector2.new(bX+bW,bY+bH), Vector2.new(bX+bW,bY+bH-cL)},
            }
            for _,c in ipairs(corners) do
                if c[1] then pcall(function()
                    c[1].Visible=true; c[1].Color=espCol; c[1].Transparency=1-alpha
                    c[1].From=c[2]; c[1].To=c[3]
                end) end
            end
        else
            for _,k in ipairs({"cTL","cTR","cBL","cBR","cTLv","cTRv","cBLv","cBRv"}) do
                pcall(function() obj[k].Visible=false end)
            end
        end

        -- Name
        local nameY = bY-16
        if cfg.NameESP and obj.name then
            pcall(function()
                obj.name.Visible=true; obj.name.Color=espCol; obj.name.Transparency=1-alpha
                obj.name.Text=plr.DisplayName~=plr.Name and plr.DisplayName.." ["..plr.Name.."]" or plr.Name
                obj.name.Position=Vector2.new(topSP.X, nameY)
                obj.name.Size=math.clamp(14-dist/250,8,14)
                nameY=nameY-13
            end)
        elseif obj.name then pcall(function() obj.name.Visible=false end) end

        -- Distance
        if cfg.DistanceESP and obj.dist then
            pcall(function()
                obj.dist.Visible=true; obj.dist.Color=Color3.new(0.6,0.6,0.6)
                obj.dist.Text=string.format("[%.0f st]",dist)
                obj.dist.Position=Vector2.new(topSP.X, nameY)
                obj.dist.Size=10
            end)
        elseif obj.dist then pcall(function() obj.dist.Visible=false end) end

        -- Health bar
        if cfg.HealthBar and obj.hpBg and obj.hpFill then
            pcall(function()
                local pct = math.clamp(ph.Health/math.max(ph.MaxHealth,1),0,1)
                local barX = bX-6
                obj.hpBg.Visible=true; obj.hpBg.Position=Vector2.new(barX,bY); obj.hpBg.Size=Vector2.new(4,bH)
                obj.hpFill.Visible=true; obj.hpFill.Color=Color3.fromHSV(pct*0.33,1,1)
                obj.hpFill.Position=Vector2.new(barX,bY+bH*(1-pct)); obj.hpFill.Size=Vector2.new(4,bH*pct)
            end)
        else
            pcall(function() obj.hpBg.Visible=false; obj.hpFill.Visible=false end)
        end

        -- Tracer
        if cfg.Tracers and obj.tracer then
            pcall(function()
                obj.tracer.Visible=true; obj.tracer.Color=espCol; obj.tracer.Transparency=1-(alpha*0.7)
                obj.tracer.From=Vector2.new(cX,vp.Y); obj.tracer.To=Vector2.new(botSP.X,botSP.Y)
            end)
        elseif obj.tracer then pcall(function() obj.tracer.Visible=false end) end

        -- Snapline
        if cfg.Snapline and obj.snap then
            pcall(function()
                obj.snap.Visible=true; obj.snap.From=Vector2.new(cX,vp.Y/2)
                obj.snap.To=Vector2.new(topSP.X,topSP.Y)
            end)
        elseif obj.snap then pcall(function() obj.snap.Visible=false end) end

        -- Skeleton
        if cfg.SkeletonESP then
            for _,bone in ipairs(obj.bones) do
                pcall(function()
                    local pa = pc:FindFirstChild(bone.a); local pb = pc:FindFirstChild(bone.b)
                    if pa and pb then
                        local spA,visA = w2v(pa.Position); local spB,visB = w2v(pb.Position)
                        if visA and visB then
                            bone.line.Visible=true; bone.line.Color=espCol
                            bone.line.Transparency=1-alpha; bone.line.From=spA; bone.line.To=spB
                        else bone.line.Visible=false end
                    else bone.line.Visible=false end
                end)
            end
        else
            for _,bone in ipairs(obj.bones) do pcall(function() bone.line.Visible=false end) end
        end

        -- Chams
        if cfg.Chams then
            for _, part in ipairs(pc:GetDescendants()) do
                if part:IsA("BasePart") and not part:FindFirstChild("_SC") then
                    pcall(function()
                        local sb=Instance.new("SelectionBox"); sb.Name="_SC"
                        sb.Adornee=part; sb.Color3=espCol; sb.LineThickness=0.05
                        sb.SurfaceTransparency=0.65; sb.SurfaceColor3=espCol; sb.Parent=part
                    end)
                end
            end
        else
            for _, part in ipairs(pc:GetDescendants()) do
                if part:IsA("SelectionBox") and part.Name=="_SC" then
                    pcall(function() part:Destroy() end)
                end
            end
        end
    end

    for name, obj in pairs(espStore) do
        if not rendered[name] then hideESP(obj) end
    end
end)

-- ▌ STEP 22: Anti-detection (deferred, non-blocking)
-- Run 2s after GUI is shown so nothing crashes before key screen
task.delay(2, function()
    -- Anti-log
    if cfg.AntiLog then
        pcall(function()
            local renv = _getrenv()
            if type(renv)=="table" then
                rawset(renv,"print",function()end)
                rawset(renv,"warn",function()end)
            end
        end)
    end

    -- Anti-kick via namecall hook on game (safest method)
    if cfg.AntiKick then
        pcall(function()
            local gameMeta = _getrawmetatable(game)
            if not gameMeta then return end
            local origNC = rawget(gameMeta,"__namecall")
            if not origNC then return end
            _setreadonly(gameMeta, false)
            rawset(gameMeta,"__namecall", _newcclosure(function(self, ...)
                local method = table.remove({...},1) or ""
                if type(method)=="string" then
                    local lo = method:lower()
                    if lo=="kick" and cfg.AntiKick then return end
                    if lo=="teleport" and cfg.AntiTeleport then return end
                end
                return origNC(self, method, ...)
            end))
            _setreadonly(gameMeta, true)
        end)
    end

    -- Instance cache (reduce indexing frequency)
    if cfg.CacheRefs then
        task.spawn(function()
            while task.wait(jit(0.5)) do
                pcall(refreshCache)
            end
        end)
    end

    -- Silent aim mouse hook (only if executor supports it)
    if cfg.IndexBypass then
        pcall(function()
            local mouseMeta = _getrawmetatable(mouse)
            if not mouseMeta then return end
            local origIdx = rawget(mouseMeta,"__index")
            if not origIdx then return end
            _setreadonly(mouseMeta, false)
            rawset(mouseMeta,"__index", _newcclosure(function(self, key)
                if cfg.SilentAim and aimTarget then
                    if key=="Hit"    then return CFrame.new(aimTarget.Position) end
                    if key=="Target" then return aimTarget end
                end
                local ok,r = pcall(origIdx, self, key)
                if ok then return r end
            end))
            _setreadonly(mouseMeta, true)
        end)
    end

    -- AC script scanner
    if cfg.AntiScanner then
        local function scanAC()
            pcall(function()
                for _, desc in ipairs(Workspace:GetDescendants()) do
                    if desc:IsA("Script") or desc:IsA("LocalScript") then
                        local n2 = desc.Name:lower()
                        if n2:find("anticheat") or n2:find("detector") or n2:find("ban") or n2:find("kick_") then
                            pcall(function() desc.Disabled=true end)
                        end
                    end
                end
            end)
        end
        scanAC(); task.delay(5, scanAC); task.delay(15, scanAC)
    end
end)

-- ▌ STEP 23: Character events
lp.CharacterAdded:Connect(function(newChar)
    _char=newChar
    _hrp=newChar:WaitForChild("HumanoidRootPart",5)
    _hum=newChar:WaitForChild("Humanoid",5)
    _godConn=nil; _jumpConn=nil; _fallConn=nil
    flyBV=nil; flyBG=nil; flyVel=Vector3.new()
    task.wait(0.3)
    if cfg.GodMode and _hum then
        pcall(function() _hum.MaxHealth=math.huge; _hum.Health=math.huge end)
    end
    if cfg.NoAccessories then
        for _, acc in ipairs(newChar:GetChildren()) do
            if acc:IsA("Accessory") then pcall(function() acc:Destroy() end) end
        end
    end
end)

lp.CharacterRemoving:Connect(function()
    stopFly(); clearESP()
    _char=nil; _hrp=nil; _hum=nil
    _godConn=nil; _jumpConn=nil; _fallConn=nil
end)

-- Done — GUI is showing the key screen
