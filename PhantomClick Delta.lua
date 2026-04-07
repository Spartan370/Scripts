-- ╔══════════════════════════════════════════════════════════════╗
-- ║         PHANTOM CLICK  •  Delta Executor Edition             ║
-- ║   LocalScript → Paste directly into Delta executor           ║
-- ║   ✓ Mobile friendly  ✓ Collapsible  ✓ Chroma border         ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ── Detect mobile (touch screen) ───────────────────────────────
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ══════════════════════════════════════════
--  STATE
-- ══════════════════════════════════════════
local isEnabled    = false
local cps          = 10
local MAX_CPS      = 9999
local clickTarget  = nil          -- Vector2 screen position
local selectMode   = false
local selectConn   = nil
local collapsed    = false
local clickAccum   = 0
local lastTick     = tick()

-- ══════════════════════════════════════════
--  SIZING  (larger touch targets on mobile)
-- ══════════════════════════════════════════
local W            = isMobile and 320  or 300
local BTN_H        = isMobile and 60   or 52
local FONT_SIZE    = isMobile and 14   or 13
local TITLE_H      = isMobile and 54   or 48
local CORNER       = 18

-- ══════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════
-- Remove any existing copy first (executor re-runs)
if PlayerGui:FindFirstChild("PhantomClickUI") then
    PlayerGui:FindFirstChild("PhantomClickUI"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "PhantomClickUI"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent         = PlayerGui

-- ══════════════════════════════════════════
--  CHROMA BORDER FRAME
-- ══════════════════════════════════════════
local FULL_H   = TITLE_H + BTN_H * 3 + 100  -- expanded height
local MINI_H   = TITLE_H + 6                 -- collapsed height

local ChromaHolder = Instance.new("Frame")
ChromaHolder.Name             = "ChromaHolder"
ChromaHolder.Size             = UDim2.new(0, W + 6, 0, FULL_H + 6)
ChromaHolder.Position         = UDim2.new(0, 16, 0, 60)
ChromaHolder.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
ChromaHolder.BorderSizePixel  = 0
ChromaHolder.ClipsDescendants = false
ChromaHolder.ZIndex           = 1
ChromaHolder.Parent           = ScreenGui

local ChromaCorner = Instance.new("UICorner")
ChromaCorner.CornerRadius = UDim.new(0, CORNER + 3)
ChromaCorner.Parent       = ChromaHolder

local ChromaGrad = Instance.new("UIGradient")
ChromaGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   110)),
    ColorSequenceKeypoint.new(0.14, Color3.fromRGB(255, 100, 0)),
    ColorSequenceKeypoint.new(0.28, Color3.fromRGB(240, 220, 0)),
    ColorSequenceKeypoint.new(0.42, Color3.fromRGB(0,   230, 100)),
    ColorSequenceKeypoint.new(0.57, Color3.fromRGB(0,   180, 255)),
    ColorSequenceKeypoint.new(0.71, Color3.fromRGB(100, 0,   255)),
    ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255, 0,   180)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0,   110)),
})
ChromaGrad.Parent = ChromaHolder

-- ══════════════════════════════════════════
--  MAIN FRAME  (clips content when collapsing)
-- ══════════════════════════════════════════
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(1, -6, 1, -6)
MainFrame.Position         = UDim2.new(0, 3, 0, 3)
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 11, 17)
MainFrame.BorderSizePixel  = 0
MainFrame.ClipsDescendants = true
MainFrame.ZIndex           = 2
MainFrame.Parent           = ChromaHolder

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, CORNER)
MainCorner.Parent       = MainFrame

local InnerGrad = Instance.new("UIGradient")
InnerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 32)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(9,  9,  15)),
})
InnerGrad.Rotation = 140
InnerGrad.Parent   = MainFrame

-- ══════════════════════════════════════════
--  TITLE BAR  (drag + collapse toggle)
-- ══════════════════════════════════════════
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, TITLE_H)
TitleBar.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 3
TitleBar.Parent           = MainFrame

local TitleBarCorner = Instance.new("UICorner")
TitleBarCorner.CornerRadius = UDim.new(0, CORNER)
TitleBarCorner.Parent       = TitleBar

-- Square off the bottom of TitleBar
local TBSquare = Instance.new("Frame")
TBSquare.Size             = UDim2.new(1, 0, 0.5, 0)
TBSquare.Position         = UDim2.new(0, 0, 0.5, 0)
TBSquare.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
TBSquare.BorderSizePixel  = 0
TBSquare.ZIndex           = 3
TBSquare.Parent           = TitleBar

-- Lightning icon
local IconLabel = Instance.new("TextLabel")
IconLabel.Size              = UDim2.new(0, 30, 1, 0)
IconLabel.Position          = UDim2.new(0, 10, 0, 0)
IconLabel.BackgroundTransparency = 1
IconLabel.Font              = Enum.Font.GothamBold
IconLabel.Text              = "⚡"
IconLabel.TextColor3        = Color3.fromRGB(255, 220, 50)
IconLabel.TextSize          = 17
IconLabel.ZIndex            = 4
IconLabel.Parent            = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size              = UDim2.new(1, -90, 1, 0)
TitleLabel.Position          = UDim2.new(0, 44, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.Text              = "PHANTOM CLICK"
TitleLabel.TextColor3        = Color3.fromRGB(245, 245, 255)
TitleLabel.TextSize          = FONT_SIZE + 1
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.ZIndex            = 4
TitleLabel.Parent            = TitleBar

-- Collapse arrow button (top-right)
local CollapseBtn = Instance.new("TextButton")
CollapseBtn.Size             = UDim2.new(0, isMobile and 44 or 36, 0, isMobile and 44 or 36)
CollapseBtn.Position         = UDim2.new(1, -(isMobile and 50 or 42), 0.5, -(isMobile and 22 or 18))
CollapseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 46)
CollapseBtn.Font             = Enum.Font.GothamBold
CollapseBtn.Text             = "▼"
CollapseBtn.TextColor3       = Color3.fromRGB(160, 160, 220)
CollapseBtn.TextSize         = 13
CollapseBtn.BorderSizePixel  = 0
CollapseBtn.ZIndex           = 5
CollapseBtn.Parent           = TitleBar
local CColCorner = Instance.new("UICorner")
CColCorner.CornerRadius = UDim.new(0, 8)
CColCorner.Parent       = CollapseBtn

-- Separator
local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, -28, 0, 1)
Sep.Position         = UDim2.new(0, 14, 0, TITLE_H)
Sep.BackgroundColor3 = Color3.fromRGB(38, 38, 58)
Sep.BorderSizePixel  = 0
Sep.ZIndex           = 3
Sep.Parent           = MainFrame

-- ══════════════════════════════════════════
--  CONTENT HOLDER  (everything below title)
-- ══════════════════════════════════════════
local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Size             = UDim2.new(1, 0, 1, -TITLE_H - 1)
Content.Position         = UDim2.new(0, 0, 0, TITLE_H + 1)
Content.BackgroundTransparency = 1
Content.ZIndex           = 3
Content.Parent           = MainFrame

-- ══════════════════════════════════════════
--  HELPER: build a button
-- ══════════════════════════════════════════
local function MakeBtn(name, text, yOff, bgCol, parent)
    local b = Instance.new("TextButton")
    b.Name             = name
    b.Size             = UDim2.new(1, -24, 0, BTN_H)
    b.Position         = UDim2.new(0, 12, 0, yOff)
    b.BackgroundColor3 = bgCol
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.Text             = text
    b.TextColor3       = Color3.fromRGB(255, 255, 255)
    b.TextSize         = FONT_SIZE
    b.ZIndex           = 4
    b.Parent           = parent or Content

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 13)
    c.Parent       = b

    -- Press scale micro-animation
    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.07), {Size = UDim2.new(1,-28, 0, BTN_H - 4)}):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {Size = UDim2.new(1,-24, 0, BTN_H)}):Play()
    end)
    -- Touch equivalents
    b.TouchLongPress:Connect(function() end)  -- eat long press so it doesn't fire twice

    return b
end

-- ══════════════════════════════════════════
--  BUTTON 1 — TOGGLE
-- ══════════════════════════════════════════
local OFF_COL  = Color3.fromRGB(34, 34, 52)
local ON_COL   = Color3.fromRGB(0,  185, 90)

local ToggleBtn = MakeBtn("Toggle", "● AUTOCLICKER  —  OFF", 10, OFF_COL)

-- Status indicator dot
local Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 10, 0, 10)
Dot.Position         = UDim2.new(0, 14, 0.5, -5)
Dot.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 5
Dot.Parent           = ToggleBtn
local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent       = Dot

-- ══════════════════════════════════════════
--  BUTTON 2 — SELECT POSITION
-- ══════════════════════════════════════════
local SEL_COL    = Color3.fromRGB(25, 80, 170)
local SEL_ACT    = Color3.fromRGB(180, 75, 0)
local SelectBtn  = MakeBtn("SelectBtn", "🎯  SELECT CLICK POSITION", 10 + BTN_H + 10, SEL_COL)

local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size              = UDim2.new(1, -24, 0, 18)
InfoLbl.Position          = UDim2.new(0, 12, 0, 10 + BTN_H * 2 + 20)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Font              = Enum.Font.Gotham
InfoLbl.Text              = "Target: not set"
InfoLbl.TextColor3        = Color3.fromRGB(90, 90, 140)
InfoLbl.TextSize          = 11
InfoLbl.ZIndex            = 4
InfoLbl.Parent            = Content

-- ══════════════════════════════════════════
--  BUTTON 3 — CPS PANEL
-- ══════════════════════════════════════════
local CPS_Y  = 10 + BTN_H * 2 + 44
local CpsBox = Instance.new("Frame")
CpsBox.Name             = "CpsBox"
CpsBox.Size             = UDim2.new(1, -24, 0, BTN_H + 14)
CpsBox.Position         = UDim2.new(0, 12, 0, CPS_Y)
CpsBox.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
CpsBox.BorderSizePixel  = 0
CpsBox.ZIndex           = 4
CpsBox.Parent           = Content
local CpsBoxCorner = Instance.new("UICorner")
CpsBoxCorner.CornerRadius = UDim.new(0, 13)
CpsBoxCorner.Parent       = CpsBox

local CpsTitleLbl = Instance.new("TextLabel")
CpsTitleLbl.Size              = UDim2.new(1, 0, 0, 20)
CpsTitleLbl.Position          = UDim2.new(0, 0, 0, 5)
CpsTitleLbl.BackgroundTransparency = 1
CpsTitleLbl.Font              = Enum.Font.GothamBold
CpsTitleLbl.Text              = "CPS AMOUNT"
CpsTitleLbl.TextColor3        = Color3.fromRGB(180, 180, 240)
CpsTitleLbl.TextSize          = 10
CpsTitleLbl.ZIndex            = 5
CpsTitleLbl.Parent            = CpsBox

local BTN_SZ = isMobile and 46 or 38

local MinusBtn = Instance.new("TextButton")
MinusBtn.Size             = UDim2.new(0, BTN_SZ, 0, BTN_SZ)
MinusBtn.Position         = UDim2.new(0, 8, 1, -(BTN_SZ + 8))
MinusBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 66)
MinusBtn.Font             = Enum.Font.GothamBold
MinusBtn.Text             = "−"
MinusBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
MinusBtn.TextSize         = 20
MinusBtn.BorderSizePixel  = 0
MinusBtn.ZIndex           = 5
MinusBtn.Parent           = CpsBox
local MinC = Instance.new("UICorner")
MinC.CornerRadius = UDim.new(0, 9)
MinC.Parent       = MinusBtn

local CpsVal = Instance.new("TextLabel")
CpsVal.Size              = UDim2.new(1, -(BTN_SZ * 2 + 24), 0, BTN_SZ)
CpsVal.Position          = UDim2.new(0, BTN_SZ + 12, 1, -(BTN_SZ + 8))
CpsVal.BackgroundTransparency = 1
CpsVal.Font              = Enum.Font.GothamBold
CpsVal.Text              = tostring(cps)
CpsVal.TextColor3        = Color3.fromRGB(255, 255, 255)
CpsVal.TextSize          = 22
CpsVal.ZIndex            = 5
CpsVal.Parent            = CpsBox

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size             = UDim2.new(0, BTN_SZ, 0, BTN_SZ)
PlusBtn.Position         = UDim2.new(1, -(BTN_SZ + 8), 1, -(BTN_SZ + 8))
PlusBtn.BackgroundColor3 = Color3.fromRGB(44, 44, 66)
PlusBtn.Font             = Enum.Font.GothamBold
PlusBtn.Text             = "+"
PlusBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
PlusBtn.TextSize         = 20
PlusBtn.BorderSizePixel  = 0
PlusBtn.ZIndex           = 5
PlusBtn.Parent           = CpsBox
local PlusC = Instance.new("UICorner")
PlusC.CornerRadius = UDim.new(0, 9)
PlusC.Parent       = PlusBtn

-- ══════════════════════════════════════════
--  COLLAPSE / EXPAND
-- ══════════════════════════════════════════
local function setCollapsed(state)
    collapsed = state
    local targetH  = state and (MINI_H + 6)  or (FULL_H + 6)
    local arrow    = state and "▲" or "▼"

    TweenService:Create(ChromaHolder, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, W + 6, 0, targetH)
    }):Play()
    TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, -6, 0, targetH - 6)
    }):Play()
    CollapseBtn.Text = arrow

    -- Fade content
    TweenService:Create(Content, TweenInfo.new(0.15), {
        GroupTransparency = state and 1 or 0
    }):Play()
    TweenService:Create(Sep, TweenInfo.new(0.15), {
        BackgroundTransparency = state and 1 or 0
    }):Play()
end

CollapseBtn.MouseButton1Click:Connect(function()
    setCollapsed(not collapsed)
end)

-- ══════════════════════════════════════════
--  DRAGGING  (works for mouse + touch)
-- ══════════════════════════════════════════
local dragging, dragStart, startPos

local function onDragStart(input)
    dragging  = true
    dragStart = input.Position
    startPos  = ChromaHolder.Position
end

local function onDragMove(input)
    if not dragging then return end
    local delta = input.Position - dragStart
    ChromaHolder.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

local function onDragEnd()
    dragging = false
end

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        onDragStart(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or
       input.UserInputType == Enum.UserInputType.Touch then
        onDragMove(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        onDragEnd()
    end
end)

-- ══════════════════════════════════════════
--  TOGGLE LOGIC
-- ══════════════════════════════════════════
ToggleBtn.MouseButton1Click:Connect(function()
    isEnabled = not isEnabled
    if isEnabled then
        ToggleBtn.Text   = "● AUTOCLICKER  —  ON"
        Dot.BackgroundColor3 = Color3.fromRGB(0, 220, 100)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = ON_COL}):Play()
    else
        ToggleBtn.Text   = "● AUTOCLICKER  —  OFF"
        Dot.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        TweenService:Create(ToggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = OFF_COL}):Play()
    end
    lastTick   = tick()
    clickAccum = 0
end)

-- ══════════════════════════════════════════
--  SELECT POSITION LOGIC
-- ══════════════════════════════════════════
SelectBtn.MouseButton1Click:Connect(function()
    if selectMode then return end
    selectMode = true
    SelectBtn.Text             = "🎯  TAP ANYWHERE TO SET..."
    TweenService:Create(SelectBtn, TweenInfo.new(0.15), {BackgroundColor3 = SEL_ACT}):Play()

    if selectConn then selectConn:Disconnect() end

    -- Small delay so this click doesn't self-register
    task.wait(0.1)

    selectConn = UserInputService.InputBegan:Connect(function(input)
        local isTap   = input.UserInputType == Enum.UserInputType.Touch
        local isClick = input.UserInputType == Enum.UserInputType.MouseButton1
        if not (isTap or isClick) then return end

        local pos = UserInputService:GetMouseLocation()

        -- Ignore clicks inside our own UI
        local ch = ChromaHolder.AbsolutePosition
        local cs = ChromaHolder.AbsoluteSize
        local onUI = pos.X >= ch.X and pos.X <= ch.X + cs.X and
                     pos.Y >= ch.Y and pos.Y <= ch.Y + cs.Y
        if onUI then return end

        clickTarget = Vector2.new(pos.X, pos.Y)
        selectMode  = false
        SelectBtn.Text = "🎯  SELECT CLICK POSITION"
        TweenService:Create(SelectBtn, TweenInfo.new(0.15), {BackgroundColor3 = SEL_COL}):Play()
        InfoLbl.Text      = string.format("Target: (%d, %d)", pos.X, pos.Y)
        InfoLbl.TextColor3 = Color3.fromRGB(0, 200, 120)
        selectConn:Disconnect()
        selectConn = nil
    end)
end)

-- ══════════════════════════════════════════
--  CPS  +/−  WITH HOLD REPEAT
-- ══════════════════════════════════════════
PlusBtn.MouseButton1Click:Connect(function()
    cps = math.min(cps + 1, MAX_CPS)
    CpsVal.Text = tostring(cps)
end)

MinusBtn.MouseButton1Click:Connect(function()
    cps = math.max(cps - 1, 1)
    CpsVal.Text = tostring(cps)
end)

local function holdRepeat(btn, delta)
    local held = false
    btn.MouseButton1Down:Connect(function()
        held = true
        task.delay(0.35, function()
            while held do
                cps = math.clamp(cps + delta, 1, MAX_CPS)
                CpsVal.Text = tostring(cps)
                task.wait(0.04)
            end
        end)
    end)
    btn.MouseButton1Up:Connect(function()   held = false end)
    btn.MouseLeave:Connect(function()       held = false end)
    -- Touch hold
    btn.TouchLongPress:Connect(function()
        held = true
        task.delay(0.0, function()
            while held do
                cps = math.clamp(cps + delta, 1, MAX_CPS)
                CpsVal.Text = tostring(cps)
                task.wait(0.04)
            end
        end)
    end)
    btn.TouchEnded:Connect(function()  held = false end)
end

holdRepeat(PlusBtn,   1)
holdRepeat(MinusBtn, -1)

-- ══════════════════════════════════════════
--  CHROMA ANIMATION + CLICK ENGINE
-- ══════════════════════════════════════════
local chromaAngle = 0

RunService.Heartbeat:Connect(function(dt)
    -- Spin chroma gradient
    chromaAngle = (chromaAngle + dt * 80) % 360
    ChromaGrad.Rotation = chromaAngle

    -- ── DELTA EXECUTOR CLICK ENGINE ──────────
    -- Delta exposes `mouse1click()` and `mouse1press()` / `mouse1release()`
    -- at the global level. We use the accumulator pattern so any CPS value,
    -- including very large ones, fires as fast as Heartbeat allows.
    if not isEnabled or not clickTarget then
        lastTick   = tick()
        clickAccum = 0
        return
    end

    local now   = tick()
    local delta = now - lastTick
    lastTick    = now

    clickAccum = clickAccum + delta * cps

    -- Move mouse to target position then fire clicks
    while clickAccum >= 1 do
        clickAccum = clickAccum - 1

        -- Delta's built-in click functions (works on mobile too via Delta)
        if mousemoveabs then
            mousemoveabs(clickTarget.X, clickTarget.Y)
        end

        -- Primary method: Delta global
        if mouse1click then
            mouse1click()
        elseif mouse1press and mouse1release then
            mouse1press()
            mouse1release()
        end
    end
end)

-- Clamp accumulator so a lag spike doesn't cause a click storm
RunService.Heartbeat:Connect(function()
    if clickAccum > 5 then clickAccum = 5 end
end)
