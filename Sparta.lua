local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local CoreGui         = game:GetService("CoreGui")
local Lighting        = game:GetService("Lighting")
local Stats           = game:GetService("Stats")

local LP  = Players.LocalPlayer
local Cam = workspace.CurrentCamera
local Mouse = LP:GetMouse()
local Char = LP.Character or LP.CharacterAdded:Wait()

local T = {
    BG          = Color3.fromRGB(10,  10,  16),
    Surface     = Color3.fromRGB(18,  18,  28),
    Card        = Color3.fromRGB(24,  24,  38),
    CardHover   = Color3.fromRGB(32,  32,  50),
    Border      = Color3.fromRGB(40,  40,  62),
    Text        = Color3.fromRGB(235, 235, 250),
    SubText     = Color3.fromRGB(120, 120, 150),
    Accent      = Color3.fromRGB(108, 70,  255),
    AccentDim   = Color3.fromRGB(70,  45,  180),
    Green       = Color3.fromRGB(60,  210, 130),
    Red         = Color3.fromRGB(220, 65,  75),
    Yellow      = Color3.fromRGB(255, 200, 60),
    White       = Color3.fromRGB(255, 255, 255),
    Black       = Color3.fromRGB(0,   0,   0),
    ToggleOff   = Color3.fromRGB(40,  40,  58),
    Font        = Enum.Font.GothamBold,
    FontMed     = Enum.Font.Gotham,
    FontLight   = Enum.Font.Gotham,
    Corner      = UDim.new(0, 13),
    CornerSm    = UDim.new(0, 9),
    CornerXs    = UDim.new(0, 6),
}

local S = {
    ChromeHue      = 0,
    ChromeSpeed    = 4,
    GUIOpacity     = 1,
    ActiveTab      = "Player",
    Collapsed      = false,
    GUIVisible     = true,
    SpeedOn        = false, SpeedVal     = 24,
    JumpOn         = false, JumpVal      = 50,
    InfJumpOn      = false,
    GodOn          = false,
    HealOn         = false, HealRate     = 8,
    SuperJumpOn    = false, SuperJumpVal = 200,
    AntiSlipOn     = false,
    FlyOn          = false, FlySpeed     = 60,
    NoclipOn       = false,
    SuperSpeed     = false, SuperSpeedVal= 300,
    FreeCamOn      = false,
    NoFallOn       = false,
    ESPOn          = false,
    FullbrightOn   = false,
    NoFogOn        = false,
    WireframeOn    = false,
    SpinOn         = false, SpinVal      = 8,
    SkyboxOn       = false,
    FOVVal         = 70,
    HitboxOn       = false, HitboxVal    = 6,
    SilentAimOn    = false,
    AutoClickOn    = false, AutoClickCPS = 10,
    ReachOn        = false, ReachVal     = 10,
    AntiAimOn      = false,
    AntiAFKOn      = false,
    ChromeSpeedVal = 4,
    NotifQueue     = {},
    Connections    = {},
}

local function getHue(offset)
    return Color3.fromHSV((S.ChromeHue + (offset or 0)) % 1, 0.9, 1)
end

local function lerp(a, b, t) return a + (b - a) * t end

local function spring(frame, prop, target, speed, damp)
    speed = speed or 20
    damp  = damp  or 1
    local tw = TweenService:Create(frame,
        TweenInfo.new(speed == 20 and 0.2 or (1/speed), Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {[prop] = target})
    tw:Play()
    return tw
end

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or T.Corner
    c.Parent = parent
    return c
end

local function addPad(parent, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.Parent = parent
    return p
end

local function addStroke(parent, thick, color)
    local s = Instance.new("UIStroke")
    s.Thickness = thick or 1.5
    s.Color = color or T.Border
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function addListLayout(parent, dir, pad, align)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, pad or 0)
    l.HorizontalAlignment = align or Enum.HorizontalAlignment.Left
    l.Parent = parent
    return l
end

local function addGradient(parent, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c0 or T.Surface, c1 or T.Card)
    g.Rotation = rot or 90
    g.Parent = parent
    return g
end

local function newFrame(parent, size, pos, bg, name)
    local f = Instance.new("Frame")
    f.Size = size or UDim2.new(1,0,1,0)
    f.Position = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3 = bg or T.Card
    f.BorderSizePixel = 0
    f.Name = name or "Frame"
    f.Parent = parent
    return f
end

local function newLabel(parent, txt, size, pos, tsz, font, align, color)
    local l = Instance.new("TextLabel")
    l.Size = size or UDim2.new(1,0,1,0)
    l.Position = pos or UDim2.new(0,0,0,0)
    l.BackgroundTransparency = 1
    l.Text = txt or ""
    l.TextSize = tsz or 13
    l.Font = font or T.FontMed
    l.TextColor3 = color or T.Text
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local Connections = {}
local function conn(c) table.insert(Connections, c) end
local function cleanConns()
    for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
    Connections = {}
end

local function applySpeed()
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.WalkSpeed = S.SpeedOn and S.SpeedVal or 16
end

local function applyJump()
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.JumpPower = S.JumpOn and S.JumpVal or 50
end

conn(UserInputService.JumpRequest:Connect(function()
    if not S.InfJumpOn then return end
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    h:ChangeState(Enum.HumanoidStateType.Jumping)
end))

local godConn
local function setupGod()
    if godConn then godConn:Disconnect(); godConn = nil end
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    if S.GodOn then
        godConn = h.HealthChanged:Connect(function()
            if S.GodOn then h.Health = h.MaxHealth end
        end)
    end
end

conn(RunService.Heartbeat:Connect(function(dt)
    if not S.HealOn then return end
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.Health = math.min(h.Health + S.HealRate * dt, h.MaxHealth)
end))

conn(RunService.Heartbeat:Connect(function()
    if not S.AntiSlipOn then return end
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CustomPhysicalProperties = PhysicalProperties.new(0.3,0,0.5,0,0.5)
        end
    end
end))

conn(RunService.Heartbeat:Connect(function()
    if not S.NoFallOn then return end
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    h:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
end))

conn(RunService.Heartbeat:Connect(function()
    if not S.SpinOn then return end
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(S.SpinVal), 0)
end))

local flyBV, flyBG, flyRunConn
local function startFly()
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if not h then return end
    h.PlatformStand = true
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e7,1e7,1e7); flyBV.Velocity = Vector3.zero; flyBV.Parent = root
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e7,1e7,1e7); flyBG.P = 1e5; flyBG.CFrame = root.CFrame; flyBG.Parent = root
    flyRunConn = RunService.Heartbeat:Connect(function()
        if not S.FlyOn then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.new(0,1,0) end
        flyBV.Velocity = (dir.Magnitude > 0 and dir.Unit or dir) * S.FlySpeed
        flyBG.CFrame   = Cam.CFrame
    end)
end

local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV = nil end
    if flyBG then flyBG:Destroy(); flyBG = nil end
    if flyRunConn then flyRunConn:Disconnect(); flyRunConn = nil end
    local char = LP.Character; if not char then return end
    local h = char:FindFirstChildOfClass("Humanoid"); if h then h.PlatformStand = false end
end

local noclipConn
local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        if not S.NoclipOn then return end
        local char = LP.Character; if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = LP.Character; if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = true end
    end
end
startNoclip()

local savedLighting = {}
local function applyFullbright()
    if S.FullbrightOn then
        savedLighting.Brightness = Lighting.Brightness
        savedLighting.ClockTime  = Lighting.ClockTime
        savedLighting.Ambient    = Lighting.Ambient
        Lighting.Brightness = 5
        Lighting.ClockTime  = 14
        Lighting.Ambient    = Color3.fromRGB(178,178,178)
    else
        Lighting.Brightness = savedLighting.Brightness or 1
        Lighting.ClockTime  = savedLighting.ClockTime  or 14
        Lighting.Ambient    = savedLighting.Ambient    or Color3.fromRGB(127,127,127)
    end
end

local function applyNoFog()
    Lighting.FogEnd   = S.NoFogOn and 999999 or (savedLighting.FogEnd   or 100000)
    Lighting.FogStart = S.NoFogOn and 999999 or (savedLighting.FogStart or 0)
end

local ESPHighlights = {}
local function makeESP(player)
    if player == LP then return end
    local hl = Instance.new("Highlight")
    hl.Name = "_SpartaESP"
    hl.FillColor = Color3.fromRGB(255, 80, 80)
    hl.OutlineColor = Color3.fromRGB(255,255,255)
    hl.FillTransparency = 0.6
    hl.OutlineTransparency = 0
    local function attach()
        if player.Character then
            hl.Adornee = player.Character
            hl.Parent  = player.Character
        end
    end
    attach()
    conn(player.CharacterAdded:Connect(attach))
    ESPHighlights[player] = hl
end

local function enableESP()
    for _, p in ipairs(Players:GetPlayers()) do makeESP(p) end
    conn(Players.PlayerAdded:Connect(function(p) if S.ESPOn then makeESP(p) end end))
end

local function disableESP()
    for _, hl in pairs(ESPHighlights) do pcall(function() hl:Destroy() end) end
    ESPHighlights = {}
end

local function applyHitbox()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root and S.HitboxOn then
                root.Size = Vector3.new(S.HitboxVal, S.HitboxVal, S.HitboxVal)
                root.Transparency = 0.8
            elseif root then
                root.Size = Vector3.new(2,2,1)
                root.Transparency = 1
            end
        end
    end
end

local autoClickConn
local autoClickAccum = 0
local function startAutoClick()
    if autoClickConn then autoClickConn:Disconnect() end
    autoClickConn = RunService.Heartbeat:Connect(function(dt)
        if not S.AutoClickOn then return end
        autoClickAccum += dt
        local interval = 1 / S.AutoClickCPS
        if autoClickAccum >= interval then
            autoClickAccum = 0
            local vInput = game:GetService("VirtualInputManager")
            if vInput then
                vInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 0)
                vInput:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 0)
            end
        end
    end)
end

local antiAFKConn
local afkTick = 0
local function startAntiAFK()
    if antiAFKConn then antiAFKConn:Disconnect() end
    antiAFKConn = RunService.Heartbeat:Connect(function(dt)
        if not S.AntiAFKOn then return end
        afkTick += dt
        if afkTick >= 60 then
            afkTick = 0
            LP:Move(Vector3.new(0,0,0))
        end
    end)
end
startAntiAFK()

conn(LP.CharacterAdded:Connect(function(c)
    Char = c
    task.wait(0.8)
    applySpeed(); applyJump(); setupGod()
    if S.FlyOn then startFly() end
end))

if CoreGui:FindFirstChild("SpartaV3") then
    CoreGui:FindFirstChild("SpartaV3"):Destroy()
end

local SG = Instance.new("ScreenGui")
SG.Name = "SpartaV3"
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.ResetOnSpawn    = false
SG.IgnoreGuiInset  = true
SG.Parent          = CoreGui

local W, H = 340, 520

local MF = newFrame(SG, UDim2.new(0,W,0,H), UDim2.new(0.5,-W/2,0.5,-H/2), T.BG, "Main")
addCorner(MF, T.Corner)
addGradient(MF, Color3.fromRGB(12,10,22), Color3.fromRGB(8,8,14), 135)

local ChromeStroke = addStroke(MF, 2, getHue(0))
ChromeStroke.LineJoinMode = Enum.LineJoinMode.Round

local Glow = Instance.new("ImageLabel")
Glow.Size = UDim2.new(1,60,1,60)
Glow.Position = UDim2.new(0,-30,0,-30)
Glow.BackgroundTransparency = 1
Glow.Image = "rbxassetid://5554236805"
Glow.ImageColor3 = T.Accent
Glow.ImageTransparency = 0.72
Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(23,23,277,277)
Glow.ZIndex = 0
Glow.Parent = MF

local TB = newFrame(MF, UDim2.new(1,0,0,52), nil, T.Surface, "TitleBar")
addCorner(TB, T.Corner)
addGradient(TB, Color3.fromRGB(22,18,40), Color3.fromRGB(14,12,26), 135)

local TBFill = newFrame(TB, UDim2.new(1,0,0,14), UDim2.new(0,0,1,-14), T.Surface)
addGradient(TBFill, Color3.fromRGB(14,12,26), Color3.fromRGB(14,12,26), 0)

local Icon = newFrame(TB, UDim2.new(0,34,0,34), UDim2.new(0,10,0.5,-17), T.Accent, "Icon")
addCorner(Icon, UDim.new(0,9))
addGradient(Icon, Color3.fromRGB(130,80,255), Color3.fromRGB(80,40,200), 135)

local IconTxt = newLabel(Icon, "⚔", UDim2.new(1,0,1,0), nil, 18, T.Font, Enum.TextXAlignment.Center, T.White)
IconTxt.TextYAlignment = Enum.TextYAlignment.Center

local TitleTxt = newLabel(TB, "SPARTA", UDim2.new(0,140,0,22), UDim2.new(0,52,0,8), 18, T.Font, Enum.TextXAlignment.Left, T.White)
local SubTxt   = newLabel(TB, "Elite Executor Suite", UDim2.new(0,160,0,14), UDim2.new(0,52,1,-20), 10, T.FontLight, Enum.TextXAlignment.Left, T.SubText)

local FPSLabel  = newLabel(TB, "60 FPS", UDim2.new(0,60,0,14), UDim2.new(1,-150,0,10), 10, T.FontMed, Enum.TextXAlignment.Right, T.Green)
local PingLabel = newLabel(TB, "-- ms",  UDim2.new(0,60,0,14), UDim2.new(1,-150,1,-22), 10, T.FontMed, Enum.TextXAlignment.Right, T.SubText)

local ColBtn = Instance.new("TextButton")
ColBtn.Size = UDim2.new(0,34,0,34); ColBtn.Position = UDim2.new(1,-80,0.5,-17)
ColBtn.BackgroundColor3 = T.Card; ColBtn.Text = "–"
ColBtn.TextColor3 = T.SubText; ColBtn.TextSize = 18; ColBtn.Font = T.Font
ColBtn.BorderSizePixel = 0; ColBtn.Parent = TB
addCorner(ColBtn, T.CornerXs)

local ClsBtn = Instance.new("TextButton")
ClsBtn.Size = UDim2.new(0,34,0,34); ClsBtn.Position = UDim2.new(1,-40,0.5,-17)
ClsBtn.BackgroundColor3 = T.Red; ClsBtn.Text = "✕"
ClsBtn.TextColor3 = T.White; ClsBtn.TextSize = 14; ClsBtn.Font = T.Font
ClsBtn.BorderSizePixel = 0; ClsBtn.Parent = TB
addCorner(ClsBtn, T.CornerXs)
addGradient(ClsBtn, Color3.fromRGB(230,60,70), Color3.fromRGB(180,40,50), 135)

local TabNames = {"Player","Movement","Visual","Combat","Exploits","Settings"}
local TabIcons = {"👤","🚀","👁","⚔","🔧","⚙"}

local TabScroll = Instance.new("ScrollingFrame")
TabScroll.Size = UDim2.new(1,-16,0,42); TabScroll.Position = UDim2.new(0,8,0,56)
TabScroll.BackgroundColor3 = T.Surface; TabScroll.BorderSizePixel = 0
TabScroll.ScrollBarThickness = 0; TabScroll.ScrollingDirection = Enum.ScrollingDirection.X
TabScroll.CanvasSize = UDim2.new(0, #TabNames*78, 1, 0)
TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
TabScroll.Parent = MF
addCorner(TabScroll, UDim.new(0,10))

addListLayout(TabScroll, Enum.FillDirection.Horizontal, 5)
addPad(TabScroll, 5,5,5,5)

local TabBtns = {}; local Pages = {}

local function setTab(name)
    S.ActiveTab = name
    for _, t in ipairs(TabNames) do
        local btn = TabBtns[t]
        if not btn then continue end
        if t == name then
            spring(btn, "BackgroundColor3", T.Accent, 12)
            spring(btn.TextLabel, "TextColor3", T.White, 12)
        else
            spring(btn, "BackgroundColor3", T.Card, 12)
            spring(btn.TextLabel, "TextColor3", T.SubText, 12)
        end
        if Pages[t] then Pages[t].Visible = (t == name) end
    end
end

for i, tname in ipairs(TabNames) do
    local btn = Instance.new("TextButton")
    btn.Name = tname; btn.Size = UDim2.new(0,70,1,0)
    btn.BackgroundColor3 = (tname == S.ActiveTab) and T.Accent or T.Card
    btn.Text = ""; btn.BorderSizePixel = 0; btn.LayoutOrder = i; btn.Parent = TabScroll
    addCorner(btn, UDim.new(0,8))

    local lbl = Instance.new("TextLabel")
    lbl.Name = "TextLabel"; lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = (TabIcons[i] or "") .. " " .. tname
    lbl.TextSize = 11; lbl.Font = T.Font
    lbl.TextColor3 = (tname == S.ActiveTab) and T.White or T.SubText
    lbl.Parent = btn

    btn.MouseButton1Click:Connect(function() setTab(tname) end)
    TabBtns[tname] = btn
end

local ContentY = 106
local ContentH = H - ContentY - 32

local Content = newFrame(MF, UDim2.new(1,-16,0,ContentH), UDim2.new(0,8,0,ContentY), Color3.fromRGB(0,0,0,0), "Content")
Content.BackgroundTransparency = 1

local function makePage()
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = T.Accent
    scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = Content
    addListLayout(scroll, Enum.FillDirection.Vertical, 7)
    addPad(scroll, 0, 6, 4, 12)
    return scroll
end

local function Section(parent, txt, order)
    local row = newFrame(parent, UDim2.new(1,0,0,20), nil, Color3.fromRGB(0,0,0,0))
    row.BackgroundTransparency = 1; row.LayoutOrder = order or 0
    newFrame(row, UDim2.new(0.22,0,0,1), UDim2.new(0,0,0.5,-0.5), T.Border)
    newLabel(row, txt:upper(), UDim2.new(0.56,0,1,0), UDim2.new(0.22,0,0,0), 9, T.Font, Enum.TextXAlignment.Center, T.SubText)
    newFrame(row, UDim2.new(0.22,0,0,1), UDim2.new(0.78,0,0.5,-0.5), T.Border)
    return row
end

local function Toggle(parent, label, desc, default, order, cb)
    local card = newFrame(parent, UDim2.new(1,0,0,52), nil, T.Card, "Toggle_"..label)
    card.LayoutOrder = order
    addCorner(card, T.CornerSm)
    addStroke(card, 1, T.Border)
    local accentBar = newFrame(card, UDim2.new(0,3,0.6,0), UDim2.new(0,0,0.2,0), T.Accent)
    addCorner(accentBar, UDim.new(0,2))
    newLabel(card, label, UDim2.new(1,-80,0,20), UDim2.new(0,14,0,8),  14, T.Font,      Enum.TextXAlignment.Left, T.Text)
    newLabel(card, desc,  UDim2.new(1,-80,0,14), UDim2.new(0,14,1,-20), 10, T.FontLight, Enum.TextXAlignment.Left, T.SubText)
    local pill = newFrame(card, UDim2.new(0,48,0,26), UDim2.new(1,-62,0.5,-13), default and T.Green or T.ToggleOff)
    addCorner(pill, UDim.new(1,0))
    addStroke(pill, 1, T.Border)
    local knob = newFrame(pill, UDim2.new(0,20,0,20), default and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10), T.White)
    addCorner(knob, UDim.new(1,0))
    local isOn = default
    local function set(v)
        isOn = v
        spring(pill, "BackgroundColor3", isOn and T.Green or T.ToggleOff, 15)
        spring(knob, "Position", isOn and UDim2.new(1,-23,0.5,-10) or UDim2.new(0,3,0.5,-10), 15)
        spring(accentBar, "BackgroundColor3", isOn and T.Green or T.Accent, 15)
        if cb then cb(isOn) end
    end
    local clickArea = Instance.new("TextButton")
    clickArea.Size = UDim2.new(1,0,1,0); clickArea.BackgroundTransparency = 1
    clickArea.Text = ""; clickArea.Parent = card
    clickArea.MouseButton1Click:Connect(function() set(not isOn) end)
    clickArea.MouseEnter:Connect(function() spring(card, "BackgroundColor3", T.CardHover, 15) end)
    clickArea.MouseLeave:Connect(function() spring(card, "BackgroundColor3", T.Card, 15) end)
    return card, set
end

local function Slider(parent, label, min, max, default, order, cb, suffix)
    suffix = suffix or ""
    local card = newFrame(parent, UDim2.new(1,0,0,62), nil, T.Card, "Slider_"..label)
    card.LayoutOrder = order
    addCorner(card, T.CornerSm)
    addStroke(card, 1, T.Border)
    newLabel(card, label, UDim2.new(0.65,0,0,20), UDim2.new(0,14,0,8), 13, T.Font, Enum.TextXAlignment.Left, T.Text)
    local valLbl = newLabel(card, tostring(default)..suffix, UDim2.new(0.35,-14,0,20), UDim2.new(0.65,0,0,8), 13, T.Font, Enum.TextXAlignment.Right, T.Accent)
    local track = newFrame(card, UDim2.new(1,-28,0,6), UDim2.new(0,14,1,-18), T.Surface)
    addCorner(track, UDim.new(1,0))
    local pct = (default - min) / (max - min)
    local fill = newFrame(track, UDim2.new(pct,0,1,0), nil, T.Accent)
    addCorner(fill, UDim.new(1,0))
    addGradient(fill, Color3.fromRGB(140,90,255), Color3.fromRGB(90,50,200), 0)
    local knob = newFrame(track, UDim2.new(0,18,0,18), UDim2.new(pct,-9,0.5,-9), T.White)
    addCorner(knob, UDim.new(1,0)); knob.ZIndex = 5
    addStroke(knob, 1.5, T.Accent)
    local dragging = false
    local function update(x)
        local abs = track.AbsolutePosition.X
        local sz  = track.AbsoluteSize.X
        local r   = math.clamp((x - abs) / sz, 0, 1)
        local v   = math.floor(min + r*(max-min) + 0.5)
        fill.Size = UDim2.new(r, 0, 1, 0)
        knob.Position = UDim2.new(r, -9, 0.5, -9)
        valLbl.Text = tostring(v) .. suffix
        if cb then cb(v) end
    end
    local hitArea = Instance.new("TextButton")
    hitArea.Size = UDim2.new(1,0,1,14); hitArea.Position = UDim2.new(0,0,0,-7)
    hitArea.BackgroundTransparency = 1; hitArea.Text = ""; hitArea.ZIndex = 4
    hitArea.Parent = track
    hitArea.MouseButton1Down:Connect(function(x) dragging = true; update(x) end)
    conn(UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            update(inp.Position.X)
        end
    end))
    conn(UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
    return card
end

local function Button(parent, label, desc, btnText, order, cb, color)
    local card = newFrame(parent, UDim2.new(1,0,0,52), nil, T.Card, "Btn_"..label)
    card.LayoutOrder = order
    addCorner(card, T.CornerSm)
    addStroke(card, 1, T.Border)
    newLabel(card, label, UDim2.new(1,-120,0,20), UDim2.new(0,14,0,8),  13, T.Font,      Enum.TextXAlignment.Left, T.Text)
    newLabel(card, desc,  UDim2.new(1,-120,0,14), UDim2.new(0,14,1,-20), 10, T.FontLight, Enum.TextXAlignment.Left, T.SubText)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0,82,0,30); btn.Position = UDim2.new(1,-96,0.5,-15)
    btn.BackgroundColor3 = color or T.Accent; btn.Text = btnText
    btn.TextColor3 = T.White; btn.TextSize = 12; btn.Font = T.Font
    btn.BorderSizePixel = 0; btn.Parent = card
    addCorner(btn, T.CornerXs)
    addGradient(btn,
        color and color:Lerp(T.White, 0.1) or Color3.fromRGB(130,80,255),
        color or T.AccentDim, 135)
    btn.MouseButton1Click:Connect(function()
        spring(btn, "BackgroundColor3", color and color:Lerp(T.Black,0.2) or T.AccentDim, 20)
        task.delay(0.18, function() spring(btn, "BackgroundColor3", color or T.Accent, 20) end)
        if cb then cb() end
    end)
    local clickBG = Instance.new("TextButton")
    clickBG.Size = UDim2.new(1,0,1,0); clickBG.BackgroundTransparency = 1
    clickBG.Text = ""; clickBG.Parent = card; clickBG.ZIndex = 0
    clickBG.MouseEnter:Connect(function() spring(card,"BackgroundColor3",T.CardHover,15) end)
    clickBG.MouseLeave:Connect(function() spring(card,"BackgroundColor3",T.Card,15) end)
    return card
end

local function InfoCard(parent, label, val, order, color)
    local card = newFrame(parent, UDim2.new(1,0,0,46), nil, T.Card, "Info_"..label)
    card.LayoutOrder = order
    addCorner(card, T.CornerSm)
    addStroke(card, 1, T.Border)
    local dot = newFrame(card, UDim2.new(0,8,0,8), UDim2.new(0,14,0.5,-4), color or T.Accent)
    addCorner(dot, UDim.new(1,0))
    newLabel(card, label, UDim2.new(0.55,0,1,0), UDim2.new(0,30,0,0),  13, T.Font,    Enum.TextXAlignment.Left,  T.Text)
    newLabel(card, val,   UDim2.new(0.45,-14,1,0), UDim2.new(0.55,0,0,0), 13, T.FontMed, Enum.TextXAlignment.Right, color or T.Accent)
    return card
end

local PP = makePage(); Pages["Player"] = PP

Section(PP, "Character Movement", 0)
Slider(PP, "Walk Speed", 8, 250, 24, 1, function(v) S.SpeedVal = v; if S.SpeedOn then applySpeed() end end, " wu/s")
Toggle(PP, "Speed Hack", "Override walk speed", false, 2, function(on) S.SpeedOn = on; applySpeed() end)
Slider(PP, "Jump Power", 25, 500, 50, 3, function(v) S.JumpVal = v; if S.JumpOn then applyJump() end end)
Toggle(PP, "Jump Power Override", "Set custom jump power", false, 4, function(on) S.JumpOn = on; applyJump() end)
Toggle(PP, "Infinite Jump", "Jump again mid-air, always", false, 5, function(on) S.InfJumpOn = on end)
Section(PP, "Survivability", 6)
Toggle(PP, "God Mode", "Full invincibility — no damage", false, 7, function(on) S.GodOn = on; setupGod() end)
Toggle(PP, "Auto Heal", "Regenerate HP continuously", false, 8, function(on) S.HealOn = on end)
Slider(PP, "Heal Rate (HP/s)", 1, 100, 8, 9, function(v) S.HealRate = v end)
Section(PP, "Advanced", 10)
Toggle(PP, "Super Jump", "Enormous jump boost", false, 11, function(on)
    S.SuperJumpOn = on
    local char = LP.Character; if char then
        local h = char:FindFirstChildOfClass("Humanoid"); if h then
            h.JumpPower = on and S.SuperJumpVal or 50
        end
    end
end)
Slider(PP, "Super Jump Height", 100, 1000, 200, 12, function(v)
    S.SuperJumpVal = v
    if S.SuperJumpOn then
        local char = LP.Character; if char then
            local h = char:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower = v end
        end
    end
end)
Toggle(PP, "Anti Slip", "No friction — slide everywhere", false, 13, function(on) S.AntiSlipOn = on end)
Toggle(PP, "No Fall Damage", "Disable fall damage state", false, 14, function(on) S.NoFallOn = on end)
Button(PP, "Reset Character", "Respawn yourself", "Reset", 15, function() LP:LoadCharacter() end, T.Red)

local MP = makePage(); MP.Visible = false; Pages["Movement"] = MP

Section(MP, "Flight", 0)
Toggle(MP, "Fly", "WASD + Space/Shift to fly freely", false, 1, function(on) S.FlyOn = on; if on then startFly() else stopFly() end end)
Slider(MP, "Fly Speed", 10, 500, 60, 2, function(v) S.FlySpeed = v end, " wu/s")
Section(MP, "Collision", 3)
Toggle(MP, "Noclip", "Phase through all geometry", false, 4, function(on) S.NoclipOn = on; if not on then stopNoclip(); startNoclip() end end)
Section(MP, "Teleport", 5)
Button(MP, "Teleport to Spawn", "Jump to game spawn location", "Go", 6, function()
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local spwn = workspace:FindFirstChildOfClass("SpawnLocation")
    if spwn then root.CFrame = spwn.CFrame + Vector3.new(0,6,0) else root.CFrame = CFrame.new(0,20,0) end
end)
Button(MP, "Teleport to Mouse", "Go where cursor is pointing", "Go", 7, function()
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    root.CFrame = CFrame.new(Mouse.Hit.Position + Vector3.new(0,5,0))
end)
Button(MP, "Fling Up", "Blast yourself into the sky", "Fling", 8, function()
    local char = LP.Character; if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Vector3.new(math.random(-80,80), 999, math.random(-80,80))
    bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Parent = root
    game:GetService("Debris"):AddItem(bv, 0.3)
end, T.Yellow)
Section(MP, "Player TP", 9)
local ptpOrder = 10
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LP then
        Button(MP, player.Name, "Teleport to " .. player.Name, "TP", ptpOrder, function()
            local char = LP.Character; local tc = player.Character
            if char and tc then
                local r1 = char:FindFirstChild("HumanoidRootPart")
                local r2 = tc:FindFirstChild("HumanoidRootPart")
                if r1 and r2 then r1.CFrame = r2.CFrame + Vector3.new(2,0,2) end
            end
        end)
        ptpOrder += 1
    end
end

local VP = makePage(); VP.Visible = false; Pages["Visual"] = VP

Section(VP, "Environment", 0)
Toggle(VP, "Fullbright", "Maximum brightness, no shadows", false, 1, function(on) S.FullbrightOn = on; applyFullbright() end)
Toggle(VP, "No Fog", "Remove all fog from the world", false, 2, function(on) S.NoFogOn = on; applyNoFog() end)
Slider(VP, "Field of View", 30, 120, 70, 3, function(v) S.FOVVal = v; Cam.FieldOfView = v end, "°")
Section(VP, "Player ESP", 4)
Toggle(VP, "ESP Highlights", "See players through walls", false, 5, function(on) S.ESPOn = on; if on then enableESP() else disableESP() end end)
Section(VP, "Character FX", 6)
Toggle(VP, "Character Spin", "Spin your character continuously", false, 7, function(on) S.SpinOn = on end)
Slider(VP, "Spin Speed", 1, 40, 8, 8, function(v) S.SpinVal = v end, "°")
Section(VP, "Camera", 9)
Button(VP, "First Person", "Lock to first person view", "Lock", 10, function()
    LP.CameraMaxZoomDistance = 0.5; LP.CameraMinZoomDistance = 0.5
end)
Button(VP, "Third Person", "Restore third person camera", "Unlock", 11, function()
    LP.CameraMaxZoomDistance = 128; LP.CameraMinZoomDistance = 0.5
end)
Section(VP, "World", 13)
Button(VP, "Hide NPCs", "Make all NPCs invisible", "Hide", 14, function()
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LP.Character then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h then for _, p in ipairs(m:GetDescendants()) do
                if p:IsA("BasePart") then p.Transparency = 1 end
            end end
        end
    end
end, T.Yellow)
Button(VP, "Show NPCs", "Restore all NPC visibility", "Show", 15, function()
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LP.Character then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h then for _, p in ipairs(m:GetDescendants()) do
                if p:IsA("BasePart") then p.Transparency = p.Name:find("HumanoidRootPart") and 1 or 0 end
            end end
        end
    end
end)

local CP = makePage(); CP.Visible = false; Pages["Combat"] = CP

Section(CP, "Aim Assist", 0)
Toggle(CP, "Silent Aim", "Bullets bend toward nearest player", false, 1, function(on)
    S.SilentAimOn = on
    if on then
        local oldNamecall
        oldNamecall = hookmetamethod and hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and S.SilentAimOn then
                local args = {...}
                local nearestDist = math.huge
                local nearestRoot = nil
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl ~= LP and pl.Character then
                        local r = pl.Character:FindFirstChild("HumanoidRootPart")
                        if r then
                            local d = (r.Position - Cam.CFrame.Position).Magnitude
                            if d < nearestDist then nearestDist = d; nearestRoot = r end
                        end
                    end
                end
                if nearestRoot then
                    for i, a in ipairs(args) do
                        if typeof(a) == "Instance" and a:IsA("BasePart") and a.Name == "HumanoidRootPart" then
                            args[i] = nearestRoot
                        end
                    end
                end
                return oldNamecall(self, table.unpack(args))
            end
            return oldNamecall(self, ...)
        end)
    end
end)
Section(CP, "Hitbox", 2)
Toggle(CP, "Hitbox Expander", "Inflate all player hitboxes", false, 3, function(on) S.HitboxOn = on; applyHitbox() end)
Slider(CP, "Hitbox Size", 2, 30, 6, 4, function(v) S.HitboxVal = v; if S.HitboxOn then applyHitbox() end end, " st")
Section(CP, "Auto Click", 5)
Toggle(CP, "Auto Click", "Automatically left-click rapidly", false, 6, function(on) S.AutoClickOn = on; startAutoClick() end)
Slider(CP, "CPS (Clicks/Sec)", 1, 30, 10, 7, function(v) S.AutoClickCPS = v end)
Section(CP, "Melee Reach", 8)
Toggle(CP, "Reach Extend", "Attack players from far away", false, 9, function(on) S.ReachOn = on end)
Slider(CP, "Reach Distance", 4, 80, 10, 10, function(v) S.ReachVal = v end, " st")
Button(CP, "Kill Nearest", "Instant-kill the closest player", "Kill", 11, function()
    local nearDist = math.huge; local nearChar = nil
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP and pl.Character then
            local r = pl.Character:FindFirstChild("HumanoidRootPart")
            local myR = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if r and myR then
                local d = (r.Position - myR.Position).Magnitude
                if d < nearDist then nearDist = d; nearChar = pl.Character end
            end
        end
    end
    if nearChar then
        local h = nearChar:FindFirstChildOfClass("Humanoid")
        if h then h.Health = 0 end
    end
end, T.Red)

local EP = makePage(); EP.Visible = false; Pages["Exploits"] = EP

Section(EP, "Server", 0)
Button(EP, "Rejoin Server", "Reconnect to current server", "Rejoin", 1, function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
end)
Button(EP, "Server Hop", "Find and join a fresh server", "Hop", 2, function()
    local ts = game:GetService("TeleportService")
    local ok, res = pcall(function()
        local data = HttpService:JSONDecode(
            game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=10"))
        if data and data.data then
            for _, sv in ipairs(data.data) do
                if sv.id ~= game.JobId and sv.playing < sv.maxPlayers then
                    ts:TeleportToPlaceInstance(game.PlaceId, sv.id, LP)
                    return
                end
            end
        end
    end)
    if not ok then ts:Teleport(game.PlaceId, LP) end
end)
Section(EP, "Player Utilities", 3)
Button(EP, "Copy User ID", "Your Roblox user ID to clipboard", "Copy", 4, function()
    if setclipboard then setclipboard(tostring(LP.UserId)) else print("Your User ID: " .. LP.UserId) end
end)
Button(EP, "Copy Game ID", "This game's place ID to clipboard", "Copy", 5, function()
    if setclipboard then setclipboard(tostring(game.PlaceId)) else print("Game ID: " .. game.PlaceId) end
end)
Button(EP, "Print Players", "Log all players to console", "Print", 6, function()
    print("-- SPARTA: SERVER PLAYERS --")
    for _, p in ipairs(Players:GetPlayers()) do
        print(p.Name .. " | ID: " .. p.UserId)
    end
end)
Section(EP, "Chat", 7)
Button(EP, "Chat Spam", "Spam Sparta message in chat", "Spam", 8, function()
    local rs = game:GetService("ReplicatedStorage")
    local evt = rs:FindFirstChild("DefaultChatSystemChatEvents") and
                rs.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
    for i=1,8 do
        task.delay(i*0.25, function()
            if evt then evt:FireServer("Sparta v3.0 Elite", "All") else print("Chat: Sparta v3.0") end
        end)
    end
end)
Section(EP, "World Cleanup", 9)
Button(EP, "Delete All Balls", "Remove sphere/ball objects", "Delete", 10, function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Shape == Enum.PartType.Ball) then
            obj:Destroy()
        end
    end
end, T.Red)
Button(EP, "Delete Decals", "Remove all decals from world", "Delete", 11, function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Decal") or obj:IsA("Texture") then obj:Destroy() end
    end
end, T.Red)
Button(EP, "Freeze All NPCs", "Anchor all non-player models", "Freeze", 12, function()
    for _, m in ipairs(workspace:GetDescendants()) do
        if m:IsA("Model") and m ~= LP.Character then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h then
                h.WalkSpeed = 0; h.JumpPower = 0
                for _, p in ipairs(m:GetDescendants()) do
                    if p:IsA("BasePart") then p.Anchored = true end
                end
            end
        end
    end
end, T.Yellow)

local SP = makePage(); SP.Visible = false; Pages["Settings"] = SP

Section(SP, "GUI", 0)
Slider(SP, "Chroma Speed", 1, 20, 4, 1, function(v) S.ChromeSpeed = v end, "x")
Slider(SP, "GUI Opacity", 20, 100, 100, 2, function(v) MF.BackgroundTransparency = 1-(v/100) end, "%")
Section(SP, "Anti Cheat", 3)
Toggle(SP, "Anti AFK", "Prevent automatic AFK kick", false, 4, function(on) S.AntiAFKOn = on end)
Section(SP, "System Info", 5)
InfoCard(SP, "Player Name",   LP.Name,                        6, T.Accent)
InfoCard(SP, "User ID",       tostring(LP.UserId),             7, T.Green)
InfoCard(SP, "Game ID",       tostring(game.PlaceId),          8, T.Yellow)
InfoCard(SP, "Server Job ID", game.JobId:sub(1,14).."...",     9, T.SubText)
InfoCard(SP, "Version",       "3.0 Elite",                    10, getHue(0))
Section(SP, "Keybinds", 11)
InfoCard(SP, "Toggle GUI",  "F9",  12, T.Accent)
InfoCard(SP, "Noclip",      "F",   13, T.Accent)
InfoCard(SP, "Fly Toggle",  "G",   14, T.Accent)

local BottomBar = newFrame(MF, UDim2.new(1,-16,0,24), UDim2.new(0,8,1,-30), T.Surface, "BottomBar")
addCorner(BottomBar, UDim.new(0,7))

local StatusLeft  = newLabel(BottomBar, "Ready",             UDim2.new(0.6,0,1,0),    UDim2.new(0,8,0,0),  9, T.FontMed,   Enum.TextXAlignment.Left,  T.Green)
local BottomRight = newLabel(BottomBar, "delta compatible",  UDim2.new(0.4,-8,1,0),   UDim2.new(0.6,0,0,0), 9, T.FontLight, Enum.TextXAlignment.Right, T.SubText)

local dragStart, dragPos, dragging = nil, nil, false

TB.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = inp.Position
        dragPos   = MF.Position
        inp.Changed:Connect(function()
            if inp.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

TB.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch) then
        local d = inp.Position - dragStart
        MF.Position = UDim2.new(dragPos.X.Scale, dragPos.X.Offset + d.X, dragPos.Y.Scale, dragPos.Y.Offset + d.Y)
    end
end)

ColBtn.MouseButton1Click:Connect(function()
    S.Collapsed = not S.Collapsed
    if S.Collapsed then
        spring(MF, "Size", UDim2.new(0,W,0,52), 15)
        ColBtn.Text = "□"
        task.delay(0.15, function()
            TabScroll.Visible = false; Content.Visible = false; BottomBar.Visible = false
        end)
    else
        TabScroll.Visible = true; Content.Visible = true; BottomBar.Visible = true
        spring(MF, "Size", UDim2.new(0,W,0,H), 15)
        ColBtn.Text = "–"
    end
end)

ClsBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MF, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
        Size = UDim2.new(0,0,0,0),
        Position = UDim2.new(MF.Position.X.Scale, MF.Position.X.Offset+W/2,
                             MF.Position.Y.Scale, MF.Position.Y.Offset+H/2)
    }):Play()
    task.delay(0.25, function() SG:Destroy() end)
end)

conn(UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.KeyCode == Enum.KeyCode.F9 then
        S.GUIVisible = not S.GUIVisible; MF.Visible = S.GUIVisible
    elseif inp.KeyCode == Enum.KeyCode.F then
        S.NoclipOn = not S.NoclipOn
        if not S.NoclipOn then stopNoclip(); startNoclip() end
    elseif inp.KeyCode == Enum.KeyCode.G then
        S.FlyOn = not S.FlyOn
        if S.FlyOn then startFly() else stopFly() end
    end
end))

local notifIdx = 0
local function notify(title, msg, kind, dur)
    dur = dur or 3.5
    kind = kind or "info"
    local color = kind == "error" and T.Red or kind == "warn" and T.Yellow or kind == "success" and T.Green or T.Accent
    notifIdx += 1
    local nf = newFrame(SG, UDim2.new(0,280,0,62), UDim2.new(1,20,1,-80-(notifIdx%5)*72), T.Card)
    addCorner(nf, T.CornerSm)
    addStroke(nf, 1.5, color)
    local bar = newFrame(nf, UDim2.new(0,4,1,0), nil, color)
    addCorner(bar, UDim.new(0,4))
    newLabel(nf, title, UDim2.new(1,-22,0,22), UDim2.new(0,14,0,6),  13, T.Font,      Enum.TextXAlignment.Left, T.Text)
    newLabel(nf, msg,   UDim2.new(1,-22,0,16), UDim2.new(0,14,1,-22), 10, T.FontLight, Enum.TextXAlignment.Left, T.SubText)
    local ns = addStroke(nf, 1.5, color)
    spring(nf, "Position", UDim2.new(1,-298, nf.Position.Y.Scale, nf.Position.Y.Offset), 18)
    local chromaLoop = RunService.Heartbeat:Connect(function() ns.Color = getHue(0.4) end)
    task.delay(dur, function()
        chromaLoop:Disconnect()
        TweenService:Create(nf, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(1,20, nf.Position.Y.Scale, nf.Position.Y.Offset)
        }):Play()
        task.delay(0.35, function() nf:Destroy() end)
    end)
end

local fpsCnt, fpsTimer, pingTimer = 0, 0, 0

conn(RunService.Heartbeat:Connect(function(dt)
    S.ChromeHue = (S.ChromeHue + dt / S.ChromeSpeed) % 1
    ChromeStroke.Color        = getHue(0)
    Glow.ImageColor3          = getHue(0.15)
    Icon.BackgroundColor3     = getHue(0.3)
    TitleTxt.TextColor3       = getHue(0.45)
    if TabBtns[S.ActiveTab] then
        TabBtns[S.ActiveTab].BackgroundColor3 = getHue(0.6)
    end
    fpsCnt += 1; fpsTimer += dt
    if fpsTimer >= 0.5 then
        local fps = math.floor(fpsCnt / fpsTimer)
        FPSLabel.Text = fps .. " FPS"
        FPSLabel.TextColor3 = fps >= 55 and T.Green or fps >= 30 and T.Yellow or T.Red
        fpsCnt = 0; fpsTimer = 0
    end
    pingTimer += dt
    if pingTimer >= 2 then
        pingTimer = 0
        pcall(function()
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            PingLabel.Text = ping .. " ms"
            PingLabel.TextColor3 = ping < 80 and T.Green or ping < 150 and T.Yellow or T.Red
        end)
    end
    local active = {}
    if S.SpeedOn  then table.insert(active, "SPD")  end
    if S.GodOn    then table.insert(active, "GOD")  end
    if S.FlyOn    then table.insert(active, "FLY")  end
    if S.NoclipOn then table.insert(active, "CLIP") end
    if S.ESPOn    then table.insert(active, "ESP")  end
    if #active > 0 then
        StatusLeft.Text = table.concat(active, "  ")
        StatusLeft.TextColor3 = getHue(0.1)
    else
        StatusLeft.Text = "Ready"
        StatusLeft.TextColor3 = T.Green
    end
end))

local WM = newFrame(SG, UDim2.new(0,220,0,30), UDim2.new(0,10,0,10), T.Card, "Watermark")
addCorner(WM, UDim.new(0,8))
addStroke(WM, 1.5, T.Border)
newLabel(WM, "SPARTA v3.0  |  " .. LP.Name, UDim2.new(1,-16,1,0), UDim2.new(0,8,0,0), 10, T.Font, Enum.TextXAlignment.Left, T.SubText)
conn(RunService.Heartbeat:Connect(function() WM:FindFirstChildOfClass("UIStroke").Color = getHue(0.8) end))

task.delay(0.6, function() notify("Sparta v3.0 Loaded", "Welcome, " .. LP.Name .. "! All systems ready.", "success", 5) end)
task.delay(2,   function() notify("Keybinds", "F9 = Toggle  |  G = Fly  |  F = Noclip", "info", 4) end)
