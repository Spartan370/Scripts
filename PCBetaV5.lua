-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  PHANTOM CLICK  v5  ·  "Silent Touch"                           ║
-- ║  iPhone / Delta  ·  True Finger-Tap Simulation                  ║
-- ║  No Cursor · Scrollable Drawer · Precision CPS Engine           ║
-- ╚══════════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PG = LP:WaitForChild("PlayerGui")

-- ── Cleanup old instances ────────────────────────────────────────
for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "PhantomV5" then v:Destroy() end
end

-- ════════════════════════════════════════════════════════════════
--  TOUCH INJECTION LAYER
-- ════════════════════════════════════════════════════════════════
local touchFn = nil

local function detectTouchAPI()
    -- 1. tap(x, y)
    local hasTap = false
    pcall(function() hasTap = typeof(tap) == "function" end)
    if hasTap then
        touchFn = function(x, y) pcall(tap, x, y) end
        return "tap"
    end

    -- 2. tapsimulate(x, y)
    local hasTapSim = false
    pcall(function() hasTapSim = typeof(tapsimulate) == "function" end)
    if hasTapSim then
        touchFn = function(x, y) pcall(tapsimulate, x, y) end
        return "tapsimulate"
    end

    -- 3. firetouch(x, y)
    local hasFireTouch = false
    pcall(function() hasFireTouch = typeof(firetouch) == "function" end)
    if hasFireTouch then
        touchFn = function(x, y) pcall(firetouch, x, y) end
        return "firetouch"
    end

    -- 4. VirtualInputManager
    local ok, vim = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    -- Not useful for touch, skip

    -- 5. Last resort: UserInputService:FireTouchInput
    local hasFireTouchInput = false
    pcall(function() hasFireTouchInput = typeof(UserInputService.FireTouchInput) == "function" end)
    if hasFireTouchInput then
        touchFn = function(x, y)
            pcall(function()
                local inp = Instance.new("InputObject")
                inp.UserInputType  = Enum.UserInputType.Touch
                inp.UserInputState = Enum.UserInputState.Begin
                inp.Position       = Vector3.new(x, y, 0)
                UserInputService:FireTouchInput(inp)
                task.wait(0.012)
                inp.UserInputState = Enum.UserInputState.End
                UserInputService:FireTouchInput(inp)
            end)
        end
        return "FireTouchInput"
    end

    -- 6. Absolute fallback — mouse1press/release only if nothing else
    touchFn = function(x, y)
        pcall(function()
            local hasM1P = false
            local hasM1R = false
            local hasM1C = false
            pcall(function() hasM1P = typeof(mouse1press) == "function" end)
            pcall(function() hasM1R = typeof(mouse1release) == "function" end)
            pcall(function() hasM1C = typeof(mouse1click) == "function" end)
            
            if hasM1P and hasM1R then
                mouse1press(x, y)
                task.wait(0.011)
                mouse1release(x, y)
            elseif hasM1C then
                mouse1click(x, y)
            end
        end)
    end
    return "mouse_fallback"
end

local apiName = detectTouchAPI()

-- ════════════════════════════════════════════════════════════════
--  STATE
-- ════════════════════════════════════════════════════════════════
local State = {
    enabled    = false,
    cps        = 10,
    MAX_CPS    = 500,
    MIN_CPS    = 1,
    targetX    = nil,
    targetY    = nil,
    selectMode = false,
    expanded   = false,
    realCps    = 0,
}

local clickBucket = {}
local CPS_WINDOW  = 1.0

-- ════════════════════════════════════════════════════════════════
--  PRECISION CPS ACCUMULATOR
-- ════════════════════════════════════════════════════════════════
local accum    = 0.0
local lastTime = tick()

-- ════════════════════════════════════════════════════════════════
--  GUI SETUP
-- ════════════════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name            = "PhantomV5"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
SG.DisplayOrder    = 9999
SG.Parent          = PG

-- ── Palette ──────────────────────────────────────────────────────
local C = {
    bg       = Color3.fromRGB(7,   7,  13),
    surface  = Color3.fromRGB(13,  13, 22),
    border   = Color3.fromRGB(28,  28, 52),
    accent   = Color3.fromRGB(0,  210, 130),
    accentD  = Color3.fromRGB(0,  140,  85),
    danger   = Color3.fromRGB(215,  45,  45),
    warn     = Color3.fromRGB(255, 165,  20),
    text     = Color3.fromRGB(228, 228, 255),
    muted    = Color3.fromRGB(80,   80, 130),
    pill_off = Color3.fromRGB(14,  14, 26),
    pill_on  = Color3.fromRGB(0,   42,  28),
    grad1    = Color3.fromRGB(17,  17, 30),
    grad2    = Color3.fromRGB(9,    9, 16),
    glow1    = Color3.fromRGB(0,  200, 120),
    glow2    = Color3.fromRGB(0,  130, 255),
    glow3    = Color3.fromRGB(120, 50, 255),
}

-- ── Helpers ──────────────────────────────────────────────────────
local function rnd(f, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or 12)
    u.Parent = f
    return u
end

local function grad2(f, a, b, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(a, b)
    g.Rotation = rot or 0
    g.Parent   = f
    return g
end

local function outline(f, col, px)
    local s = Instance.new("UIStroke")
    s.Color     = col or C.border
    s.Thickness = px or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = f
    return s
end

local function tw(obj, t, props, sty, dir)
    return TweenService:Create(obj,
        TweenInfo.new(t,
            sty or Enum.EasingStyle.Quart,
            dir or Enum.EasingDirection.Out),
        props)
end

local function mkLabel(p, par)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font         = p.font   or Enum.Font.GothamBold
    l.TextSize     = p.size   or 12
    l.TextColor3   = p.color  or C.text
    l.Text         = p.text   or ""
    l.Size         = p.sz     or UDim2.new(1,0,1,0)
    l.Position     = p.pos    or UDim2.new(0,0,0,0)
    l.ZIndex       = p.z      or 5
    l.TextXAlignment = p.xa   or Enum.TextXAlignment.Left
    l.TextYAlignment = p.ya   or Enum.TextYAlignment.Center
    l.Parent       = par
    return l
end

local function addRipple(btn)
    btn.MouseButton1Down:Connect(function(mx, my)
        local rip = Instance.new("Frame")
        rip.AnchorPoint           = Vector2.new(0.5, 0.5)
        rip.Size                  = UDim2.new(0, 0, 0, 0)
        rip.Position              = UDim2.new(0, mx - btn.AbsolutePosition.X,
                                               0, my - btn.AbsolutePosition.Y)
        rip.BackgroundColor3      = Color3.fromRGB(255,255,255)
        rip.BackgroundTransparency = 0.72
        rip.BorderSizePixel       = 0
        rip.ZIndex                = btn.ZIndex + 1
        rip.Parent                = btn
        rnd(rip, 999)
        local spread = btn.AbsoluteSize.X * 2.8
        tw(rip, 0.45, {
            Size = UDim2.new(0, spread, 0, spread),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad):Play()
        task.delay(0.46, function() rip:Destroy() end)
        tw(btn, 0.06, {Size = UDim2.new(1,-4, 1,-3)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        tw(btn, 0.12, {Size = UDim2.new(1,0, 1,0)}):Play()
    end)
end

-- ════════════════════════════════════════════════════════════════
--  PILL  (collapsed header)
-- ════════════════════════════════════════════════════════════════
local PILL_W  = 164
local PILL_H  = 44
local MARGIN  = 10

local Root = Instance.new("Frame")
Root.Name                  = "PhantomRoot"
Root.Size                  = UDim2.new(0, PILL_W + 6, 0, PILL_H + 6)
Root.Position              = UDim2.new(1, -(PILL_W + 6 + MARGIN), 0, 54 + MARGIN)
Root.BackgroundTransparency = 1
Root.ClipsDescendants      = false
Root.ZIndex                = 20
Root.Parent                = SG

local Halo = Instance.new("Frame")
Halo.Name             = "Halo"
Halo.Size             = UDim2.new(1, 0, 0, PILL_H + 6)
Halo.Position         = UDim2.new(0, 0, 0, 0)
Halo.BackgroundColor3 = C.glow1
Halo.BackgroundTransparency = 0.25
Halo.BorderSizePixel  = 0
Halo.ZIndex           = 19
Halo.Parent           = Root
rnd(Halo, 26)
local HaloGrad = grad2(Halo, C.glow1, C.glow2, 90)

local Pill = Instance.new("Frame")
Pill.Name             = "Pill"
Pill.Size             = UDim2.new(1, -6, 0, PILL_H - 2)
Pill.Position         = UDim2.new(0, 3, 0, 3)
Pill.BackgroundColor3 = C.pill_off
Pill.BorderSizePixel  = 0
Pill.ZIndex           = 21
Pill.ClipsDescendants = true
Pill.Parent           = Root
rnd(Pill, 22)
grad2(Pill, C.grad1, C.grad2, 140)

local SDot = Instance.new("Frame")
SDot.Size             = UDim2.new(0, 9, 0, 9)
SDot.Position         = UDim2.new(0, 13, 0.5, -4)
SDot.BackgroundColor3 = Color3.fromRGB(55,22,22)
SDot.BorderSizePixel  = 0
SDot.ZIndex           = 23
SDot.Parent           = Pill
rnd(SDot, 5)

local PillName = mkLabel({
    text  = "PHANTOM",
    size  = 11,
    color = C.muted,
    sz    = UDim2.new(0, 78, 1, 0),
    pos   = UDim2.new(0, 28, 0, 0),
    font  = Enum.Font.GothamBold,
    z     = 23,
}, Pill)

local PillBadge = Instance.new("Frame")
PillBadge.Size             = UDim2.new(0, 52, 0, 26)
PillBadge.Position         = UDim2.new(1, -60, 0.5, -13)
PillBadge.BackgroundColor3 = Color3.fromRGB(18,18,34)
PillBadge.BorderSizePixel  = 0
PillBadge.ZIndex           = 23
PillBadge.Parent           = Pill
rnd(PillBadge, 8)
outline(PillBadge, C.border, 1)

local PillCpsTxt = mkLabel({
    text  = "0",
    size  = 12,
    color = C.text,
    sz    = UDim2.new(1,0,1,0),
    font  = Enum.Font.GothamBold,
    z     = 24,
    xa    = Enum.TextXAlignment.Center,
}, PillBadge)

local Handle = Instance.new("TextButton")
Handle.Size             = UDim2.new(0, 28, 1, 0)
Handle.Position         = UDim2.new(1, -30, 0, 0)
Handle.BackgroundTransparency = 1
Handle.Text             = "⋮"
Handle.TextColor3       = C.muted
Handle.Font             = Enum.Font.GothamBold
Handle.TextSize         = 16
Handle.ZIndex           = 25
Handle.Parent           = Pill

local PillTap = Instance.new("TextButton")
PillTap.Size             = UDim2.new(1, -30, 1, 0)
PillTap.BackgroundTransparency = 1
PillTap.Text             = ""
PillTap.ZIndex           = 24
PillTap.Parent           = Pill

-- ════════════════════════════════════════════════════════════════
--  DRAWER  (scrollable)
-- ════════════════════════════════════════════════════════════════
local DRAWER_W        = PILL_W + 20
local DRAWER_VISIBLE  = 310
local CONTENT_H       = 340
local DRAWER_X_OFFSET = -10

local DrawerClip = Instance.new("Frame")
DrawerClip.Name             = "DrawerClip"
DrawerClip.Size             = UDim2.new(0, DRAWER_W, 0, 0)
DrawerClip.Position         = UDim2.new(0, DRAWER_X_OFFSET, 0, PILL_H + 2)
DrawerClip.BackgroundTransparency = 1
DrawerClip.ClipsDescendants = true
DrawerClip.ZIndex           = 15
DrawerClip.Visible          = false
DrawerClip.Parent           = Root

local Drawer = Instance.new("Frame")
Drawer.Name             = "Drawer"
Drawer.Size             = UDim2.new(1, 0, 0, DRAWER_VISIBLE)
Drawer.Position         = UDim2.new(0, 0, 0, 0)
Drawer.BackgroundColor3 = C.surface
Drawer.BorderSizePixel  = 0
Drawer.ZIndex           = 16
Drawer.Parent           = DrawerClip
rnd(Drawer, 18)
grad2(Drawer, C.grad1, C.grad2, 155)
outline(Drawer, C.border, 1)

local DShadow = Instance.new("Frame")
DShadow.Size             = UDim2.new(1, 20, 1, 20)
DShadow.Position         = UDim2.new(0,-10,0,-10)
DShadow.BackgroundColor3 = Color3.fromRGB(0,0,0)
DShadow.BackgroundTransparency = 0.5
DShadow.BorderSizePixel  = 0
DShadow.ZIndex           = 15
DShadow.Parent           = DrawerClip
rnd(DShadow, 22)

local DHeader = Instance.new("Frame")
DHeader.Size             = UDim2.new(1,0,0,42)
DHeader.BackgroundColor3 = Color3.fromRGB(10,10,20)
DHeader.BorderSizePixel  = 0
DHeader.ZIndex           = 18
DHeader.Parent           = Drawer
rnd(DHeader, 18)

local DHeaderSq = Instance.new("Frame")
DHeaderSq.Size             = UDim2.new(1,0,0.5,0)
DHeaderSq.Position         = UDim2.new(0,0,0.5,0)
DHeaderSq.BackgroundColor3 = Color3.fromRGB(10,10,20)
DHeaderSq.BorderSizePixel  = 0
DHeaderSq.ZIndex           = 18
DHeaderSq.Parent           = DHeader

mkLabel({
    text  = "⚡  PHANTOM  v5",
    size  = 12,
    color = C.text,
    sz    = UDim2.new(1,-40,0,22),
    pos   = UDim2.new(0,14,0,4),
    font  = Enum.Font.GothamBold,
    z     = 19,
}, DHeader)

mkLabel({
    text  = "SILENT TOUCH  •  " .. apiName:upper(),
    size  = 9,
    color = C.muted,
    sz    = UDim2.new(1,-40,0,14),
    pos   = UDim2.new(0,14,0,24),
    font  = Enum.Font.Gotham,
    z     = 19,
}, DHeader)

local HDivide = Instance.new("Frame")
HDivide.Size             = UDim2.new(1,-24,0,1)
HDivide.Position         = UDim2.new(0,12,0,41)
HDivide.BackgroundColor3 = C.border
HDivide.BorderSizePixel  = 0
HDivide.ZIndex           = 18
HDivide.Parent           = Drawer

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                    = UDim2.new(1, 0, 1, -43)
Scroll.Position                = UDim2.new(0, 0, 0, 43)
Scroll.BackgroundTransparency  = 1
Scroll.BorderSizePixel         = 0
Scroll.CanvasSize              = UDim2.new(0, 0, 0, CONTENT_H)
Scroll.ScrollBarThickness      = 3
Scroll.ScrollBarImageColor3    = C.border
Scroll.ScrollingDirection      = Enum.ScrollingDirection.Y
Scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
Scroll.ZIndex                  = 17
Scroll.ElasticBehavior         = Enum.ElasticBehavior.Always
Scroll.Parent                  = Drawer

local SLayout = Instance.new("UIListLayout")
SLayout.SortOrder        = Enum.SortOrder.LayoutOrder
SLayout.Padding          = UDim.new(0, 10)
SLayout.Parent           = Scroll

local SPad = Instance.new("UIPadding")
SPad.PaddingLeft   = UDim.new(0, 12)
SPad.PaddingRight  = UDim.new(0, 12)
SPad.PaddingTop    = UDim.new(0, 10)
SPad.PaddingBottom = UDim.new(0, 10)
SPad.Parent        = Scroll

local function drawerBtn(name, text, bg, order)
    local b = Instance.new("TextButton")
    b.Name             = name
    b.Size             = UDim2.new(1, 0, 0, 48)
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.Text             = text
    b.TextColor3       = Color3.fromRGB(255,255,255)
    b.TextSize         = 13
    b.ZIndex           = 18
    b.LayoutOrder      = order or 0
    b.ClipsDescendants = true
    b.Parent           = Scroll
    rnd(b, 13)
    addRipple(b)
    return b
end

local TogBtn = drawerBtn("Toggle", "  AUTO-CLICK  OFF",
    Color3.fromRGB(25,25,42), 1)

local TogDot = Instance.new("Frame")
TogDot.Size             = UDim2.new(0,9,0,9)
TogDot.Position         = UDim2.new(0,15,0.5,-4)
TogDot.BackgroundColor3 = C.danger
TogDot.BorderSizePixel  = 0
TogDot.ZIndex           = 19
TogDot.Parent           = TogBtn
rnd(TogDot, 5)

local SelBtn = drawerBtn("Select", "🎯   SET TARGET",
    Color3.fromRGB(12,50,125), 2)

local InfoBadge = Instance.new("Frame")
InfoBadge.Size             = UDim2.new(1,0,0,30)
InfoBadge.BackgroundColor3 = Color3.fromRGB(10,10,20)
InfoBadge.BorderSizePixel  = 0
InfoBadge.ZIndex           = 18
InfoBadge.LayoutOrder      = 3
InfoBadge.Parent           = Scroll
rnd(InfoBadge, 10)
outline(InfoBadge, C.border, 1)

local InfoLbl = mkLabel({
    text  = "No target set",
    size  = 11,
    color = C.muted,
    sz    = UDim2.new(1,-16,1,0),
    pos   = UDim2.new(0,10,0,0),
    font  = Enum.Font.Gotham,
    z     = 19,
    xa    = Enum.TextXAlignment.Left,
}, InfoBadge)

local CpsCard = Instance.new("Frame")
CpsCard.Size             = UDim2.new(1,0,0,52)
CpsCard.BackgroundColor3 = Color3.fromRGB(10,10,20)
CpsCard.BorderSizePixel  = 0
CpsCard.ZIndex           = 18
CpsCard.LayoutOrder      = 4
CpsCard.Parent           = Scroll
rnd(CpsCard, 13)
outline(CpsCard, C.border, 1)

mkLabel({
    text  = "CPS",
    size  = 10,
    color = C.muted,
    sz    = UDim2.new(0,60,1,0),
    pos   = UDim2.new(0,14,0,0),
    font  = Enum.Font.GothamBold,
    z     = 19,
    xa    = Enum.TextXAlignment.Left,
}, CpsCard)

local BSIZE = 34
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0,BSIZE,0,BSIZE)
MinBtn.Position         = UDim2.new(1,-(BSIZE*2+14),0.5,-BSIZE/2)
MinBtn.BackgroundColor3 = Color3.fromRGB(22,22,40)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.Text             = "−"
MinBtn.TextColor3       = C.text
MinBtn.TextSize         = 20
MinBtn.BorderSizePixel  = 0
MinBtn.ZIndex           = 19
MinBtn.Parent           = CpsCard
rnd(MinBtn, 9)
outline(MinBtn, C.border, 1)
addRipple(MinBtn)

local CpsValLbl = mkLabel({
    text  = tostring(State.cps),
    size  = 16,
    color = C.text,
    sz    = UDim2.new(0,BSIZE,1,0),
    pos   = UDim2.new(1,-(BSIZE*2+14)+BSIZE+2,0,0),
    font  = Enum.Font.GothamBold,
    z     = 19,
    xa    = Enum.TextXAlignment.Center,
}, CpsCard)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size             = UDim2.new(0,BSIZE,0,BSIZE)
PlusBtn.Position         = UDim2.new(1,-(BSIZE+8),0.5,-BSIZE/2)
PlusBtn.BackgroundColor3 = Color3.fromRGB(22,22,40)
PlusBtn.Font             = Enum.Font.GothamBold
PlusBtn.Text             = "+"
PlusBtn.TextColor3       = C.text
PlusBtn.TextSize         = 20
PlusBtn.BorderSizePixel  = 0
PlusBtn.ZIndex           = 19
PlusBtn.Parent           = CpsCard
rnd(PlusBtn, 9)
outline(PlusBtn, C.border, 1)
addRipple(PlusBtn)

local MeterCard = Instance.new("Frame")
MeterCard.Size             = UDim2.new(1,0,0,38)
MeterCard.BackgroundColor3 = Color3.fromRGB(8,8,16)
MeterCard.BorderSizePixel  = 0
MeterCard.ZIndex           = 18
MeterCard.LayoutOrder      = 5
MeterCard.Parent           = Scroll
rnd(MeterCard, 10)
outline(MeterCard, C.border, 1)

local MeterLbl = mkLabel({
    text  = "Actual: 0 cps  /  Set: 10 cps",
    size  = 10,
    color = C.muted,
    sz    = UDim2.new(1,-16,1,0),
    pos   = UDim2.new(0,10,0,0),
    font  = Enum.Font.Gotham,
    z     = 19,
    xa    = Enum.TextXAlignment.Left,
}, MeterCard)

local ColBtn = drawerBtn("Collapse", "▲   COLLAPSE",
    Color3.fromRGB(16,16,30), 6)

-- ════════════════════════════════════════════════════════════════
--  EXPAND / COLLAPSE DRAWER
-- ════════════════════════════════════════════════════════════════
local function setExpanded(open)
    State.expanded = open
    if open then
        DrawerClip.Visible = true
        DrawerClip.Size    = UDim2.new(0, DRAWER_W, 0, 0)
        tw(DrawerClip, 0.30,
            {Size = UDim2.new(0, DRAWER_W, 0, DRAWER_VISIBLE)},
            Enum.EasingStyle.Back,
            Enum.EasingDirection.Out):Play()
    else
        tw(DrawerClip, 0.22,
            {Size = UDim2.new(0, DRAWER_W, 0, 0)},
            Enum.EasingStyle.Quart):Play()
        task.delay(0.23, function()
            DrawerClip.Visible = false
        end)
    end
end

PillTap.MouseButton1Click:Connect(function()
    setExpanded(not State.expanded)
end)
ColBtn.MouseButton1Click:Connect(function()
    setExpanded(false)
end)

-- ════════════════════════════════════════════════════════════════
--  DRAG  (handle-only)
-- ════════════════════════════════════════════════════════════════
local dragActive = false
local dragStart  = nil
local dragOrigin = nil

Handle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = true
        dragStart  = Vector2.new(inp.Position.X, inp.Position.Y)
        dragOrigin = Root.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if not dragActive then return end
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseMovement then
        local dx = inp.Position.X - dragStart.X
        local dy = inp.Position.Y - dragStart.Y
        Root.Position = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + dx,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + dy
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragActive = false
    end
end)

-- ════════════════════════════════════════════════════════════════
--  TOGGLE LOGIC
-- ════════════════════════════════════════════════════════════════
local function applyToggleUI()
    if State.enabled then
        TogBtn.Text          = "  AUTO-CLICK  ON"
        TogDot.BackgroundColor3 = C.accent
        tw(TogBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(0,100,62)}):Play()
        tw(SDot,   0.2, {BackgroundColor3 = C.accent}):Play()
        tw(Pill,   0.2, {BackgroundColor3 = C.pill_on}):Play()
        PillName.TextColor3  = C.accent
        accum    = 0
        lastTime = tick()
    else
        TogBtn.Text          = "  AUTO-CLICK  OFF"
        TogDot.BackgroundColor3 = C.danger
        tw(TogBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(25,25,42)}):Play()
        tw(SDot,   0.2, {BackgroundColor3 = Color3.fromRGB(55,22,22)}):Play()
        tw(Pill,   0.2, {BackgroundColor3 = C.pill_off}):Play()
        PillName.TextColor3  = C.muted
        accum = 0
    end
end

TogBtn.MouseButton1Click:Connect(function()
    State.enabled = not State.enabled
    applyToggleUI()
end)

-- ════════════════════════════════════════════════════════════════
--  SELECT TARGET
-- ════════════════════════════════════════════════════════════════
local selectConn

SelBtn.MouseButton1Click:Connect(function()
    if State.selectMode then return end
    State.selectMode = true
    SelBtn.Text = "🎯   TAP YOUR TARGET..."
    tw(SelBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(110,55,8)}):Play()
    setExpanded(false)

    if selectConn then selectConn:Disconnect() end
    task.wait(0.2)

    selectConn = UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch
        and inp.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        local px = inp.Position.X
        local py = inp.Position.Y

        local rp = Root.AbsolutePosition
        local rs = Root.AbsoluteSize
        if px >= rp.X - 12 and px <= rp.X + rs.X + 12
        and py >= rp.Y - 12 and py <= rp.Y + rs.Y + 12 + DRAWER_VISIBLE then
            return
        end

        State.targetX    = px
        State.targetY    = py
        State.selectMode = false

        SelBtn.Text = "🎯   SET TARGET"
        tw(SelBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(12,50,125)}):Play()

        InfoLbl.Text       = string.format("✓  Target locked  (%d , %d)", math.floor(px), math.floor(py))
        InfoLbl.TextColor3 = C.accent

        selectConn:Disconnect()
        selectConn = nil
    end)
end)

-- ════════════════════════════════════════════════════════════════
--  CPS CONTROLS
-- ════════════════════════════════════════════════════════════════
local function refreshCpsUI()
    CpsValLbl.Text = tostring(State.cps)
end

PlusBtn.MouseButton1Click:Connect(function()
    State.cps = math.min(State.cps + 1, State.MAX_CPS)
    refreshCpsUI()
end)
MinBtn.MouseButton1Click:Connect(function()
    State.cps = math.max(State.cps - 1, State.MIN_CPS)
    refreshCpsUI()
end)

local function holdRamp(btn, delta)
    local held = false
    btn.MouseButton1Down:Connect(function()
        held = true
        task.delay(0.32, function()
            while held do
                State.cps = math.clamp(State.cps + delta, State.MIN_CPS, State.MAX_CPS)
                refreshCpsUI()
                task.wait(0.045)
            end
        end)
    end)
    btn.MouseButton1Up:Connect(function()  held = false end)
    btn.MouseLeave:Connect(function()      held = false end)
end
holdRamp(PlusBtn,  1)
holdRamp(MinBtn,  -1)

-- ════════════════════════════════════════════════════════════════
--  PRECISION CLICK WORKER
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.enabled and State.targetX and State.targetY then
            local now   = tick()
            local delta = now - lastTime
            lastTime    = now

            if delta > 0.25 then delta = 0.25 end

            accum = accum + delta * State.cps

            while accum >= 1.0 do
                accum = accum - 1.0

                local cx = State.targetX
                local cy = State.targetY

                touchFn(cx, cy)

                table.insert(clickBucket, tick())
            end
        else
            accum    = 0
            lastTime = tick()
        end

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

        task.wait(0)
    end
end)

-- ════════════════════════════════════════════════════════════════
--  VISUAL UPDATE
-- ════════════════════════════════════════════════════════════════
local chromaT  = 0
local pulseT   = 0
local pulseDir = 1

RunService.Heartbeat:Connect(function(dt)
    chromaT = (chromaT + dt * 70) % 360
    HaloGrad.Rotation = chromaT

    if State.enabled then
        pulseT   = pulseT + dt * pulseDir * 2.2
        if pulseT >= 1 then pulseT = 1; pulseDir = -1 end
        if pulseT <= 0 then pulseT = 0; pulseDir =  1 end
        Halo.BackgroundTransparency = 0.15 + pulseT * 0.45
    else
        Halo.BackgroundTransparency = 0.75
    end

    PillCpsTxt.Text = tostring(State.realCps)

    MeterLbl.Text = string.format(
        "Actual: %d cps   /   Set: %d cps",
        State.realCps, State.cps)
    MeterLbl.TextColor3 = State.enabled and C.accent or C.muted
end)

print(string.format(
    "[PhantomV5] Silent Touch loaded. API: %s | Touch: %s",
    apiName,
    tostring(touchFn ~= nil)
))
