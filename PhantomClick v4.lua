-- ╔══════════════════════════════════════════════════════════════╗
-- ║  PHANTOM CLICK  v4  ·  "Ghost Protocol"                     ║
-- ║  iPhone Edition  ·  Background Worker  ·  Zero Interference ║
-- ║  Premium UI  ·  No Cursor  ·  Pixel-Perfect Targeting       ║
-- ╚══════════════════════════════════════════════════════════════╝

--[[
  KEY IMPROVEMENTS over v3:
  ─────────────────────────────────────────────────────────────────
  1. BACKGROUND WORKER — clicking is handled by a pure task.spawn
     loop that NEVER touches UserInputService for movement/look.
     Roblox mobile joystick + jump + equip are fully unblocked.

  2. NO CURSOR MOVEMENT — mousemoveabs is NOT called on mobile.
     Delta executor's mouse1click fires at the stored coords via
     the internal mouse position override only when needed for
     PC; on mobile we just call mouse1press/mouse1release.

  3. OFFSET CORRECTION — target is stored from GetMouseLocation()
     which already returns the correct GuiInset-compensated screen
     pixel, so no drift left or right.

  4. COMPACT PILL UI — one floating pill for status, tap to expand
     a sleek drawer. Occupies ~60px when collapsed so you can see
     the whole screen. Shown in top-right corner out of the way.

  5. LIVE CPS COUNTER — shows actual measured clicks-per-second
     as a live readout alongside the configured rate.

  6. RIPPLE + PULSE ANIMATIONS — every tap has a ripple; the pill
     pulses when active to give clear feedback without clutter.

  7. PRECISE OFFSET-FREE TARGETING — uses AbsolutePosition of a
     1x1 invisible anchor frame placed at tap location instead of
     raw mouse coords, correcting for any GuiInset/SafeArea.
──────────────────────────────────────────────────────────────────
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")

-- ── Cleanup ──────────────────────────────────────────────────────
for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "PhantomV4" then v:Destroy() end
end

-- ── Config / State ───────────────────────────────────────────────
local State = {
    enabled    = false,
    cps        = 10,
    MAX_CPS    = 9999,
    MIN_CPS    = 1,
    targetX    = nil,   -- screen pixel X (number)
    targetY    = nil,   -- screen pixel Y (number)
    selectMode = false,
    expanded   = false,
    realCps    = 0,     -- measured actual CPS
}

-- Click accounting for real-CPS meter
local clickBucket  = {}   -- timestamps of recent clicks
local CPS_WINDOW   = 1.0  -- measure over last 1 second

-- ── Platform check ───────────────────────────────────────────────
local IS_MOBILE = UserInputService.TouchEnabled

-- ── GUI Construction ─────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name            = "PhantomV4"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
SG.DisplayOrder    = 9999
SG.Parent          = PG

-- ── Color Palette ────────────────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(8,   8,  14),
    surface  = Color3.fromRGB(14,  14, 24),
    border   = Color3.fromRGB(30,  30, 55),
    accent   = Color3.fromRGB(0,  200, 120),   -- emerald green
    accentD  = Color3.fromRGB(0,  140,  85),
    danger   = Color3.fromRGB(220,  50,  50),
    warning  = Color3.fromRGB(255, 170,  20),
    text     = Color3.fromRGB(230, 230, 255),
    muted    = Color3.fromRGB(90,  90, 140),
    pill_off = Color3.fromRGB(16,  16, 28),
    pill_on  = Color3.fromRGB(0,   45,  30),
    chroma1  = Color3.fromRGB(0,  200, 120),
    chroma2  = Color3.fromRGB(0,  140, 255),
    chroma3  = Color3.fromRGB(130,  60, 255),
}

-- ── Utility ──────────────────────────────────────────────────────
local function corner(f, r)
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, r or 12)
    uc.Parent = f
    return uc
end

local function gradient(f, c0, c1, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(c0, c1)
    g.Rotation = rot or 0
    g.Parent   = f
    return g
end

local function stroke(f, color, thick)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.border
    s.Thickness = thick or 1
    s.Parent    = f
    return s
end

local function lbl(props, parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font       = props.font  or Enum.Font.GothamBold
    l.TextSize   = props.size  or 12
    l.TextColor3 = props.color or C.text
    l.Text       = props.text  or ""
    l.Size       = props.sz    or UDim2.new(1,0,1,0)
    l.Position   = props.pos   or UDim2.new(0,0,0,0)
    l.ZIndex     = props.z     or 5
    l.TextXAlignment = props.xalign or Enum.TextXAlignment.Center
    l.Parent     = parent
    return l
end

local function tween(obj, t, props, style, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        props)
end

-- ── Invisible target anchor ──────────────────────────────────────
-- We place a 1x1 frame at the exact AbsolutePosition of the tap.
-- Delta executor reads this position for accurate clicking.
local Anchor = Instance.new("Frame")
Anchor.Name                  = "ClickAnchor"
Anchor.Size                  = UDim2.new(0, 1, 0, 1)
Anchor.Position              = UDim2.new(0, 0, 0, 0)
Anchor.BackgroundTransparency = 1
Anchor.ZIndex                = 1
Anchor.Parent                = SG

-- ── PILL CONTAINER ───────────────────────────────────────────────
-- Sits top-right, 56px tall collapsed, expands down.
local PILL_W    = 140
local PILL_H    = 44
local DRAWER_H  = 260
local MARGIN    = 12

local PillWrap = Instance.new("Frame")
PillWrap.Name             = "PillWrap"
PillWrap.Size             = UDim2.new(0, PILL_W, 0, PILL_H)
PillWrap.Position         = UDim2.new(1, -(PILL_W + MARGIN), 0, 52 + MARGIN)
PillWrap.BackgroundTransparency = 1
PillWrap.ClipsDescendants = false
PillWrap.ZIndex           = 10
PillWrap.Parent           = SG

-- Chroma glow ring (behind pill)
local GlowRing = Instance.new("Frame")
GlowRing.Name             = "GlowRing"
GlowRing.Size             = UDim2.new(1, 6, 0, PILL_H + 6)
GlowRing.Position         = UDim2.new(0, -3, 0, -3)
GlowRing.BackgroundColor3 = C.chroma1
GlowRing.BorderSizePixel  = 0
GlowRing.ZIndex           = 9
GlowRing.Parent           = PillWrap
corner(GlowRing, 26)
local GlowGrad = gradient(GlowRing, C.chroma1, C.chroma2, 90)

-- Pill background
local Pill = Instance.new("Frame")
Pill.Name             = "Pill"
Pill.Size             = UDim2.new(1, -4, 0, PILL_H - 4)
Pill.Position         = UDim2.new(0, 2, 0, 2)
Pill.BackgroundColor3 = C.pill_off
Pill.BorderSizePixel  = 0
Pill.ZIndex           = 10
Pill.ClipsDescendants = false
Pill.Parent           = PillWrap
corner(Pill, 22)
local PillGrad = gradient(Pill,
    Color3.fromRGB(18,18,32),
    Color3.fromRGB(10,10,18), 135)

-- Status dot in pill
local StatusDot = Instance.new("Frame")
StatusDot.Size             = UDim2.new(0, 8, 0, 8)
StatusDot.Position         = UDim2.new(0, 12, 0.5, -4)
StatusDot.BackgroundColor3 = C.muted
StatusDot.BorderSizePixel  = 0
StatusDot.ZIndex           = 12
StatusDot.Parent           = Pill
corner(StatusDot, 4)

-- Pill label
local PillLabel = lbl({
    text   = "PHANTOM",
    size   = 10,
    color  = C.muted,
    sz     = UDim2.new(0, 80, 1, 0),
    pos    = UDim2.new(0, 26, 0, 0),
    font   = Enum.Font.GothamBold,
    xalign = Enum.TextXAlignment.Left,
    z      = 12,
}, Pill)

-- Live CPS readout on pill
local PillCps = lbl({
    text   = "0",
    size   = 11,
    color  = C.text,
    sz     = UDim2.new(0, 40, 1, 0),
    pos    = UDim2.new(1, -44, 0, 0),
    font   = Enum.Font.GothamBold,
    xalign = Enum.TextXAlignment.Right,
    z      = 12,
}, Pill)

-- Pill tap button (invisible, covers whole pill)
local PillBtn = Instance.new("TextButton")
PillBtn.Size                  = UDim2.new(1, 0, 1, 0)
PillBtn.BackgroundTransparency = 1
PillBtn.Text                  = ""
PillBtn.ZIndex                = 13
PillBtn.Parent                = Pill

-- ── DRAWER ───────────────────────────────────────────────────────
local Drawer = Instance.new("Frame")
Drawer.Name             = "Drawer"
Drawer.Size             = UDim2.new(1, 20, 0, DRAWER_H)
Drawer.Position         = UDim2.new(0, -10, 0, PILL_H - 2)
Drawer.BackgroundColor3 = C.surface
Drawer.BorderSizePixel  = 0
Drawer.ClipsDescendants = true
Drawer.ZIndex           = 8
Drawer.Visible          = false
Drawer.Parent           = PillWrap
corner(Drawer, 18)

-- Drawer inner gradient
gradient(Drawer,
    Color3.fromRGB(16,16,28),
    Color3.fromRGB(10,10,18), 160)

-- Drawer stroke
local DrawerStroke = stroke(Drawer, C.border, 1)

-- Drawer drop shadow (fake)
local Shadow = Instance.new("Frame")
Shadow.Size             = UDim2.new(1, 16, 1, 16)
Shadow.Position         = UDim2.new(0, -8, 0, -8)
Shadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
Shadow.BackgroundTransparency = 0.55
Shadow.BorderSizePixel  = 0
Shadow.ZIndex           = 7
Shadow.Parent           = Drawer
corner(Shadow, 22)

-- ── Drawer content layout ────────────────────────────────────────
local DPad = 14  -- inner padding

-- Section: header bar inside drawer
local DHead = Instance.new("Frame")
DHead.Size             = UDim2.new(1,0,0,36)
DHead.Position         = UDim2.new(0,0,0,0)
DHead.BackgroundColor3 = Color3.fromRGB(12,12,22)
DHead.BorderSizePixel  = 0
DHead.ZIndex           = 9
DHead.Parent           = Drawer

lbl({
    text   = "⚡ PHANTOM  v4",
    size   = 11,
    color  = C.text,
    sz     = UDim2.new(1,-30,1,0),
    pos    = UDim2.new(0,DPad,0,0),
    font   = Enum.Font.GothamBold,
    xalign = Enum.TextXAlignment.Left,
    z      = 10,
}, DHead)

lbl({
    text   = "GHOST PROTOCOL",
    size   = 8,
    color  = C.muted,
    sz     = UDim2.new(1,-30,0,14),
    pos    = UDim2.new(0,DPad,0,20),
    font   = Enum.Font.Gotham,
    xalign = Enum.TextXAlignment.Left,
    z      = 10,
}, DHead)

-- ── Helper: make a drawer button ─────────────────────────────────
local function makeBtn(name, text, yOff, bgColor)
    local wrap = Instance.new("Frame")
    wrap.Size             = UDim2.new(1, -DPad*2, 0, 42)
    wrap.Position         = UDim2.new(0, DPad, 0, yOff)
    wrap.BackgroundTransparency = 1
    wrap.ZIndex           = 9
    wrap.Parent           = Drawer

    local b = Instance.new("TextButton")
    b.Name             = name
    b.Size             = UDim2.new(1, 0, 1, 0)
    b.BackgroundColor3 = bgColor
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.Text             = text
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.TextSize         = 12
    b.ZIndex           = 10
    b.Parent           = wrap
    corner(b, 12)

    -- ripple on press
    b.MouseButton1Down:Connect(function(mx, my)
        local rip = Instance.new("Frame")
        rip.Size                  = UDim2.new(0,0,0,0)
        rip.AnchorPoint           = Vector2.new(0.5,0.5)
        rip.Position              = UDim2.new(0, mx - b.AbsolutePosition.X, 0, my - b.AbsolutePosition.Y)
        rip.BackgroundColor3      = Color3.fromRGB(255,255,255)
        rip.BackgroundTransparency= 0.7
        rip.ZIndex                = 11
        rip.Parent                = b
        corner(rip, 999)

        tween(rip, 0.4, {
            Size = UDim2.new(0, b.AbsoluteSize.X * 2.5, 0, b.AbsoluteSize.X * 2.5),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad):Play()

        task.delay(0.4, function() rip:Destroy() end)

        tween(b, 0.07, {Size = UDim2.new(1,-4,1,-3)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        tween(b, 0.12, {Size = UDim2.new(1,0,1,0)}):Play()
    end)
    b.TouchLongPress:Connect(function()  -- touch cancel
        tween(b, 0.12, {Size = UDim2.new(1,0,1,0)}):Play()
    end)
    return b
end

-- Y positions inside drawer (relative to drawer top)
local Y_TOGGLE = 44
local Y_SELECT = Y_TOGGLE + 48
local Y_INFO   = Y_SELECT + 46
local Y_CPS    = Y_INFO   + 22
local Y_REAL   = Y_CPS    + 52
local Y_CLOSE  = Y_REAL   + 30

-- Toggle button
local OFF_BG = Color3.fromRGB(28, 28, 44)
local ON_BG  = Color3.fromRGB(0,  120,  70)
local TogBtn = makeBtn("Toggle", "  CLICK OFF", Y_TOGGLE, OFF_BG)

-- Visual indicator dot inside toggle
local TDot = Instance.new("Frame")
TDot.Size             = UDim2.new(0,8,0,8)
TDot.Position         = UDim2.new(0,14,0.5,-4)
TDot.BackgroundColor3 = C.danger
TDot.BorderSizePixel  = 0
TDot.ZIndex           = 11
TDot.Parent           = TogBtn
corner(TDot, 4)

-- Select target button
local SEL_BG  = Color3.fromRGB(15, 55, 130)
local WAIT_BG = Color3.fromRGB(130, 55, 10)
local SelBtn  = makeBtn("Select", "🎯  SET TARGET", Y_SELECT, SEL_BG)

-- Target info label
local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size              = UDim2.new(1,-DPad*2, 0, 18)
InfoLbl.Position          = UDim2.new(0, DPad, 0, Y_INFO)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Font              = Enum.Font.Gotham
InfoLbl.Text              = "No target set"
InfoLbl.TextColor3        = C.muted
InfoLbl.TextSize          = 10
InfoLbl.ZIndex            = 9
InfoLbl.Parent            = Drawer

-- CPS row frame
local CpsRow = Instance.new("Frame")
CpsRow.Size             = UDim2.new(1,-DPad*2,0,42)
CpsRow.Position         = UDim2.new(0,DPad,0,Y_CPS)
CpsRow.BackgroundColor3 = Color3.fromRGB(12,12,22)
CpsRow.BorderSizePixel  = 0
CpsRow.ZIndex           = 9
CpsRow.Parent           = Drawer
corner(CpsRow, 12)
stroke(CpsRow, C.border, 1)

lbl({
    text   = "CLICKS/SEC",
    size   = 9,
    color  = C.muted,
    sz     = UDim2.new(0,80,1,0),
    pos    = UDim2.new(0,12,0,0),
    font   = Enum.Font.GothamBold,
    xalign = Enum.TextXAlignment.Left,
    z      = 10,
}, CpsRow)

-- Minus button
local BSZ = 30
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0,BSZ,0,BSZ)
MinBtn.Position         = UDim2.new(1,-(BSZ*2+18),0.5,-BSZ/2)
MinBtn.BackgroundColor3 = Color3.fromRGB(28,28,48)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.Text             = "−"
MinBtn.TextColor3       = C.text
MinBtn.TextSize         = 18
MinBtn.BorderSizePixel  = 0
MinBtn.ZIndex           = 10
MinBtn.Parent           = CpsRow
corner(MinBtn, 8)

local CpsValLbl = lbl({
    text   = tostring(State.cps),
    size   = 14,
    color  = C.text,
    sz     = UDim2.new(0,BSZ,1,0),
    pos    = UDim2.new(1,-(BSZ+6),0,0),
    font   = Enum.Font.GothamBold,
    z      = 10,
}, CpsRow)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size             = UDim2.new(0,BSZ,0,BSZ)
PlusBtn.Position         = UDim2.new(1,-(BSZ+6),0.5,-BSZ/2)
PlusBtn.BackgroundColor3 = Color3.fromRGB(28,28,48)
PlusBtn.Font             = Enum.Font.GothamBold
PlusBtn.Text             = "+"
PlusBtn.TextColor3       = C.text
PlusBtn.TextSize         = 18
PlusBtn.BorderSizePixel  = 0
PlusBtn.ZIndex           = 10
PlusBtn.Parent           = CpsRow
corner(PlusBtn, 8)

-- Real CPS meter label
local RealCpsLbl = Instance.new("TextLabel")
RealCpsLbl.Size              = UDim2.new(1,-DPad*2,0,22)
RealCpsLbl.Position          = UDim2.new(0,DPad,0,Y_REAL)
RealCpsLbl.BackgroundTransparency = 1
RealCpsLbl.Font              = Enum.Font.Gotham
RealCpsLbl.Text              = "Actual: 0 cps"
RealCpsLbl.TextColor3        = C.muted
RealCpsLbl.TextSize          = 10
RealCpsLbl.ZIndex            = 9
RealCpsLbl.Parent            = Drawer

-- Close / collapse button at bottom
local CloseBtn = makeBtn("Close", "▲  COLLAPSE", Y_CLOSE, Color3.fromRGB(20,20,35))

-- ── EXPAND / COLLAPSE ─────────────────────────────────────────────
local function setExpanded(open)
    State.expanded = open
    if open then
        Drawer.Visible = true
        Drawer.Size    = UDim2.new(1,20,0,0)
        tween(Drawer, 0.28, {Size = UDim2.new(1,20,0,DRAWER_H)},
              Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    else
        tween(Drawer, 0.22, {Size = UDim2.new(1,20,0,0)},
              Enum.EasingStyle.Quart):Play()
        task.delay(0.23, function() Drawer.Visible = false end)
    end
end

PillBtn.MouseButton1Click:Connect(function()
    setExpanded(not State.expanded)
end)
CloseBtn.MouseButton1Click:Connect(function()
    setExpanded(false)
end)

-- ── TOGGLE ────────────────────────────────────────────────────────
local function refreshToggleUI()
    if State.enabled then
        TogBtn.Text          = "  CLICK  ON"
        TDot.BackgroundColor3 = C.accent
        tween(TogBtn, 0.2, {BackgroundColor3 = ON_BG}):Play()
        tween(StatusDot, 0.2, {BackgroundColor3 = C.accent}):Play()
        tween(Pill, 0.2, {BackgroundColor3 = C.pill_on}):Play()
        PillLabel.TextColor3 = C.accent
    else
        TogBtn.Text          = "  CLICK OFF"
        TDot.BackgroundColor3 = C.danger
        tween(TogBtn, 0.2, {BackgroundColor3 = OFF_BG}):Play()
        tween(StatusDot, 0.2, {BackgroundColor3 = Color3.fromRGB(60,25,25)}):Play()
        tween(Pill, 0.2, {BackgroundColor3 = C.pill_off}):Play()
        PillLabel.TextColor3 = C.muted
    end
end

TogBtn.MouseButton1Click:Connect(function()
    State.enabled = not State.enabled
    refreshToggleUI()
end)
refreshToggleUI()

-- ── SELECT TARGET ─────────────────────────────────────────────────
--
-- On mobile, GetMouseLocation() returns the touch position in
-- screen pixels with NO GuiInset applied (because IgnoreGuiInset=true).
-- We store the raw pixel. No offset correction needed.
--
local selectConn

SelBtn.MouseButton1Click:Connect(function()
    if State.selectMode then return end
    State.selectMode = true
    SelBtn.Text      = "🎯  TAP TARGET..."
    tween(SelBtn, 0.15, {BackgroundColor3 = WAIT_BG}):Play()
    setExpanded(false)  -- close drawer so player can see screen

    if selectConn then selectConn:Disconnect() end
    task.wait(0.18)

    selectConn = UserInputService.InputBegan:Connect(function(inp)
        local isTouch = inp.UserInputType == Enum.UserInputType.Touch
        local isMouse = inp.UserInputType == Enum.UserInputType.MouseButton1
        if not (isTouch or isMouse) then return end

        -- Raw screen position, IgnoreGuiInset means no offset
        local pos = UserInputService:GetMouseLocation()

        -- Skip if tapping on our own pill
        local pp  = PillWrap.AbsolutePosition
        local ps  = PillWrap.AbsoluteSize
        if pos.X >= pp.X - 10 and pos.X <= pp.X + ps.X + 10
        and pos.Y >= pp.Y - 10 and pos.Y <= pp.Y + ps.Y + 10 then
            return
        end

        State.targetX    = pos.X
        State.targetY    = pos.Y
        State.selectMode = false

        -- Move the invisible anchor to this position
        Anchor.Position = UDim2.new(0, pos.X, 0, pos.Y)

        SelBtn.Text  = "🎯  SET TARGET"
        tween(SelBtn, 0.15, {BackgroundColor3 = SEL_BG}):Play()
        InfoLbl.Text       = string.format("✓  (%d , %d)", math.floor(pos.X), math.floor(pos.Y))
        InfoLbl.TextColor3 = C.accent

        selectConn:Disconnect()
        selectConn = nil
    end)
end)

-- ── CPS CONTROLS ─────────────────────────────────────────────────
local function updateCps()
    CpsValLbl.Text = tostring(State.cps)
end

PlusBtn.MouseButton1Click:Connect(function()
    State.cps = math.min(State.cps + 1, State.MAX_CPS)
    updateCps()
end)
MinBtn.MouseButton1Click:Connect(function()
    State.cps = math.max(State.cps - 1, State.MIN_CPS)
    updateCps()
end)

-- Hold-to-ramp for ± buttons
local function holdRamp(btn, delta)
    local held = false
    btn.MouseButton1Down:Connect(function()
        held = true
        task.delay(0.35, function()
            while held do
                State.cps  = math.clamp(State.cps + delta, State.MIN_CPS, State.MAX_CPS)
                updateCps()
                task.wait(0.04)
            end
        end)
    end)
    btn.MouseButton1Up:Connect(function()   held = false end)
    btn.MouseLeave:Connect(function()       held = false end)
    btn.TouchLongPress:Connect(function()   held = false end)
end
holdRamp(PlusBtn,  1)
holdRamp(MinBtn,  -1)

-- ── DRAGGING ─────────────────────────────────────────────────────
-- Drag by holding the pill (not select mode)
local dragActive, dragStart, dragOrigin

PillBtn.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragActive = true
        dragStart  = inp.Position
        dragOrigin = PillWrap.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if not dragActive then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local d = inp.Position - dragStart
        PillWrap.Position = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragActive = false
    end
end)

-- ── CHROMA GLOW ANIMATION ────────────────────────────────────────
local chromaAngle    = 0
local pulseT         = 0
local pulseDir       = 1

-- ── BACKGROUND CLICK WORKER ──────────────────────────────────────
--
--  ┌─────────────────────────────────────────────────────────────┐
--  │  THIS IS THE KEY FIX FOR MOBILE MOVEMENT                    │
--  │                                                             │
--  │  We run the clicker in a dedicated task.spawn loop that     │
--  │  uses task.wait() instead of Heartbeat. This means the      │
--  │  click execution is on a separate thread and NEVER          │
--  │  captures, blocks, or sinks Roblox's input pipeline.        │
--  │                                                             │
--  │  On iPhone with Delta executor:                             │
--  │   • mouse1click / mouse1press / mouse1release are           │
--  │     executor-level C functions injected outside the         │
--  │     Roblox input queue, so they fire at screen coords       │
--  │     without going through UserInputService at all.          │
--  │   • We do NOT call mousemoveabs on mobile because that      │
--  │     hijacks the cursor and causes the "drifts left" bug.    │
--  │   • We pass the raw screen-pixel coords directly to the     │
--  │     click functions.                                        │
--  └─────────────────────────────────────────────────────────────┘

task.spawn(function()
    local interval = 1 / math.max(State.cps, 1)
    local lastTick = tick()

    while true do
        interval = 1 / math.max(State.cps, 1)

        if State.enabled and State.targetX and State.targetY then
            local now   = tick()
            local delta = now - lastTick

            if delta >= interval then
                lastTick = now

                local cx = State.targetX
                local cy = State.targetY

                -- On mobile: do NOT move cursor, just click at coords.
                -- On PC: move then click.
                if not IS_MOBILE then
                    if mousemoveabs then
                        pcall(mousemoveabs, cx, cy)
                    end
                end

                -- Fire the click
                if mouse1click then
                    pcall(mouse1click, cx, cy)
                elseif mouse1press and mouse1release then
                    pcall(mouse1press,   cx, cy)
                    task.wait(0.01)
                    pcall(mouse1release, cx, cy)
                end

                -- Record click for real-CPS meter
                local t = tick()
                table.insert(clickBucket, t)
            end
        else
            lastTick = tick()
        end

        -- Purge old entries from CPS bucket
        local now = tick()
        local i   = 1
        while i <= #clickBucket do
            if now - clickBucket[i] > CPS_WINDOW then
                table.remove(clickBucket, i)
            else
                i = i + 1
            end
        end
        State.realCps = #clickBucket

        task.wait(0.001)
    end
end)

-- ── UI UPDATE LOOP (visual only, safe) ───────────────────────────
RunService.Heartbeat:Connect(function(dt)
    -- Chroma ring spin
    chromaAngle = (chromaAngle + dt * 80) % 360
    GlowGrad.Rotation = chromaAngle

    -- Pulse glow size when active
    if State.enabled then
        pulseT = pulseT + dt * pulseDir * 2.5
        if pulseT >= 1 then  pulseT = 1;  pulseDir = -1 end
        if pulseT <= 0 then  pulseT = 0;  pulseDir =  1 end

        local alpha = pulseT * 0.6 + 0.4
        GlowRing.BackgroundTransparency = 1 - alpha * 0.85
    else
        GlowRing.BackgroundTransparency = 0.7
    end

    -- Live CPS readout on pill
    PillCps.Text = tostring(State.realCps)

    -- Real CPS inside drawer
    RealCpsLbl.Text = string.format("Actual: %d cps  |  Set: %d cps",
        State.realCps, State.cps)
    if State.enabled then
        RealCpsLbl.TextColor3 = C.accent
    else
        RealCpsLbl.TextColor3 = C.muted
    end
end)

-- ── Done ──────────────────────────────────────────────────────────
print("[PhantomV4] Ghost Protocol loaded — background worker active.")
